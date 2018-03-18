; Functions related to input/output and user input.

; Allows SendRaw'ing of input with tabs to programs which auto-indent text.
sendRawWithTabs(input) {
	; Split the input text on newlines, as that's where the tabs will be an issue.
	Loop, Parse, input, `n, `r  ; Specifying `n prior to `r allows both Windows and Unix files to be parsed.
	{
		; Get how many tabs we're dealing with while also pulling them off.
		currLine := A_LoopField
		numTabs := 0
		while SubStr(currLine, 1, 1) = A_Tab
		{
			; DEBUG.popup(currLine, "Before currLine", numTabs, "Number of tabs")
			numTabs++
			currLine := StringTrimLeft(currLine, 1)
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
	; Copy selected text to the clipboard.
	if(WinActive("ahk_class PuTTY")) {
		; PuTTY auto-copies the selection to the clipboard, and ^c causes an interrupt, so do nothing.
	} else {
		originalClipboard := clipboardAll ; Back up the clipboard since we're going to use it to get the selected text.
		clipboard :=                      ; Clear the clipboard so we can tell when something is added by ^c.
		Send, ^c
		ClipWait, 0.5                     ; Wait for the clipboard to actually contain data (minimum time).
	}
	
	textFound := clipboard
	clipboard := originalClipboard    ; Restore the original clipboard. Note we're using clipboard (not clipboardAll).
	
	return textFound
}

; Sends the selected text using the clipboard, fixing the clipboard as it finishes.
sendTextWithClipboard(text) {
	; DEBUG.popup("Text to send with clipboard", text)
	
	originalClipboard := clipboardAll ; Save the entire clipboard to a variable of your choice.
	clipboard := ""                   ; Clear the clipboard
	
	clipboard := text
	ClipWait, 0.5                     ; Wait for clipboard to contain the data we put in it (minimum time).
	Send, ^v
	Sleep, 100
	
	clipboard := originalClipboard    ; Restore the original clipboard. Note we're using clipboard (not clipboardAll).
}

; Runs a command line program and returns the result.
runAndReturnOutput(command, outputFile = "cmdOutput.tmp") {
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
	winIDs := WinGet("LIST", "ahk_class tooltips_class32")
	SetTitleMatchMode, 1
	
	Loop, %winIDs% {
		currID := winIDs%A_Index%
		tooltipText := ControlGetText( , "ahk_id %currID%")
		if(tooltipText != "")
			outText .= tooltipText "`n"
	}
	outText := StringTrimRight(outText, 1)
	
	return outText
}


sendUsingLevel(hotkeyString, level) {
	startSendLevel := A_SendLevel
	SendLevel, %level%
	Send, %hotkeyString%
	SendLevel, % startSendLevel
}

clickUsingMode(x = "", y = "", mouseCoordMode = "") {
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
waitForHotkeyRelease(hotkeyString = "") {
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
getKeyNameFromHotkeyChar(hotkeyChar = "") {
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

; Link the selected text with the given URL.
linkSelectedText(url) {
	if(!url)
		return
	
	if(WinActive("ahk_exe ONENOTE.EXE")) {
		Send, ^k
		WinWaitActive, Link ahk_class NUIDialog
		if(!WinActive("Link ahk_class NUIDialog"))
			return
		sendTextWithClipboard(url)
		Send, {Enter}{Right}
	} else if(WinActive("ahk_exe OUTLOOK.EXE")) {
		Send, ^k
		WinWaitActive, ahk_class bosa_sdm_Mso96
		if(!WinActive("ahk_class bosa_sdm_Mso96"))
			return
		sendTextWithClipboard(url)
		Send, {Enter}
	} else if(WinActive("ahk_exe WINWORD.EXE")) {
		Send, ^k
		WinWaitActive, ahk_class bosa_sdm_msword
		if(!WinActive("ahk_class bosa_sdm_msword"))
			return
		sendTextWithClipboard(url)
		Send, {Enter}
	} else if(WinActive("DLG ahk_exe EpicD82.exe ahk_class ThunderRT6MDIForm")) { ; EMC2, specifically DLG activities
		Send, ^k
		Sleep, 100 ; It's a fake pop-up so we can't wait for it (or sense it at all, really)
		sendTextWithClipboard(url)
		Send, {Enter}
	}
}
