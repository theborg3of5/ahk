; Gui-related helper functions.

class GuiLib {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Show the user a yes/no confirmation popup to the user.
	; PARAMETERS:
	;  message (I,REQ) - The message to show in the popup.
	;  title   (I,OPT) - The title of the popup
	; RETURNS:        true/false - whether the user clicked the "Yes" button.
	;---------
	static showConfirmationPopup(message, title := "") {
		result := MsgBox(message, title, "YesNo")
		return (result = "Yes")
	}
	
	;---------
	; DESCRIPTION:    Apply a title format (heavy weight, underline) for the next set of controls
	;                 being added to the gui.
	;---------
	static applyTitleFormat(guiObj) {
		guiObj.SetFont("w600 underline") ; Heavier weight (not quite bold), underline.
	}
	;---------
	; DESCRIPTION:    Clear a title format (heavy weight, underline) for the next set of controls
	;                 being added to the gui.
	;---------
	static clearTitleFormat(guiObj) {
		guiObj.SetFont("norm")
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
	static getLabelSizeForText(guiObj, text, &width := "", &height := "") {
		ctrl := guiObj.Add("Text", , text)
		ctrl.GetPos(, , &width, &height)
		ctrl.Visible := false
	}
	
	;endregion ------------------------------ PUBLIC ------------------------------
}

