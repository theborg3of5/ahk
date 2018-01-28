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
		
		; Make hotkey (Group sans ED.vbp)
		^+m::
			Send, !f
			Sleep, 100
			Send, g
			WinWaitActive, Microsoft Visual Basic
			Send, +{Tab 2}
			Send, {Home}{Space}
			; Send, !b
		return
		
		; ; Stop when running.
		; $F12::
			; Send, !r
			; Sleep, 100
			; Send, e
		; return
		
		; Bookmark controls.
		; Toggle bookmark.
		F2::
			Send, !e
			Send, bb
			Send, {Right}
			Send, t
		return
		
		; Next/previous bookmark.
		^]::
			Send, !e
			Send, bb
			Send, {Right}
			Send, n
		return
		^[::
			Send, !e
			Send, bb
			Send, {Right}
			Send, p
		return
		
		; Make debug hotkeys same as in ES.
		; ; Toggle breakpoint.
		; F3::
			; Send, {F9}
		; return
		
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
		
		; Options.
		$!o::
			Send, {Blind}t ; Because it's an ALT+ hotkey, alt coming up prematurely disrupted the selection. So, just use the alt already down.
			Sleep, 250
			Send, o
		return
		
		; Epic Headers Addin.
		^+h::
			Send, !a
			Sleep, 100
			Send, {Up}{Enter}
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
		WinGetTitle, title
		StringTrimRight, title, title, 2
		parenPos := InStr(title, "(")
		StringTrimLeft, title, title, parenPos
		
		if(title = "Code") {
			Send, +{F7}
		} else if(title = "Form" || title = "UserControl") {
			Send, {F7}
		}
	return
	
	; Add basic error handler stuff.
	^+e::
		vbGetComboBoxClasses("", procedureComboClass)
		ControlGet, currentProcedure, List, Selected, %procedureComboClass%
		; DEBUG.popup("Current procedure", currentProcedure)
		if(!currentProcedure)
			MsgBox, No function name found.
		
		; Assuming that we're starting in the middle of an empty function.
		Send, {Tab}On Error Goto Handler{Enter}
		Send, {Enter}{Backspace}
		Send, Exit Sub{Enter}
		Send, Handler:{Enter}
		Send, {Tab}Call ErrorHandler("%currentProcedure%")
	return
	
	{ ; Button-based hotkeys.
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
	
	{ ; Large, loop-over-everything hotkeys.	
		; Create all required procedure stubs from an interface.
		^+f::
			vbGetComboBoxClasses(objectComboClass, procedureComboClass)
			; DEBUG.popup("Object", objectComboClass, "Procedure", procedureComboClass)
			
			ControlGet, objectName, List, Selected, %objectComboClass%
			; DEBUG.popup("Current object", objectName)
			
			; Allow being on "Implements ..." line instead of having left combobox correctly selected first.
			if(objectName = "(General)") {
				ClipSave := clipboard ; Save the current clipboard.
				
				Send, {End}{Shift Down}{Home}{Shift Up}
				Send, ^c
				
				Sleep, 100 ; Allow clipboard time to populate.
				
				lineString := clipboard
				clipboard := ClipSave ; Restore clipboard
				
				; Pull the class name from the implements statement.
				StringTrimLeft, className, lineString, 11
				
				; Trims trailing spaces via "Autotrim" behavior.
				className = %className%
				
				; Open the dropdown so we can see everything.
				ControlFocus, %objectComboClass%, A
				Send, {Down}
				Sleep, 100
				
				ControlGet, ObjectList, List, , %objectComboClass%
				; DEBUG.popup("List of objects", ObjectList)
				
				classRow := 0
				
				Loop, Parse, ObjectList, `n  ; Rows are delimited by linefeeds (`n).
				{
					if(A_LoopField = className) {
						; DEBUG.popup("Class name", className, "Is on row", A_Index)
						classRow := A_Index
						break
					}
				}
				
				Control, Choose, %classRow%, %objectComboClass%, A
			}
			
			LastItem := ""
			SelectedItem := ""
			
			ControlFocus, %objectComboClass%, A
			Send, {Down}
			
			Sleep, 100
			
			ControlGet, List, List, , %procedureComboClass%
			; DEBUG.popup("List of functions", List)
			
			RegExReplace(List, "`n", "", countNewLines)
			countNewLines++
			
			Loop %countNewLines% {
				ControlFocus, %procedureComboClass%, A
				Control, Choose, %A_Index%, %procedureComboClass%, A
			}
		return
		
		; Add function headers to all functions.
		^!h::
			vbGetComboBoxClasses(objectComboClass, procedureComboClass)
			; DEBUG.popup("Object", objectComboClass, "Procedure", procedureComboClass)
			
			objectComboValue := ""
			objectComboValuePast := ""
			procedureComboValue := ""
			procedureComboValuePast := ""
			
			; Module header.
			Send, !a
			Send, {Up}{Enter}
			WinWait, Epic Header Add-In
			Send, !m
			Sleep, 100
			
			Loop {
				Send, ^{Down}
				Sleep, 100
				
				ControlGetText, objectComboValue, %objectComboClass%, A
				ControlGetText, procedureComboValue, %procedureComboClass%, A
				; DEBUG.popup("Object combo value", objectComboValue, "Procedure combo value", procedureComboValue)
				
				if(objectComboValue = objectComboValuePast && procedureComboValue = procedureComboValuePast) {
					Break
				}
				procedureComboValuePast := procedureComboValue
				objectComboValuePast := objectComboValue
				
				; Add the header.
				Send, !a
				Send, {Up}{Enter}
				WinWait, Epic Header Add-In
				Send, !p
			}
		return
	}
#IfWinActive
}

