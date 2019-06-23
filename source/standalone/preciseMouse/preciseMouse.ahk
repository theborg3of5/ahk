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
; BlockInput, MouseMove

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
	
	; Move continuously based on currently-down keys, but only if at least one key is being held down.
	; This is to allow a single keystroke to move the cursor only one tick in that direction.
	if(rightHeld && GetKeyState("Right", "P"))
		moveX := 1
	if(downHeld && GetKeyState("Down", "P"))
		moveY := 1
	
	; if(!rightHotkey && GetKeyState("Right", "P"))
		; moveX += 1
	; if(!downHotkey && GetKeyState("Down", "P"))
		; moveY += 1
	
	; DEBUG.popup("moveX",moveX, "moveY",moveY)
	if(moveX != 0 || moveY != 0) {
		if(movingLock) {
			Loop {
				if(!movingLock) { ; loop
					movingLock := "loop" counter
					Break
				} else {
					x := "loop"
				}
			}
		} else {
			movingLock := "loop" counter
		}
		
		counter++
		
		tempX := moveX
		tempY := moveY
		
		MouseMove, moveX, moveY, , R
		
		if(tempX != moveX || tempY != moveY)
			MsgBox ope
		
		moveX := 0
		moveY := 0
		movingLock := false
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
		if(movingLock) {
			Loop {
				if(!movingLock) { ; right
					movingLock := "right"
					Break
				} else {
					x := "right"
				}
			}
		} else {
			movingLock := "right"
		}
		
		moveX := 1
		movingLock := false
		rightRunOnce := true
	} else {
		rightHeld := true
	}
return
Right Up::
	; blockRight := false
	; rightHotkey := false
	
	rightRunOnce := false
	rightHeld := false
	; DEBUG.toast("rightrelease",rightrelease)
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
		if(movingLock) {
			Loop {
				if(!movingLock) { ; down
					movingLock := "down"
					Break
				} else {
					x := "down"
				}
			}
		} else {
			movingLock := "down"
		}
		
		moveY := 1
		movingLock := false
		downRunOnce := true
	} else {
		downHeld := true
	}
return
Down Up::
	; downHotkey := false
	downRunOnce := false
	downHeld := false
	; DEBUG.toast("downrelease",downrelease)
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
