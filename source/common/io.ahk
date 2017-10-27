; Functions related to input/output and user input.

global TEXT_SOURCE_PASSED   := "PASS"
global TEXT_SOURCE_SEL_CLIP := "SELECTION/CLIPBOARD"
global TEXT_SOURCE_TITLE    := "TITLE"

; Get text from a control, send it to another, and focus a third.
ControlGet_Send_Return(fromControl, toControl, retControl = "") {
	ControlGetText, data, %fromControl%, A
	; DEBUG.popup("Data from control", data)
	
	ControlSend_Return(toControl, data, retControl)
}

; Send text to a particular control, then focus another.
ControlSend_Return(toControl, keys, retControl = "") {
	if(!retControl) {
		ControlGetFocus, retControl, A
	}
	; DEBUG.popup("Control to send to",toControl, "Control to return to",retControl, "Keys to send",keys)
	
	if(toControl) {
		ControlFocus, %toControl%
	}
	
	Sleep, 100
	Send, %keys%
	Sleep, 100
	ControlFocus, %retControl%, A
}

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
			StringTrimLeft, currLine, currLine, 1
			; DEBUG.popup(currLine, "After currLine", numTabs, "Number of tabs")
		}
		
		Send, {Tab %numTabs%}
		SendRaw, %currLine%
		Send, {Enter}
		Send, +{Tab %numTabs%}
	}
}

; Grabs the selected text using the clipboard, fixing the clipboard as it finishes.
getSelectedText() {
	ClipSaved := ClipboardAll ; Save the entire clipboard to a variable of your choice.
	clipboard :=              ; Clear the clipboard
	
	Send, ^c
	ClipWait, 1               ; Wait for the clipboard to actually contain data.
	
	textFound := clipboard
	
	clipboard := ClipSaved    ; Restore the original clipboard. Note the use of Clipboard (not ClipboardAll).
	ClipSaved =               ; Free the memory in case the clipboard was very large.
	
	return textFound
}

; Sends the selected text using the clipboard, fixing the clipboard as it finishes.
sendTextWithClipboard(text) {
	; DEBUG.popup(text, "Text to send with clipboard")
	
	ClipSaved := ClipboardAll   ; Save the entire clipboard to a variable of your choice.
	Clipboard := "" ; Clear the clipboard
	
	Clipboard := text
	Sleep, 100
	Send, ^v
	Sleep, 100
	
	Clipboard := ClipSaved   ; Restore the original clipboard. Note the use of Clipboard (not ClipboardAll).
	ClipSaved =   ; Free the memory in case the clipboard was very large.
}

; Runs a command line program and returns the result.
runAndReturnOutput(command, outputFile = "cmdOutput.tmp") {
	RunWait, %comspec% /c %command% > %outputFile%,,UseErrorLevel Hide
	outputFileContents := ""
	FileRead, outputFileContents, %outputFile%
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
		ControlGetText, tooltipText, , ahk_id %currID%
		if(tooltipText != "")
			outText .= tooltipText "`n"
	}
	StringTrimRight, outText, outText, 1
	
	return outText
}



clickUsingMode(x = "", y = "", mouseCoordMode = "") {
	; Store the old mouse position to move back to once we're finished.
	MouseGetPos, prevX, prevY
	
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
