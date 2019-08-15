; Functions related to input/output and user input.

; Select the current line in text fields.
selectCurrentLine() {
	; Start with End as in some places, Home can put us in an inconsistent place relative to any
	; indentation (i.e. hitting home when you're at the start of the line jumps to the start/end
	; of the indentation).
	Send, {End}{Shift Down}{Home}{Shift Up}
}

; Allows SendRaw'ing of input with tabs to programs which auto-indent text.
sendRawWithTabs(input) {
	; Split the input text on newlines, as that's where the tabs will be an issue.
	Loop, Parse, input, `n, `r  ; Specifying `n prior to `r allows both Windows and Unix files to be parsed.
	{
		; Get how many tabs we're dealing with while also pulling them off.
		currLine := A_LoopField
		numTabs := 0
		while stringStartsWith(currLine, A_Tab)
		{
			; DEBUG.popup(currLine, "Before currLine", numTabs, "Number of tabs")
			numTabs++
			currLine := removeStringFromStart(currLine, A_Tab)
			; DEBUG.popup(currLine, "After currLine", numTabs, "Number of tabs")
		}
		
		Send, {Tab %numTabs%}
		SendRaw, %currLine%
		Send, {Enter}
		Send, +{Tab %numTabs%}
	}
}

getFirstLineOfSelectedText() {
	text := getSelectedText()
	return getFirstLine(text)
}

; Grabs the selected text using the clipboard, fixing the clipboard as it finishes.
getSelectedText() {
	; PuTTY auto-copies the selection to the clipboard, and ^c causes an interrupt, so do nothing.
	if(WinActive("ahk_class PuTTY"))
		return clipboard
	
	originalClipboard := clipboardAll ; Back up the clipboard since we're going to use it to get the selected text.
	copyWithHotkey("^c")
	
	textFound := clipboard
	clipboard := originalClipboard    ; Restore the original clipboard. Note we're using clipboard (not clipboardAll).
	
	return textFound
}

getWithClipboardUsingFunction(boundFunc) { ; boundFunc is a BoundFunc object created with Func.Bind() or ObjBindMethod().
	if(!boundFunc)
		return
	
	originalClipboard := clipboardAll ; Back up the clipboard since we're going to use it to get the selected text.
	copyWithFunction(boundFunc)
	
	textFound := clipboard
	clipboard := originalClipboard    ; Restore the original clipboard. Note we're using clipboard (not clipboardAll).
	
	return textFound
}

; Within the currently selected text, select only the first instance of the given needle text.
selectTextWithinSelection(needle) {
	needleLen := strLen(needle)
	if(!needleLen)
		return
	
	selectedText := getSelectedText()
	if(selectedText = "")
		return
	
	; Determine where in the string our needle is
	needleStartPos := stringContains(selectedText, needle)
	if(!needleStartPos)
		return
	numRight := needleStartPos - 1
	
	; DEBUG.popup("io.selectTextWithinSelection","Finished processing", "Selection",selectedText, "Needle",needle, "Needle start position",needleStartPos, "Number of times to go right",numRight)
	Send, {Left} ; Get to start of selection.
	Send, {Right %numRight%} ; Get to start of needle.
	Send, {Shift Down}
	Send, {Right %needleLen%} ; Select to end of needle.
	Send, {Shift Up}
}

; Runs a command line program and returns the result.
runAndReturnOutput(command, outputFile := "cmdOutput.tmp") {
	RunWait, %comspec% /c %command% > %outputFile%,,UseErrorLevel Hide
	outputFileContents := FileRead(outputFile)
	FileDelete, %outputFile%
	
	if(outputFileContents = "") {
		return 0
	} else {
		return outputFileContents
	}
}

; Grab the tooltip(s) shown onscreen. Based on http://www.autohotkey.com/board/topic/53672-get-the-text-content-of-a-tool-tip-window/?p=336440
getTooltipText() {
	outText := ""
	
	; Allow partial matching on ahk_class. (tooltips_class32, WindowsForms10.tooltips_class32.app.0.2bf8098_r13_ad1 so far)
	SetTitleMatchMode, RegEx
	WinGet, winIDs, LIST, ahk_class tooltips_class32
	SetTitleMatchMode, 1
	
	Loop, %winIDs% {
		currID := winIDs%A_Index%
		tooltipText := ControlGetText( , "ahk_id %currID%")
		if(tooltipText != "")
			outText .= tooltipText "`n"
	}
	outText := removeStringFromEnd(outText, "`n")
	
	return outText
}

releaseAllModifierKeys() {
	Send, {LWin Up}{RWin Up}{LCtrl Up}{RCtrl Up}{LAlt Up}{RAlt Up}{LShift Up}{RShift Up}
}

sendUsingLevel(hotkeyString, level) {
	startSendLevel := A_SendLevel
	SendLevel, %level%
	Send, %hotkeyString%
	SendLevel, % startSendLevel
}

clickUsingMode(x := "", y := "", mouseCoordMode := "") {
	; Store the old mouse position to move back to once we're finished.
	MouseGetPos(prevX, prevY)
	
	; Plug in the new mouse CoordMode.
	origCoordMode := A_CoordModeMouse
	CoordMode, Mouse, % mouseCoordMode
	
	; DEBUG.popup("io", "clickUsingMode", "X", x, "Y", y, "CoordMode", mouseCoordMode)
	Click, %x%, %y%
	
	; Restore default mouse CoordMode.
	CoordMode, Mouse, % origCoordMode
	
	; Move the mouse back to its former position.
	MouseMove, prevX, prevY
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
	if(MainConfig.isMediaPlayer("Chrome")) {
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

; Set a web field (that we can't set directly with ControlSetText) using the clipboard, double-checking that it worked.
; Assumes that the field we want to set is already focused.
setWebFieldValue(value) {
	; Send our new value with the clipboard, then confirm it's correct by re-copying the field value (in case it just sent "v")
	WindowActions.selectAll() ; Select all so we overwrite anything already in the field
	sendTextWithClipboard(value)
	if(webFieldMatchesValue(value))
		return true
	
	; If it didn't match, try a second time
	Sleep, 500
	WindowActions.selectAll()
	sendTextWithClipboard(value)
	return webFieldMatchesValue(value)
}
webFieldMatchesValue(value) {
	WindowActions.selectAll()
	actualValue := getSelectedText()
	Send, {Right} ; Release the select all
	return (actualValue = value)
}
