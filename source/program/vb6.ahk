; Hotkeys for VB6 IDE.

#If Config.isWindowActive("VB6")
	; Back and (sort of - actually jump to definition) forward in history.
	!Left:: Send, ^+{F2}
	!Right::Send,  +{F2}
	
	; Find next/previous.
	 ^g::Send,  {F3}
	^+g::Send, +{F3}
	
	; Comment/uncomment
	 ^`;::clickUsingMode(126, 37, "Client")
	^+`;::clickUsingMode(150, 39, "Client")
	
	; Delete current line
	^d::VB6.deleteCurrentLine()
	
	; Close current 'window' within VB.
	^w::VB6.closeCurrentFile()
	
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
	
	; Components, References windows.
	$^r::Send, ^t
	^+r::
		Send, !p
		Sleep, 100
		Send, n
	return
	
	; Add contact comments
	 ^8::VB6.addContactComment()
	^+8::VB6.addContactCommentForHeader()
	^!8::VB6.addContactCommentNoDash()
	
	; Triple ' hotkey for procedure header, like ES.
	::'''::
		Send, !a
		Sleep, 100
		Send, {Up}{Enter}
		Send, !p
	return
	
	; Comment and indentation for new lines.
	 ^Enter::VB6.addNewCommentLineWithIndent()   ; Normal line
	^+Enter::VB6.addNewCommentLineWithIndent(15) ; Function headers (lines up with edge of description, etc.)
	
	; Code vs. design swap.
	Pause::VB6.toggleCodeAndDesign()
	
	; Add basic error handler stuff.
	^+e::VB6.addErrorHandlerForCurrentFunction()
#If

; VB6-specific actions. Everything should be called statically.
class VB6 {

; ==============================
; == Public ====================
; ==============================
	static objectComboBoxClassNN    := "ComboBox1" ; Object dropdown in top-left
	static procedureComboBoxClassNN := "ComboBox2" ; Procedure dropdown in top-right
	
	;---------
	; DESCRIPTION:    Add different variations on a contact comment at the current cursor position.
	;                 These are specific wrappers that send different versions of a contact comment
	;                 from .generateContactCommentText().
	;---------
	addContactComment() {                                     ; Basic:
		SendRaw, % VB6.generateContactCommentText()            ; ' *<initials> <DLG ID> - 
	}
	addContactCommentForHeader() {                            ; Extra space before *<initials>:
		SendRaw, % VB6.generateContactCommentText(true)        ; '  *<initials> <DLG ID> - 
	}
	addContactCommentNoDash() {                               ; No dash at end:
		SendRaw, % VB6.generateContactCommentText(false, true) ; ' *<initials> <DLG ID>
	}
	
	;---------
	; DESCRIPTION:    Add a new line starting at the current position, starting the new line with a
	;                 comment character and the given amount of indentation.
	; PARAMETERS:
	;  numSpaces (I,OPT) - Number of spaces to indent by. Defaults to 1.
	;---------
	addNewCommentLineWithIndent(numSpaces := 1) {
		Send, {Enter}
		Send, '
		Send, {Space %numSpaces%}
	}
	
	;---------
	; DESCRIPTION:    Delete the current line in VB.
	;---------
	deleteCurrentLine() {
		if(!VB6.isInCodeMode()) ; Don't do anything if we're not editing code.
			return
		
		Send, {End}{Right}               ; Start of next line, before its indentation
		Send, {Shift Down}{Up}{Shift Up} ; Select entire original line, including newline
		Send, {Delete}                   ; Delete the selection
		Send, {Home}                     ; Get to the start of the line, after indentation
	}
	
	;---------
	; DESCRIPTION:    Add error handler logic for current function.
	;---------
	addErrorHandlerForCurrentFunction() {
		currentObject    := ControlGet("List", "Selected", VB6.objectComboBoxClassNN)
		currentProcedure := ControlGet("List", "Selected", VB6.procedureComboBoxClassNN)
		if(currentObject != "(General)")
			functionName := currentObject "_" currentProcedure
		else
			functionName := currentProcedure
		; DEBUG.popup("currentObject",currentObject, "currentProcedure",currentProcedure, "functionName",functionName)
		
		Send, On Error Goto Handler{Enter} ; For top of function
		Send, {Enter}{Backspace} ; This and below for bottom of function
		Send, Exit Sub{Enter}
		Send, Handler:{Enter}
		Send, % "{Tab}Call ErrorHandler(""" functionName """)"
	}
	
	;---------
	; DESCRIPTION:    Toggle between the code and design views for the current object.
	; NOTES:          This only works if "window" within VB6 is "maximized".
	;---------
	toggleCodeAndDesign() {
		if(VB6.isInCodeMode()) {
			Send, +{F7}
		} else {
			Send, {F7}
		}
	}
	
	;---------
	; DESCRIPTION:    Close the current file.        
	;---------
	closeCurrentFile() {
		window := new VisualWindow("A")
		closeButtonX := window.rightX - 10 ; Close button lives 10px from right edge of window
		closeButtonY := window.topY   + 45 ; 10px from the top of the window
		clickUsingMode(closeButtonX, closeButtonY, "Screen")
	}
	
	
; ==============================
; == Private ===================
; ==============================
	
	;---------
	; DESCRIPTION:    Check whether the current window within VB is in "code" mode (as opposed to a design view).
	; RETURNS:        True if we're in code mode, False otherwise.
	;---------
	isInCodeMode() {
		return (WinGetTitle("A").firstBetweenStrings("(", ")") = "Code")
	}
	
	;---------
	; DESCRIPTION:    Builds the string for a contact comment in the current project.
	; PARAMETERS:
	;  extraSpace  (I,OPT) - Set to true to add an extra space after the comment character, before the *<initials>.
	;  excludeDash (I,OPT) - Set to true to not add <space>-<space> to the end of the string.
	; RETURNS:        Contact comment string. Basic format (note space at end):
	;                    ' *<initials> <DLG ID> - 
	;---------
	generateContactCommentText(extraSpace := false, excludeDash := false) {
		; Date and DLG ID
		date := FormatTime(, "MM/yy")
		dlgId := VB6.getDLGIdFromProject()
		if(dlgId = "")
			return
		
		outStr := "' "
		if(extraSpace)
			outStr .= " "
		outStr .= "*" Config.private["INITIALS"] " " date " " dlgId
		
		if(!excludeDash)
			outStr .= " - "
		
		return outStr
	}
	
	;---------
	; DESCRIPTION:    Find and return the current project's DLG ID (if one exists).
	; RETURNS:        DLG ID if one was found, "" otherwise
	;---------
	getDLGIdFromProject() {
		; Use the project/project group title, usually "Project Group - DLG######" or "Project - DLG######"
		projectName := ControlGetText("PROJECT1")
		dlgName := projectName.clean(["Project", "Group", "-"])
		if(!dlgName.startsWith("DLG")) {
			new ErrorToast("Failed to find DLG ID", "DLG name is not DLG######: " dlgName).showMedium()
			return ""
		}
		dlgId := dlgName.removeFromStart("DLG")
		
		; Ignore anything after a dash (usually added by me to break up projects that are too large to load together).
		dlgId := dlgId.beforeString("-")
		
		return dlgId
	}
}



