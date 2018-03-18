global lastGuiId = 0

getNextGuiId() {
	lastGuiId++
	
	; 100 should be a reasonable limit to wrap around from if scripts run long enough to need to wrap.
	if(lastGuiId = 100)
		lastGuiId = 1
	
	return lastGuiId
}

setTrayIcon(iconPath) {
	if(!iconPath || !FileExist(iconPath))
		return ""
	
	originalIconPath := A_IconFile ; Back up the current icon before changing it.
	Menu, Tray, Icon, % iconPath
	
	return originalIconPath
}

applyTitleFormat() {
	Gui, Font, w600 underline ; Heavier weight (not quite bold), underline.
}
clearTitleFormat() {
	Gui, Font, norm
}

; Assumes that the formatting that would apply to the text in question is currently in effect.
getLabelWidthForText(name, uniqueId) {
	static ; Assumes-static mode - means that any variables that are used in here are assumed to be static
	Gui, Add, Text, vVar%uniqueId%, % name
	out := GuiControlGet("Pos", "Var" uniqueId)
	GuiControl, Hide, Var%uniqueId%
	
	return outW
}

; Assumes the default gui name is set to whatever GUI you want to deal with.
addInputField(varName, x, y, width, height, data) {
	global          ; This allows us to get at the variable named in varName later on.
	%varName% := "" ; Clear the variable so there's no bleed-over from previous uses.
	Gui, Add, Edit, v%varName% x%x% y%y% w%width% h%height% -E0x200 +Border, % data
}
