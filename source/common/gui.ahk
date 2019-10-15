
showConfirmationPopup(message, title := "") {
	MsgBoxButtons_YesNo := 4
	MsgBox, % MsgBoxButtons_YesNo, % title, % message
	IfMsgBox, Yes
		return true
	return false
}

applyTitleFormat() {
	Gui, Font, w600 underline ; Heavier weight (not quite bold), underline.
}
clearTitleFormat() {
	Gui, Font, norm
}

; Assumes that the formatting and default gui that would apply to the text in question is currently in effect.
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

; These two basically let us hide the static/global requirement for variables used for GUI controls - 
; the given string is the variable name, but as long as it's only referenced via indirection, it won't 
; be treated as a local variable in other functions.
setDynamicGlobalVar(varName, value := "") {
	global
	%varName% := value
}
getDynamicGlobalVar(varName) {
	global
	local value := %varName%
	return value
}



