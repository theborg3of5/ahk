
setTrayIcon(iconPath) {
	if(!iconPath || !FileExist(iconPath))
		return ""
	
	originalIconPath := A_IconFile ; Back up the current icon before changing it.
	Menu, Tray, Icon, % iconPath
	
	return originalIconPath
}

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

; Assumes that the formatting and default gui that would apply to the text in question is currently in effect.
getLabelWidthForText(text) {
	getLabelSizeForText(text, width)
	return width
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

fadeGuiIn(guiId, maxOpacity := 255, numSteps := 10) {
	if(!guiId)
		return
	
	startOpacity := WinGet("Transparent", "ahk_id " guiId)
	if(startOpacity = "")
		startOpacity := 0 ; If no transparency value set yet, just use 0.
	
	fadeGui(guiId, startOpacity, maxOpacity, numSteps)
}

fadeGuiOut(guiId, numSteps := 10) {
	startOpacity := WinGet("Transparent", "ahk_id " guiId)
	fadeGui(guiId, startOpacity, 0, numSteps)
}

fadeGui(guiId, startOpacity, finalOpacity, numSteps := 10) {
	if(!guiId)
		return
	
	Gui, % guiId ":Default"
	stepSize := (finalOpacity - startOpacity) / numSteps
	Loop, %numSteps% {
		WinSet, Transparent, % startOpacity + (A_Index * stepSize), % "ahk_id " guiId
		Sleep, 10 ; 10ms between steps - can vary fade speed with number of steps
	}
}

invertColor(color) {
	; Get RGB bits as integers
	r := hexToInteger(color.sub(1, 2))
	g := hexToInteger(color.sub(3, 2))
	b := hexToInteger(color.sub(5))
	
	; Reverse integers
	newR := 255 - r
	newG := 255 - g
	newB := 255 - b
	
	; Convert back to hex and recombine
	finalR := numToHex(newR).prePadToLength(2, "0")
	finalG := numToHex(newG).prePadToLength(2, "0")
	finalB := numToHex(newB).prePadToLength(2, "0")
	
	return StringUpper(finalR finalG finalB)
}
