#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
ScriptTrayInfo.Init("AHK: Color Picker", "color.ico", "colorRed.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)

; Gui settings
global GUI_SPACING         := 10 ; For margins, space between labels, etc.
global MOUSE_GUI_PADDING   := 10 ; Space between the mouse and the gui
global MAGNIFIER_RADIUS    := 5
global MAGNIFIER_GRID_SIZE := 2 * MAGNIFIER_RADIUS + 1

; Label settings
global FONT_NAME := "Consolas"
global FONT_SIZE := 14 ; Points

global GuiWidth, GuiHeight ; Calculated based on contents
global LabelHex, LabelRGB ; reference variables for labels

global GuiId ; Window handle for the gui.

; Make mouse and pixel coordinate modes both relative to the screen (not the window)
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen

; Show a toast describing the hotkeys that can be used
hotkeyDisplay := "
	(
		Right-click: Copy hex color to clipboard
		Ctrl + Right-click: Copy RGB color to clipboard
		Middle-click: Hold RGB color to send to a color dialog
	)"

new Toast(hotkeyDisplay).showMedium()

buildGui()
Loop
	updateGui()
ExitApp


; Copy hex color
RButton::
	finishGui()
	hexColor := getColorUnderMouse()
	
	ClipboardLib.set(hexColor)
	new Toast("Clipboard set to hex color code:`n" hexColor).blockingOn().showMedium()
	ExitApp
return

; Copy RGB color
^RButton::
	finishGui()
	hexColor := getColorUnderMouse()
	
	RGB := hexColorToRGB(hexColor)
	rgbColor := "(" RGB["R"] "," RGB["G"] "," RGB["B"] ")"
	
	ClipboardLib.set(rgbColor)
	new Toast("Clipboard set to RGB color code:`n" rgbColor).blockingOn().showMedium()
	ExitApp
return

; Send RGB to a color dialog
MButton::
	finishGui()
	hexColor := getColorUnderMouse()
	
	RGB := hexColorToRGB(hexColor)
	rgbColor := "(" RGB["R"] "," RGB["G"] "," RGB["B"] ")"
	
	t := new Toast("Ready to send RGB color to a color dialog: " rgbColor "`nMiddle-click again to send").show()
	KeyWait, MButton, D
	
	Send, !r
	Send, % RGB["R"]
	Send, !g
	Send, % RGB["G"]
	Send, !u
	Send, % RGB["B"]
	
	t.close()
	ExitApp
return


buildGui() {
	; Set overall gui properties
	Gui, New, -Caption +ToolWindow +AlwaysOnTop +Border +HWNDGuiId ; No title bar/menu, don't include in taskbar, always on top, show a border, set GuiId := window handle (which can be used with ahk_id)
	Gui, Font, % " s" FONT_SIZE, % FONT_NAME
	Gui, Margin, % GUI_SPACING, % GUI_SPACING

	; Add label (vLabel* are Label* variables to reference these controls by)
	defaultText := "123456" ; The controls auto-size, so we need to give them something to start with. We're using a monospace font and everything is 6 chars wide, so this works well.
	Gui, Add, Text, % "Center vLabelHex"                     , % defaultText
	Gui, Add, Text, % "Center vLabelRGB y+" GUI_SPACING " R3", % defaultText ; RGB table goes a little lower and has 3 rows
	
	; Auto-size gui and store off size in globals
	Gui, Show, % "AutoSize Hide" ; Hide - don't actually show it until we have real values in place.
	settings := new TempSettings().detectHiddenWindows("On")
	WinGetPos, , , GuiWidth, GuiHeight, % "ahk_id " GuiId
	settings.restore()
}


updateGui() {
	; Get color under mouse
	MouseGetPos(mouseX, mouseY)
	hexColor := getColorUnderMouse(mouseX, mouseY)
	
	; Background is the current color
	Gui, Color, % hexColor
	
	; Text value is the current color
	GuiControl, , LabelHex, % hexColor
	GuiControl, , LabelRGB, % getRGBText(hexColor)
	
	; Text color is the inverse of the background color
	Gui, Font, % "c" invertColor(hexColor)
	GuiControl, Font, LabelHex
	GuiControl, Font, LabelRGB
	
	moveGui(mouseX, mouseY)
}

getColorUnderMouse(mouseX := "", mouseY := "") {
	if(mouseX = "" || mouseY = "")
		MouseGetPos(mouseX, mouseY)
	
	rawColor := PixelGetColor(mouseX, mouseY, "RGB")
	color := rawColor.removeFromStart("0x")
	
	return color
}

getRGBText(hexColor) {
	RGB := hexColorToRGB(hexColor)
	tt := new TextTable([ ["R",RGB["R"]], ["G",RGB["G"]], ["B",RGB["B"]] ]).setColumnDivider("   ")
	return tt.generateText()
}

hexColorToRGB(hex) {
	r := DataLib.hexToInteger(hex.sub(1, 2))
	g := DataLib.hexToInteger(hex.sub(3, 2))
	b := DataLib.hexToInteger(hex.sub(5))
	
	return {"R":r, "G":g, "B":b}
}

; hexColor should just be the hex code, no "0x" at the start like PixelGetColor returns it.
invertColor(hexColor) {
	; Get individual RGB bits and invert them
	RGB := hexColorToRGB(hexColor)
	newR := 255 - RGB["R"]
	newG := 255 - RGB["G"]
	newB := 255 - RGB["B"]
	
	; Convert back to hex and recombine
	finalR := DataLib.numToHex(newR).prePadToLength(2, "0")
	finalG := DataLib.numToHex(newG).prePadToLength(2, "0")
	finalB := DataLib.numToHex(newB).prePadToLength(2, "0")
	
	return StringUpper(finalR finalG finalB)
}

moveGui(mouseX, mouseY) {
	; Gui lives a little above and to the right of the cursor by default
	guiX := mouseX + MOUSE_GUI_PADDING
	guiY := mouseY - MOUSE_GUI_PADDING - GuiHeight
	
	bounds := WindowLib.getMouseMonitorBounds()
	
	; Check if we're past the right edge of the monitor
	distanceX := bounds["RIGHT"] - (guiX + GuiWidth) ; From right edge of gui to right edge of monitor
	if(distanceX < 0)
		guiX := mouseX - MOUSE_GUI_PADDING - GuiWidth ; Left side of cursor
	
	; Check if we're past the top edge of the monitor
	distanceY := guiY - bounds["TOP"] ; From top edge of gui to top edge of monitor
	if(distanceY < 0)
		guiY := mouseY + MOUSE_GUI_PADDING ; Below cursor
	
	Gui, Show, % "NoActivate x" guiX " y" guiY
}

finishGui() {
	; We need to specify the gui to affect since we created it using Gui, New and this could be a different thread (started by a hotkey).
	Gui, % GuiId ":Default"
	Gui, Destroy
}
