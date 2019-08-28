#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
trayInfo := new ScriptTrayInfo("AHK: Color Picker", "color.ico", "colorRed.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone, trayInfo)

; Gui settings
global GUI_WIDTH         := 100
global GUI_HEIGHT        := 50
global MOUSE_GUI_PADDING := 10

; Label settings
global FONT_NAME := "Consolas"
global FONT_SIZE   := 14 ; Points
global FONT_HEIGHT := 24 ; Pixels, including padding
global ColorText ; reference variable for label

; Make mouse and pixel coordinate modes the same so they match
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen

buildGui()


Loop {
	updateGui()
	Sleep, 1000
}

Gui, Destroy

RButton::
	
	
	ExitApp
return

buildGui() {
	; Create gui
	Gui, -Caption +ToolWindow +AlwaysOnTop +Border ; No title bar/menu, don't include in taskbar, always on top, show a border
	Gui, Show, % "w" GUI_WIDTH " h" GUI_HEIGHT " Hide" ; Set size (but don't show yet)
	Gui, Font, % " s" FONT_SIZE, % FONT_NAME

	; Add label
	textHeight := FONT_HEIGHT
	textWidth  := GUI_WIDTH ; Same width so we can center horizontally
	textX      := 0
	textY      := (GUI_HEIGHT - textHeight) / 2 ; Vertically centered
	Gui, Add, Text, % "vColorText Center x" textX " y" textY " w" textWidth " h" textHeight
}


updateGui() {
	; Get color under mouse
	MouseGetPos(mouseX, mouseY)
	colorToUse := PixelGetColor(mouseX, mouseY, "RGB").removeFromStart("0x")
	
	; Background is the current color
	Gui, Color, % colorToUse
	
	; Text shows the current color
	GuiControl, , ColorText, % colorToUse
	
	; Text color is the inverse of the background color
	Gui, Font, % "c" invertColor(colorToUse)
	GuiControl, Font, ColorText
	
	moveGui(mouseX, mouseY)
}

moveGui(mouseX, mouseY) {
	; Gui lives a little above and to the right of the cursor
	guiX := mouseX + MOUSE_GUI_PADDING
	guiY := mouseY - MOUSE_GUI_PADDING - GUI_HEIGHT
	
	; Adjust if we're up against the edge of the monitor
	; GDB TODO
	
	Gui, Show, % "NoActivate x" guiX " y" guiY " w" GUI_WIDTH " h" GUI_HEIGHT
}
