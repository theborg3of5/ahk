/*
	Reference/inspired by: https://www.autohotkey.com/boards/viewtopic.php?t=45606
	Do
		Consider a magnified display of pixel and surrounding few, instead (or in addition to?) the color in question
*/

#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
trayInfo := new ScriptTrayInfo("AHK: Color Picker", "color.ico", "colorRed.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone, trayInfo)

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

; Make mouse and pixel coordinate modes the same so they match
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen

Gui, 2:-Caption +ToolWindow +AlwaysOnTop +Border ; No title bar/menu, don't include in taskbar, always on top, show a border
Gui, 2:Font, s16, Consolas
Gui, 2:Margin, 0, 0

charWidth := 6

startX := 0
startY := -charWidth - 1

y := startY
Loop, % MAGNIFIER_GRID_SIZE {
	x := startX
	yCoord := A_Index.prePadToLength(2, "0")
	
	if(mod(A_Index, 2))
		rowColor := "00FF00"
	else
		rowColor := "FF0000"
	
	Loop, % MAGNIFIER_GRID_SIZE {
		xCoord := A_Index.prePadToLength(2, "0")
		
		if(mod(A_Index, 2))
			color := "0000FF"
		else
			color := rowColor
		Gui, 2:Font, c%color%
		; DEBUG.popup("color",color, "rowColor",rowColor, "mod(A_Index,2)", mod(A_Index, 2))
		
		; DEBUG.popup("Creating grid",, "xCoord",xCoord, "yCoord",yCoord)
		
		Gui, 2:Add, Text, % "x" x " y" y " BackgroundTrans vColorSquare" xCoord yCoord, ▘ ; Top-left square (unicode block character U+2598)
		x += charWidth
	}
	
	y += charWidth
}

; x := 0
; y := 1
; Gui, 2:Add, Text, % "x" x " y" y " BackgroundTrans", ▘

width  := charWidth * MAGNIFIER_GRID_SIZE
height := charWidth * MAGNIFIER_GRID_SIZE

Gui, 2:Show, % "w" width " h" height, % GUI_TITLE

buildGui()
Loop
	updateGui()
ExitApp



; Copy color, display result, and exit.
RButton::
	Gui, Hide
	captureColor()
	ExitApp
return


buildGui() {
	; Set overall gui properties
	Gui, -Caption +ToolWindow +AlwaysOnTop +Border ; No title bar/menu, don't include in taskbar, always on top, show a border
	Gui, Show, % "w" GUI_WIDTH " h" GUI_HEIGHT " Hide", % GUI_TITLE ; Set size (but don't show yet)
	Gui, Font, % " s" FONT_SIZE, % FONT_NAME

	; Add label
	textHeight := FONT_HEIGHT
	textWidth  := GUI_WIDTH ; Same width so we can center horizontally
	textX      := 0
	textY      := (GUI_HEIGHT - textHeight) / 2 ; Vertically centered
	Gui, Add, Text, % "vColorText Center x" textX " y" textY " w" textWidth " h" textHeight ; ColorText is global variable to reference this control by
}


updateGui() {
	; Get color under mouse
	MouseGetPos(mouseX, mouseY)
	foundColor := getRGBUnderMouse(mouseX, mouseY)
	
	; Background is the current color
	Gui, Color, % foundColor
	
	; Text shows the current color
	GuiControl, , ColorText, % foundColor
	
	; Text color is the inverse of the background color
	Gui, Font, % "c" invertColor(foundColor)
	GuiControl, Font, ColorText
	
	magnifiedColor := []
	Loop, % MAGNIFIER_GRID_SIZE {
		relativeY := (A_Index - MAGNIFIER_RADIUS - 1) ; -1 gets us to 0 when we match the mouse, negative because that's how y values work on screen
		; DEBUG.popup("xCoord",xCoord, "relativeX",relativeX, "yCoord",yCoord, "relativeY",relativeY)
		
		; yCoord := A_Index.prePadToLength(2, "0")
		
		Loop, % MAGNIFIER_GRID_SIZE {
			relativeX := A_Index - MAGNIFIER_RADIUS - 1 ; -1 gets us to 0 when we match the mouse
			; DEBUG.popup("A_Index",A_Index, "relativeX",relativeX)
			; xCoord := A_Index.prePadToLength(2, "0")
			
			if(!IsObject(magnifiedColor[relativeX]))
				magnifiedColor[relativeX] := []
			magnifiedColor[relativeX, relativeY] := getRGBUnderMouse(mouseX + relativeX, mouseY + relativeY)
			; DEBUG.popup("Updating color",, "xCoord",xCoord, "yCoord",yCoord, "magnifiedColor",magnifiedColor)
			; Gui, 2:Font, % "c" magnifiedColor
			; GuiControl, 2:Font, ColorSquare%xCoord%%yCoord%
		}
	}
	
	; DEBUG.popup("magnifiedColor",magnifiedColor)
	
	Loop, % MAGNIFIER_GRID_SIZE {
		relativeY := (A_Index - MAGNIFIER_RADIUS - 1) ; -1 gets us to 0 when we match the mouse, negative because that's how y values work on screen
		; DEBUG.popup("xCoord",xCoord, "relativeX",relativeX, "yCoord",yCoord, "relativeY",relativeY)
		
		yCoord := A_Index.prePadToLength(2, "0")
		
		Loop, % MAGNIFIER_GRID_SIZE {
			relativeX := A_Index - MAGNIFIER_RADIUS - 1 ; -1 gets us to 0 when we match the mouse
			; DEBUG.popup("A_Index",A_Index, "relativeX",relativeX)
			xCoord := A_Index.prePadToLength(2, "0")
			
			; magnifiedColor := getRGBUnderMouse(mouseX + relativeX, mouseY + relativeY)
			; DEBUG.popup("Updating color",, "xCoord",xCoord, "yCoord",yCoord, "magnifiedColor",magnifiedColor)
			
			; DEBUG.popup("Updating color",, "relativeX",relativeX, "relativeY",relativeY, "magnifiedColor[relativeX,relativeY]",magnifiedColor[relativeX, relativeY])
			
			Gui, 2:Font, % "c" magnifiedColor[relativeX, relativeY]
			GuiControl, 2:Font, ColorSquare%xCoord%%yCoord%
		}
	}
	
	moveGui(mouseX, mouseY)
}

getRGBUnderMouse(mouseX := "", mouseY := "") {
	if(mouseX = "" || mouseY = "")
		MouseGetPos(mouseX, mouseY)
	
	rawColor := PixelGetColor(mouseX, mouseY, "RGB")
	color := rawColor.removeFromStart("0x")
	
	return color
}

moveGui(mouseX, mouseY) {
	; Gui lives a little above and to the right of the cursor by default
	guiX := mouseX + MOUSE_GUI_PADDING
	guiY := mouseY - MOUSE_GUI_PADDING - GUI_HEIGHT
	
	bounds := getWindowMonitorWorkArea(GUI_TITLE)
	
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

captureColor() {
	foundColor := getRGBUnderMouse()
	setClipboardAndToastValue(foundColor, "RGB color code")
	Sleep, 2000
}
