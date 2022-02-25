class VB6 {
	; #INTERNAL#
	
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
		currentObject    := ControlGet("List", "Selected", VB6.ClassNN_ObjectComboBox)
		currentProcedure := ControlGet("List", "Selected", VB6.ClassNN_ProcedureComboBox)
		if(currentObject != "(General)")
			functionName := currentObject "_" currentProcedure
		else
			functionName := currentProcedure
		; Debug.popup("currentObject",currentObject, "currentProcedure",currentProcedure, "functionName",functionName)
		
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
		VB6.clickUsingMode(closeButtonX, closeButtonY, "Screen")
	}
	
	
	; #PRIVATE#
	
	static ClassNN_ObjectComboBox    := "ComboBox1" ; Object dropdown in top-left
	static ClassNN_ProcedureComboBox := "ComboBox2" ; Procedure dropdown in top-right
	
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
		projectName := ControlGetText("PROJECT1", Config.windowInfo["VB6"].idString)
		dlgName := projectName.clean(["Project", "Group", "-"])
		if(!dlgName.startsWith("DLG")) {
			Toast.ShowError("Failed to find DLG ID", "DLG name is not DLG######: " dlgName)
			return ""
		}
		dlgId := dlgName.removeFromStart("DLG")
		
		; Ignore anything after a dash (usually added by me to break up projects that are too large to load together).
		dlgId := dlgId.beforeString("-")
		
		return dlgId
	}
	
	;---------
	; DESCRIPTION:    Click at the given coordinates, then move the mouse back to where it was before.
	; PARAMETERS:
	;  x              (I,REQ) - X coordinate to click at.
	;  y              (I,REQ) - Y coordinate to click at.
	;  mouseCoordMode (I,REQ) - The CoordMode to click with - Screen, Client, etc.
	;---------
	clickUsingMode(x, y, mouseCoordMode) {
		; Store the old mouse position to move back to once we're finished.
		MouseGetPos(prevX, prevY)
		
		settings := new TempSettings().coordMode("Mouse", mouseCoordMode)
		Click, %x%, %y%
		settings.restore()
		
		; Move the mouse back to its former position.
		MouseMove, prevX, prevY
	}
	; #END#
}