{ ; References/components windows.
#If WinActive("References - ") || WinActive("Components")
	^f::
		; Get user input.
		prompt := "Enter the first portion of the row to find. Shortcuts: `n`t * `t Epic Systems `n`t *h `t Epic Systems Hospital Billing `n`t *p `t Epic Systems Resolute `n`t *e `t Epic Systems Enterprise Billing `n`t *f `t Epic Systems Foundations"
		InputBox, userIn, Partial Search, %prompt%
		if(ErrorLevel)
			return
		
		; Expand it as needed.
		userIn := convertSpecialStars(userIn)
		if(!userIn)
			return
		
		; Crawl the list and check it.
		if(!findReferenceLine(userIn)) {
			MsgBox, Reference not found in list!
		}
	return
#IfWinActive
}

{ ; Functions.
	; Builds a contact comment with as much info as we can muster.
	generateContactComment(extraSpace = false) {
		global USER_INITIALS
		
		; Date
		FormatTime, date, , MM/yy
		
		; DLG - uses VBG title, usually DLG######
		ControlGetText, projectName, PROJECT1
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
		WinGet, List, ControlList, A
		; DEBUG.popup(List, "Control list in window")
		
		Loop, Parse, List, `n  ; Rows are delimited by linefeeds (`n).
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

	; Finds and checks a single reference.
	findReferenceLine(lineToFind, numToMatch = 0, shouldSelect = false) {
		prevRow := ""
		numSame := 1
		foundPage := false
		
		if(WinActive("References - ")) {
			buttonNN := "Button5"
		} else if(WinActive("Components")) {
			buttonNN := "Button1"
		} else {
			return false
		}
		
		firstChar := SubStr(lineToFind, 1, 1)
		; MsgBox, % firstChar . "`n" . lineToFind
		
		; If what we're currently on is after what we want, start at the top.
		ControlGetText, currRow, %buttonNN%, A
		if(lineToFind < currRow, 1, StrLen(lineToFind)) {
			Send, {Home}
		}
		
		; Start with the first letter of the given input.
		SendRaw, %firstChar%
		
		; Loop downwards over the listbox - first by page, then by line.
		Loop {
			; Take a step down.
			if(!foundPage) {
				Send, {PgDn}
			} else {
				Send, {Down}
			}
			
			; Grab current item's identity.
			Sleep, 1
			ControlGetText, currRowFull, %buttonNN%, A
			; MsgBox, %currRowFull%
			
			; Trim it down to size to allow partial matching.
			currRow := SubStr(currRowFull, 1, StrLen(lineToFind))
			; MsgBox, %currRow%
			
			; Just in case we hit the end of the listbox: if we see the same row 10 times, finish.
			if(currRowFull = prevRow) {
				numSame++
			} else {
				numSame := 1
			}
			; MsgBox, Row: %currRow% `nPrevious: %prevRow% `nnumSame: %numSame%
			if(numSame = 10) {
				return false
			}
			prevRow := currRowFull
			
			; If it matches our input, finish.
			if(lineToFind = currRow) {
				; If we've got the additional argument, push down a few more before selecting.
				if(numToMatch) {
					numToMatch-- ; We're given the index, not the number of times we need to go down.
					Send, {Down %numToMatch%}
				}
				
				; Check and finish.
				if(shouldSelect)
					Send, {Space}
				return true
			
			; If we overshot it, back up a page and start going by single rows.
			} else if(currRow > lineToFind) {
				; MsgBox, %currRow% %lineToFind%
				
				; If we overshot it for the first time, go back a page and go by rows.
				if(!foundPage) {
					Send, {PgUp}
					foundPage := true
				
				; If we overshot once already, it's not here.
				} else {
					return false
				}
			}
		}
	}

	convertSpecialStars(toConvert) {
		if(SubStr(toConvert, 1, 1) != "*") {
			return toConvert
		} else {
			outStr := "Epic Systems"
			StringTrimLeft, toConvert, toConvert, 1
			
			firstChar := SubStr(toConvert, 1, 1)
			rest := SubStr(toConvert, 2)
			
			if(firstChar = "h")
				outStr .= " Hospital Billing"
			else if(firstChar = "p")
				outStr .= " Resolute"
			else if(firstChar = "e")
				outStr .= " Enterprise Billing"
			else if(firstChar = "f")
				outStr .= " Foundations"
			else
				outStr .= firstChar
			
			outStr .= rest
			
			return outStr
		}
	}
}