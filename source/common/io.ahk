; Functions related to input/output and user input.



; Grabs the selected text using the clipboard, fixing the clipboard as it finishes.
getSelectedText() {
	return ClipboardLib.getSelectedTextWithClipboard()
}



; Select the current line in text fields.
selectCurrentLine() {
	; Start with End as in some places, Home can put us in an inconsistent place relative to any
	; indentation (i.e. hitting home when you're at the start of the line jumps to the start/end
	; of the indentation).
	Send, {End}{Shift Down}{Home}{Shift Up}
}

; Within the currently selected text, select only the first instance of the given needle text.
selectTextWithinSelection(needle) {
	if(needle = "")
		return
	
	selectedText := getSelectedText()
	if(selectedText = "")
		return
	
	; Determine where in the string our needle is
	needleStartPos := selectedText.contains(needle)
	if(!needleStartPos)
		return
	
	; Debug.popup("io.selectTextWithinSelection","Finished processing", "Selection",selectedText, "Needle",needle, "Needle start position",needleStartPos, "Number of times to go right",numRight)
	Send, {Left} ; Get to start of selection.
	numRight := needleStartPos - 1
	Send, {Right %numRight%} ; Get to start of needle.
	Send, {Shift Down}
	needleLen := needle.length()
	Send, {Right %needleLen%} ; Select to end of needle.
	Send, {Shift Up}
}









releaseAllModifierKeys() {
	modifierKeys := ["LWin", "RWin", "LCtrl", "RCtrl", "LAlt", "RAlt", "LShift", "RShift"]
	For _,modifier in modifierKeys {
		if(GetKeyState(modifier))
			Send, {%modifier% Up}
	}
}

; Wait for a hotkey to be fully released
waitForHotkeyRelease(hotkeyString := "") {
	if(!hotkeyString)
		hotkeyString := A_ThisHotkey
	
	Loop, Parse, hotkeyString
	{
		keyName := getKeyNameFromHotkeyChar(A_LoopField)
		if(keyName)
			KeyWait, % keyName
	}
}

; Partial - doesn't cover everything possible. Doesn't cover UP, for example.
getKeyNameFromHotkeyChar(hotkeyChar := "") {
	if(!hotkeyChar)
		return ""
	
	; Special characters for how a hotkey is checked
	if(hotkeyChar = "*")
		return ""
	if(hotkeyChar = "$")
		return ""
	if(hotkeyChar = "~")
		return ""
	if(hotkeyChar = " ")
		return "" ; Space within hotkey - probably around an & or similar.
	
	; Modifier keys
	if(hotkeyChar = "#")
		return "LWin" ; There's no generic "Win", so just pick the left one.
	if(hotkeyChar = "!")
		return "Alt"
	if(hotkeyChar = "^")
		return "Ctrl"
	if(hotkeyChar = "+")
		return "Shift"
	
	; Otherwise, probably a letter or number.
	return hotkeyChar
}











sendMediaKey(keyName) {
	if(!keyName)
		return
	
	; There's some sort of odd race condition with Spotify that double-sends the play/pause hotkey if Spotify is focused - this prevents it, though I'm not sure why.
	Sleep, 100
	
	; Only certain media keys need special handling, let others straight through.
	specialKeysAry := ["Media_Play_Pause", "Media_Prev", "Media_Next"]
	if(!specialKeysAry.contains(keyName)) {
		Send, % "{" keyName "}"
		return
	}
	
	; Youtube - special case that won't respond to media keys natively
	if(Config.isMediaPlayer("Chrome")) {
		if(keyName = "Media_Play_Pause")
			Send, ^.
		else if(keyName = "Media_Prev")
			Send, ^+,
		else if(keyName = "Media_Next")
			Send, ^+.
		
	} else {
		Send, % "{" keyName "}"
	}
}
