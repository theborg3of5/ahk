; Hotkeys for VB6 IDE.

#IfWinActive, ahk_class wndclass_desked_gsk
	; Back and (sort of) forward like ES.
	!Left:: Send, ^+{F2}
	!Right::Send,  +{F2}
	
	 ^g::Send,  {F3}
	^+g::Send, +{F3}
	
	; Redo, not yank.
	 ^y::
	^+z::
		Send, !e
		Sleep, 100
		Send, r
	return
	
	; Make (compile).
	^m::
		Send, !f
		Sleep, 100
		Send, k
	return
	
	; Remap debug hotkeys.
	 F10::Send,  +{F8} ; Step over
	 F11::Send,   {F8} ; Step into
	+F11::Send, ^+{F8} ; Step out of
	 F12::Send,  ^{F8} ; Run to cursor.
	
	; Epic VB Parse Addin.
	^+p::
		Send, !a
		Sleep, 100
		Send, {Up 2}{Enter}
	return
	
	; References window.
	^+r::
		Send, !p
		Sleep, 100
		Send, n
	return
	
	; Components window.
	$^r::Send, ^t
	
	; Contact comment hotkeys.
	 ^8::SendRaw, % generateContactComment()
	^+8::SendRaw, % generateContactComment(true)
	^!8::SendRaw, % generateContactComment(    , true)
	
	; Triple ' hotkey for procedure header, like ES.
	:*:'''::
		Send, !a
		Sleep, 100
		Send, {Up}{Enter}
		Send, !p
	return
	
	; Comment and indentation for new lines.
	 ^Enter::addNewCommentLineWithIndent()   ; Normal line
	^+Enter::addNewCommentLineWithIndent(15) ; Function headers (lines up with edge of description, etc.)
	
	; Code vs. design swap. Note: only works if mini-window within window is maximized within outer window.
	Pause::
		toggleVB6CodeDesign() {
			mode := getFirstStringBetweenStr(WinGetTitle("A"), "(", ")")
			if(mode = "Code") {
				Send, +{F7}
			} else if(mode = "Form" || mode = "UserControl") {
				Send, {F7}
			}
		}
	
	; Add basic error handler stuff.
	^+e::
		addVB6ErrorHandler() {
			vbGetComboBoxClasses("", procedureComboClass)
			currentProcedure := ControlGet("List", "Selected", procedureComboClass)
			; DEBUG.popup("Current procedure", currentProcedure)
			if(!currentProcedure)
				MsgBox, No function name found.
			
			; Assuming that we're starting in the middle of an empty function.
			Send, {Tab}On Error Goto Handler{Enter}
			Send, {Enter}{Backspace}
			Send, Exit Sub{Enter}
			Send, Handler:{Enter}
			Send, {Tab}Call ErrorHandler("%currentProcedure%")
		}
	
	; Comment/uncomment
	 ^`;::clickUsingMode(126, 37, "Client")
	^+`;::clickUsingMode(150, 39, "Client")
	
	; Close current 'window' within VB.
	^w::
		closeCurrentFile() {
			window := new VisualWindow("A")
			closeButtonX := window.rightX - 10 ; Close button lives 10px from right edge of window
			closeButtonY := window.topY   + 45 ; 10px from the top of the window
			clickUsingMode(closeButtonX, closeButtonY, "Screen")
		}
#IfWinActive

; Builds a contact comment with as much info as we can muster.
generateContactComment(extraSpace := false, excludeDash := false) {
	; Date
	date := FormatTime(, "MM/yy")
	
	; DLG - uses VBG title, usually "Project Group - DLG######" or "Project - DLG######"
	projectName := ControlGetText("PROJECT1")
	dlgName := cleanupText(projectName, ["Project", "Group", "-"])
	if(!stringStartsWith(dlgName, "DLG")) {
		Toast.showError("Failed to find DLG ID", "DLG name is not DLG######: " dlgName)
		return
	}
	dlgId := removeStringFromStart(dlgName, "DLG")
	
	; Ignore anything after a dash (usually used by me so I can break up projects).
	dlgId := getStringBeforeStr(dlgId, "-")
	
	outStr := "' "
	if(extraSpace)
		outStr .= " "
	outStr .= "*" MainConfig.private["INITIALS"] " " date " " dlgId
	
	if(!excludeDash)
		outStr .= " - "
	
	return outStr
}

; Obtains the classNNs for the two top comboboxes.
vbGetComboBoxClasses(ByRef objectComboClass, ByRef procedureComboClass) {
	WinGet, ctlList, ControlList, A
	; DEBUG.popup(List, "Control list in window")
	
	Loop, Parse, ctlList, `n  ; Rows are delimited by linefeeds (`n).
	{
		if(InStr(A_LoopField, "ComboBox")) {
			ControlGetPos, x, y, w, h, %A_LoopField%, A
			; DEBUG.popup(A_LoopField, "Class name", A_Index, "On row", x, "X", y, "Y")
			
			; When two in a row have the same y value, they're what we're looking for.
			if(y = yPast) {
				; DEBUG.popup(x, "Got two! `nX", y, "Y", yPast, "Y past")
				procedureComboClass := A_LoopField
				
				break
			}
			
			yPast := y
			objectComboClass := A_LoopField
		}
	}
	
	; DEBUG.popup("Object", objectComboClass, "Procedure", procedureComboClass)
}

addNewCommentLineWithIndent(numSpaces := 1) {
	Send, {Enter}
	Send, '
	Send, {Space %numSpaces%}
}
