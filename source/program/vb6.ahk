{ ; Main VB window.
#IfWinActive, ahk_class wndclass_desked_gsk
	{ ; Normal replacements/shortcuts.
		; TLG Hotkey.
		^t::
			Send, %epicID%
		return
		
		; Back and (sort of) forward like ES.
		!Left::
			Send, ^+{F2}
		return
		!Right::
			Send, +{F2}
		return
		
		^g::Send, {F3}
		^+g::Send, +{F3}
		
		; Redo, not yank.
		^y::
		^+z::
			Send, !e
			Sleep, 100
			Send, r
		return
		
		; Make hotkey.
		^m::
			Send, !f
			Sleep, 100
			Send, k
		return
		
		; Make debug hotkeys same as in ES.
		; Step over.
		F10::
			Send, +{F8}
		return
		; Step into.
		F11::
			Send, {F8}
		return
		; Step out of.
		+F11::
			Send, ^+{F8}
		return
		; Run to cursor.
		F12::
			Send, ^{F8}
		return
		
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
		$^r::
			Send, ^t
		return
		
		; Contact comment hotkeys.
		^8::
			SendRaw, % generateContactComment()
		return
		^+8::
			SendRaw, % generateContactComment(true)
		return
		
		; Triple ' hotkey for procedure header, like ES.
		:*:'''::
			Send, !a
			Sleep, 100
			Send, {Up}{Enter}
			Send, !p
		return
		
		; Comment and indentation for new lines.
		^Enter:: ; Normal line
			Send, {Enter}
			Send, '{Space}
		return
		^+Enter:: ; Function headers (lines up with edge of description, etc.)
			Send, {Enter}
			Send, '{Space 15}
		return
	}
	
	; Code vs. design swap. Note: only works if mini-window within window is maximized within outer window.
	Pause::
		toggleVB6CodeDesign() {
			title := WinGetTitle("A")
			title := SubStr(title, 1, StrLen(title) - 2)
			parenPos := InStr(title, "(")
			title := SubStr(title, parenPos + 1)
			
			if(title = "Code") {
				Send, +{F7}
			} else if(title = "Form" || title = "UserControl") {
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
	
	{ ; GUI-button-based hotkeys.
		; Comment/uncomment hotkeys.
		^`;::
			clickUsingMode(126, 37, "Client")
		return
		^+`;::
			clickUsingMode(150, 39, "Client")
		return
		
		; Close code/design window.
		^w::
			clickUsingMode(1910, 11, "Client")
		return
	}
#IfWinActive
}

{ ; Functions.
	; Builds a contact comment with as much info as we can muster.
	generateContactComment(extraSpace = false) {
		global USER_INITIALS
		
		; Date
		date := FormatTime(, "MM/yy")
		
		; DLG - uses VBG title, usually DLG######
		projectName := ControlGetText("PROJECT1")
		splitName := StrSplit(projectName, A_Space)
		dlgName := splitName[splitName.MaxIndex()]
		dlgId := SubStr(dlgName, 4)
		
		; Ignore anything after a dash (usually used by me so I can break up projects).
		dashPosition := stringContains(dlgId, "-")
		if(dashPosition)
			dlgId := SubStr(dlgId, 1, dashPosition-1)
		
		outStr := "' "
		if(extraSpace)
			outStr .= " "
		outStr .= "*" USER_INITIALS " " date " " dlgId " - "
		
		return outStr
	}
	
	; Obtains the classNNs for the two top comboboxes.
	vbGetComboBoxClasses(ByRef objectComboClass, ByRef procedureComboClass) {
		ctlList := WinGet("ControlList", "A")
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
}