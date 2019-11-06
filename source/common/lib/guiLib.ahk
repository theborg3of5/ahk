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
	; DESCRIPTION:    Apply/clear a title format (heavy weight, underline) for the next set of
	;                 controls being added to the gui.
	;---------
	applyTitleFormat() {
		Gui, Font, w600 underline ; Heavier weight (not quite bold), underline.
	}
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
	; DESCRIPTION:    Create/get the value of a global which can be used with a control, to
	;                 reference that control (with GuiControl) or get the value of the control
	;                 (with .getDynamicGlobal) later.
	; PARAMETERS:
	;  varName (I,REQ) - The name of the global variable to create/get the value of.
	; RETURNS:        getDynamicGlobal: the value in the specified global.
	; NOTES:          This basically exists to let us hide the static/global requirement for
	;                 variables used by gui controls - as long as the global is only referenced
	;                 via indirection, it won't be treated as a local variable in other functions.
	;---------
	createDynamicGlobal(varName) {
		global
		%varName% := ""
	}
	getDynamicGlobal(varName) {
		global
		local value := %varName%
		return value
	}
	; #END#
}

