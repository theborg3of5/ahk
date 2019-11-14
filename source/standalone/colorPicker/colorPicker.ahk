#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
ScriptTrayInfo.Init("AHK: Color Picker", "color.ico", "colorRed.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)

; Gui settings
global GUI_TITLE         := "AHK_ColorPicker"
global GUI_WIDTH         := 100
global GUI_HEIGHT        := 50
global MOUSE_GUI_PADDING := 10

; Label settings
global FONT_NAME   := "Consolas"
global FONT_SIZE   := 14 ; Points
global FONT_HEIGHT := 24 ; Pixels, including padding
global ColorText ; reference variable for label

global MAGNIFIER_RADIUS := 5
global MAGNIFIER_GRID_SIZE := 2 * MAGNIFIER_RADIUS + 1

; Make mouse and pixel coordinate modes both relative to the screen (not the window)
Setters.coordMode("Mouse", "Screen")
Setters.coordMode("Pixel", "Screen")

buildGui()
Loop
	updateGui()
ExitApp



; Copy color, display result, and exit.
RButton::
	Gui, Hide
	
	foundColor := getRGBUnderMouse()
	if(foundColor = "") {
		new ErrorToast("Failed to get RGB color code").blockingOn().showMedium()
		ExitApp
	}
	
	ClipboardLib.set(foundColor)
	new Toast("Clipboard set to " "RGB color code" ":`n" foundColor).blockingOn().showMedium()
	ExitApp
return


buildGui() {
	; Set overall gui properties
	Gui, -Caption +ToolWindow +AlwaysOnTop +Border ; No title bar/menu, don't include in taskbar, always on top, show a border
	Gui, Show, % "w" GUI_WIDTH " h" GUI_HEIGHT " Hide", % GUI_TITLE ; Set size (but don't show yet)
	Gui, Font, % " s" FONT_SIZE, % FONT_NAME

	; Add label
	textHeight := FONT_HEIGHT
	textWidth  := GUI_WIDTH ; Full width so we can center horizontally
	textX      := 0 ; Left side so we cover the width fully
	textY      := (GUI_HEIGHT - textHeight) / 2 ; Vertically centered
	Gui, Add, Text, % "vColorText Center x" textX " y" textY " w" textWidth " h" textHeight ; ColorText is global variable to reference this control by
}


updateGui() {
	; Get color under mouse
	MouseGetPos(mouseX, mouseY)
	foundColor := getRGBUnderMouse(mouseX, mouseY)
	
	; Background is the current color
	Gui, Color, % foundColor
	
	; Text value is the current color
	GuiControl, , ColorText, % foundColor
	
	; Text color is the inverse of the background color
	Gui, Font, % "c" invertColor(foundColor)
	GuiControl, Font, ColorText
	
	moveGui(mouseX, mouseY)
}

getRGBUnderMouse(mouseX := "", mouseY := "") {
	if(mouseX = "" || mouseY = "")
		MouseGetPos(mouseX, mouseY)
	
	rawColor := PixelGetColor(mouseX, mouseY, "RGB")
	color := rawColor.removeFromStart("0x")
	
	return color
}

invertColor(color) {
	; Get RGB bits as integers
	r := DataLib.hexToInteger(color.sub(1, 2))
	g := DataLib.hexToInteger(color.sub(3, 2))
	b := DataLib.hexToInteger(color.sub(5))
	
	; Reverse integers
	newR := 255 - r
	newG := 255 - g
	newB := 255 - b
	
	; Convert back to hex and recombine
	finalR := DataLib.numToHex(newR).prePadToLength(2, "0")
	finalG := DataLib.numToHex(newG).prePadToLength(2, "0")
	finalB := DataLib.numToHex(newB).prePadToLength(2, "0")
	
	return StringUpper(finalR finalG finalB)
}

moveGui(mouseX, mouseY) {
	; Gui lives a little above and to the right of the cursor by default
	guiX := mouseX + MOUSE_GUI_PADDING
	guiY := mouseY - MOUSE_GUI_PADDING - GUI_HEIGHT
	
	bounds := WindowLib.getMouseMonitorBounds()
	
	; Check if we're past the right edge of the monitor
	distanceX := bounds["RIGHT"] - (guiX + GUI_WIDTH) ; From right edge of gui to right edge of monitor
	if(distanceX < 0)
		guiX := mouseX - MOUSE_GUI_PADDING - GUI_WIDTH ; Left side of cursor
	
	; Check if we're past the top edge of the monitor
	distanceY := guiY - bounds["TOP"] ; From top edge of gui to top edge of monitor
	if(distanceY < 0)
		guiY := mouseY + MOUSE_GUI_PADDING ; Below cursor
	
	Gui, Show, % "NoActivate x" guiX " y" guiY " w" GUI_WIDTH " h" GUI_HEIGHT
}
