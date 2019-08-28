#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
trayInfo := new ScriptTrayInfo("AHK: Color Picker", "color.ico", "colorRed.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone, trayInfo)

; Make mouse and pixel coordinate modes the same so they match
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen

; Set up gui settings
global GUI_WIDTH         := 100
global GUI_HEIGHT        := 50
global MOUSE_GUI_PADDING := 10
global FONT_SIZE := 14
global TEXT_HEIGHT := 26
global TEXT_X := 0
global TEXT_Y := (GUI_HEIGHT - TEXT_HEIGHT) / 2 ; Vertically centered

guiOptions := "-Caption "     ; No title bar/menu
guiOptions .= "+ToolWindow "  ; Don't include in taskbar
guiOptions .= "+AlwaysOnTop " ; Always on top
guiOptions .= "+Border "      ; Show a border



; Create gui to show color under mouse
Gui, % guiOptions

; Get color under mouse and show it in the gui
MouseGetPos(mouseX, mouseY)
colorUnderMouse := PixelGetColor(mouseX, mouseY, "RGB").removeFromStart("0x")


Gui, Color, % colorUnderMouse
Gui, Font, % "c" invertColor(colorUnderMouse) " s" FONT_SIZE


Gui, Add, Text, % "vColorText Center x" TEXT_X " y" TEXT_Y " w" GUI_WIDTH " h" TEXT_HEIGHT, % colorUnderMouse


guiX := mouseX + MOUSE_GUI_PADDING
guiY := mouseY - MOUSE_GUI_PADDING - GUI_HEIGHT

Gui, Show, % "NoActivate x" guiX " y" guiY " w" GUI_WIDTH " h" GUI_HEIGHT

Sleep, 1000



MouseGetPos(mouseX, mouseY)
colorUnderMouse := PixelGetColor(mouseX, mouseY, "RGB").removeFromStart("0x")


updateGui(colorUnderMouse)

moveGui(mouseX, mouseY)

; guiX := mouseX + MOUSE_GUI_PADDING
; guiY := mouseY - MOUSE_GUI_PADDING - GUI_HEIGHT
; Gui, Show, % "NoActivate x" guiX " y" guiY " w" GUI_WIDTH " h" GUI_HEIGHT



Sleep, 1000


Gui, Destroy


updateGui(colorToUse) {
	; Background is the current color
	Gui, Color, % colorToUse
	
	; Text is the current color
	GuiControl, , ColorText, % colorToUse
	
	; Text color is the inverse of the background color
	Gui, Font, % "c" invertColor(colorToUse) " s" FONT_SIZE
	GuiControl, Font, ColorText
}

moveGui(mouseX, mouseY) {
	guiX := mouseX + MOUSE_GUI_PADDING
	guiY := mouseY - MOUSE_GUI_PADDING - GUI_HEIGHT
	Gui, Show, % "NoActivate x" guiX " y" guiY " w" GUI_WIDTH " h" GUI_HEIGHT
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