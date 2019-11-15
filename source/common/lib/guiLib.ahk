; Gui-related helper functions.

class GuiLib {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Show the user a yes/no confirmation popup to the user.
	; PARAMETERS:
	;  message (I,REQ) - The message to show in the popup.
	;  title   (I,OPT) - The title of the popup
	; RETURNS:        true/false - whether the user clicked the "Yes" button.
	;---------
	showConfirmationPopup(message, title := "") {
		MsgBoxButtons_YesNo := 4
		MsgBox, % MsgBoxButtons_YesNo, % title, % message
		IfMsgBox, Yes
			return true
		return false
	}
	
	;---------
	; DESCRIPTION:    Apply a title format (heavy weight, underline) for the next set of controls
	;                 being added to the gui.
	;---------
	applyTitleFormat() {
		Gui, Font, w600 underline ; Heavier weight (not quite bold), underline.
	}
	;---------
	; DESCRIPTION:    Clear a title format (heavy weight, underline) for the next set of controls
	;                 being added to the gui.
	;---------
	clearTitleFormat() {
		Gui, Font, norm
	}
	
	;---------
	; DESCRIPTION:    Get the size of a label with the given text.
	; PARAMETERS:
	;  text   (I,REQ) - The text to measure the size of.
	;  width  (O,OPT) - The width of the label needed to hold the given text.
	;  height (O,OPT) - The height of the label needed to hold the given text.
	; SIDE EFFECTS:   This adds a hidden label to the gui (specifically, adds it so we can see the
	;                 size, then hides it).
	; NOTES:          This assumes that the formatting/default gui for the text in question are
	;                 already in effect.
	;---------
	getLabelSizeForText(text, ByRef width := "", ByRef height := "") {
		global ; Needed for the dynamic variable used to reference the text control
		
		SizeMeasuringLabelUniqueId++
		local varName := "Var" SizeMeasuringLabelUniqueId
		
		Gui, Add, Text, % "v" varName, % text
		controlSize := GuiControlGet("Pos", varName)
		width  := controlSize["W"]
		height := controlSize["H"]
		
		GuiControl, Hide, % varName ; GuiControl, Delete not yet implemented, so just hide the temporary control.
	}
	
	;---------
	; DESCRIPTION:    Create a global to assign to a control so we can reference the control (with
	;                 GuiControl, or get the value with .getDynamicGlobal) dynamically.
	; PARAMETERS:
	;  varName (I,REQ) - The name of the global variable to create.
	; NOTES:          This basically exists to let us hide the static/global requirement for
	;                 variables used by gui controls - as long as the global is only referenced
	;                 via indirection, it won't be treated as a local variable in other functions.
	;---------
	createDynamicGlobal(varName) {
		global
		%varName% := ""
	}
	;---------
	; DESCRIPTION:    Get the value of a control using the dynamic global (created with
	;                 .createDynamicGlobal) that's assigned to it.
	; PARAMETERS:
	;  varName (I,REQ) - The name of the global variable to get the value of.
	; RETURNS:        The value in the specified global (aka the value of the control).
	; NOTES:          This basically exists to let us hide the static/global requirement for
	;                 variables used by gui controls - as long as the global is only referenced
	;                 via indirection, it won't be treated as a local variable in other functions.
	;---------
	getDynamicGlobal(varName) {
		global
		local value := %varName%
		return value
	}
	; #END#
}

