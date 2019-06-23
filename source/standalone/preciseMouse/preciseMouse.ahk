/* GDB TODO
	Lock the mouse?
		Until exit?
		Until click?
		Not at all?
	Arrow keys to move cursor
	Maybe modifier keys for bigger jumps, jump to other side of screen, etc.
	Holding some key (like spacebar?) could allow mouse movement until it's released?
		BlockInput, MouseMoveOff
*/

#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#Include <includeCommon>
setCommonHotkeysType(HOTKEY_TYPE_Standalone)
; setUpTrayIcons("controllerGreen.ico", "controllerRed.ico", "AHK: Controller Emulator")

global moveX := 0
global moveY := 0

; Don't allow the mouse to move while this is running (automatically releases on exit).
BlockInput, MouseMove

SetTimer, MainLoop, 10 ; GDB TODO ms, timer toggled by commonHotkeys' suspend hotkey.
MainLoop:
	; moveX := 0
	; moveY := 0
	; if(GetKeyState("Left"))
		; moveX -= 1
	; if(GetKeyState("Right"))
		; moveX += 1
	; if(GetKeyState("Up"))
		; moveY -= 1
	; if(GetKeyState("Down"))
		; moveY += 1
	
	; DEBUG.popup("moveX",moveX, "moveY",moveY)
	; if(moveX != 0 || moveY != 0) {
		; MouseMove, moveX, moveY, , R
		; moveX := 0
		; moveY := 0
	; }
	
return

; Up::
; Down::
; Left::
; Right::
	; return

; Left::
	; ; moveMouse(-1, 0)
	; moveX -= 1
; return
; Right::
	; ; moveMouse(1, 0)
	; moveX += 1
; return
; Up::
	; ; moveMouse(0, -1)
	; moveY -= 1
; return
; Down::
	; ; moveMouse(0, 1)
	; moveY += 1
; return

Left::
Right::
Up::
Down::
	updateMouse()
	return

updateMouse() {
	
	; DEBUG.popup("moveX",moveX, "moveY",moveY)
	
	; DEBUG.popup("GetKeyState(""Left"")",GetKeyState("Left"))
	
	; if(A_ThisHotkey = "Left" || GetKeyState("Left", "P"))
		; moveX -= 1
	; if(A_ThisHotkey = "Right" || GetKeyState("Right", "P"))
		; moveX += 1
	; if(A_ThisHotkey = "Up" || GetKeyState("Up", "P"))
		; moveY -= 1
	; if(A_ThisHotkey = "Down" || GetKeyState("Down", "P"))
		; moveY += 1
	
	
	if(GetKeyState("Left", "P"))
		moveX -= 1
	if(GetKeyState("Right", "P"))
		moveX += 1
	if(GetKeyState("Up", "P"))
		moveY -= 1
	if(GetKeyState("Down", "P"))
		moveY += 1
	
	if(moveX != 0 || moveY != 0) {
		MouseMove, moveX, moveY, , R
		moveX := 0
		moveY := 0
	}
	
	; DEBUG.popup("moveX",moveX, "moveY",moveY)
}


moveMouse(x, y) {
	MouseMove, x, y, , R
}


#Include <commonHotkeys>
