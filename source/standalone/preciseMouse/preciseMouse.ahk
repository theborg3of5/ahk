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
global keyHeld := false

; Don't allow the mouse to move while this is running (automatically releases on exit).
BlockInput, MouseMove

SetTimer, MainLoop, 50 ; GDB TODO ms, timer toggled by commonHotkeys' suspend hotkey.
MainLoop:
	; moveX := 0
	; moveY := 0
	; if(GetKeyState("Left", "P"))
		; moveX -= 1
	; if(GetKeyState("Right", "P"))
		; moveX += 1
	; if(GetKeyState("Up", "P"))
		; moveY -= 1
	; if(GetKeyState("Down", "P"))
		; moveY += 1
	
	; ; Check physical key state so that we catch when it's triggered by that hotkey, and check all so that we can do multiple together.
	; if(A_ThisHotkey != "Left" && GetKeyState("Left", "P"))
		; moveX -= 1
	; if(A_ThisHotkey != "Right" && GetKeyState("Right", "P"))
		; moveX += 1
	; if(A_ThisHotkey != "Up" && GetKeyState("Up", "P"))
		; moveY -= 1
	; if(A_ThisHotkey != "Down" && GetKeyState("Down", "P"))
		; moveY += 1
	
	
	
	
	; if(!rightHotkey && GetKeyState("Right", "P"))
		; moveX += 1
	; if(!downHotkey && GetKeyState("Down", "P"))
		; moveY += 1
	
	; if(rightHotkey) {
		; count := 25
		; while(rightHotkey) {
			; Sleep, 10
			; count--
			; if(count <= 0)
				; rightHotkey := false
		; }
		; ; Sleep, 500
		; ; rightHotkey := false
	; }
	; if(downHotkey) {
		; count := 25
		; while(downHotkey) {
			; Sleep, 10
			; count--
			; if(count <= 0)
				; downHotkey := false
		; }
		; ; Sleep, 500
		; ; downHotkey := false
	; }
	
	
	if(keyHeld && GetKeyState("Right", "P"))
		moveX += 1
	if(keyHeld && GetKeyState("Down", "P"))
		moveY += 1
	
	
	; if(!rightHotkey && GetKeyState("Right", "P"))
		; moveX += 1
	; if(!downHotkey && GetKeyState("Down", "P"))
		; moveY += 1
	
	; DEBUG.popup("moveX",moveX, "moveY",moveY)
	if(moveX != 0 || moveY != 0) {
		MouseMove, moveX, moveY, , R
		moveX := 0
		moveY := 0
	}
	
	
	if(!GetKeyState("Left", "P") && !GetKeyState("Right", "P") && !GetKeyState("Up", "P") && !GetKeyState("Down", "P"))
		keyHeld := false
return

; Up::
; Down::
; Left::
; Right::
	; return

Left::
	; moveMouse(-1, 0)
	moveX -= 1
return

Right::
	; moveMouse(1, 0)
	
	; while(GetKeyState("Right", "P"))
		; moveX += 1
	
	; if(blockRight)
		; return
	; moveX += 1
	; blockRight := true
	
	; moveX += 1
	; rightHotkey := true
	; KeyWait, Right
	
	if(!rightRunOnce) {
		moveX += 1
		rightRunOnce := true
	} else {
		keyHeld := true
	}
return
Right Up::
	; blockRight := false
	; rightHotkey := false
	
	rightRunOnce := false
return

Up::
	; moveMouse(0, -1)
	moveY -= 1
return
Down::
	; moveMouse(0, 1)
	
	; moveY += 1
	; downHotkey := true
	; KeyWait, Down
	
	if(!downRunOnce) {
		moveY += 1
		downRunOnce := true
	} else {
		keyHeld := true
	}
return
Down Up::
	; downHotkey := false
	downRunOnce := false
return

; Left::
; Right::
; Up::
; Down::
	; ; updateMouse()
	; return

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
	
	; ; Check physical key state so that we catch when it's triggered by that hotkey, and check all so that we can do multiple together.
	; if(GetKeyState("Left", "P"))
		; moveX -= 1
	; if(GetKeyState("Right", "P"))
		; moveX += 1
	; if(GetKeyState("Up", "P"))
		; moveY -= 1
	; if(GetKeyState("Down", "P"))
		; moveY += 1
	
	
	; DEBUG.popup("moveX",moveX, "moveY",moveY)
}


moveMouse(x, y) {
	MouseMove, x, y, , R
}


#Include <commonHotkeys>
