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


global keyRunOnce := []
global keyHeld    := []

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
	; if(rightHeld && GetKeyState("Right", "P"))
		; moveX += 1
	; if(downHeld && GetKeyState("Down", "P"))
		; moveY += 1
	
	if(keyHeld["Right"] && GetKeyState("Right", "P"))
		moveX += 1
	if(keyHeld["Down"] && GetKeyState("Down", "P"))
		moveY += 1
	
	; if(!rightHotkey && GetKeyState("Right", "P"))
		; moveX += 1
	; if(!downHotkey && GetKeyState("Down", "P"))
		; moveY += 1
	
	; moveX += keyMoveX
	; keyMoveX := 0
	; moveY += keyMoveY
	; keyMoveY := 0
	
	; Store off and clear X/Y values so we can track any updates that happen while we're actually moving the mouse
	tempX := moveX
	moveX := 0
	tempY := moveY
	moveY := 0
	
	; DEBUG.popup("moveX",moveX, "moveY",moveY)
	if(tempX != 0 || tempY != 0) {
		; if(movingLock) {
			; Loop {
				; if(!movingLock) { ; loop
					; movingLock := "loop" counter
					; Break
				; } else {
					; x := "loop"
				; }
			; }
		; } else {
			; movingLock := "loop" counter
		; }
		
		; counter++
		
		; tempX := moveX
		; tempY := moveY
		
		MouseMove, tempX, tempY, 0, R ; Speed of 0 moves mouse instantly, moving relative to current position
		
		; if(tempX != moveX || tempY != moveY)
			; MsgBox ope
		
		; moveX := 0
		; moveY := 0
		; movingLock := false
	}
	
	
	; if(!GetKeyState("Left", "P") && !GetKeyState("Right", "P") && !GetKeyState("Up", "P") && !GetKeyState("Down", "P"))
		; keyHeld := false
return

; Up::
; Down::
; Left::
; Right::
	; return

Left::arrowPressed("Left")
Right::arrowPressed("Right")
Up::arrowPressed("Up")
Down::arrowPressed("Down")

Left Up::arrowReleased("Left")
Right Up::arrowReleased("Right")
Up Up::arrowReleased("Up")
Down Up::arrowReleased("Down")

; Right::
	; if(rightRunOnce) {
		; rightHeld := true
		; return
	; }
		
	; moveX += 1
	; rightRunOnce := true
; return
; Right Up::
	; rightRunOnce := false
	; rightHeld := false
; return

; Up::
	; moveY -= 1
; return
; Down::
	; if(downRunOnce) {
		; downHeld := true
		; return
	; }
	
	; moveY += 1
	; downRunOnce := true
; return
; Down Up::
	; downRunOnce := false
	; downHeld := false
; return
; Down::
	; if(keyRunOnce["Down"]) {
		; keyHeld["Down"] := true
		; return
	; }
	
	; moveY += 1
	; keyRunOnce["Down"] := true
; return
; Down Up::
	; keyRunOnce["Down"] := false
	; keyHeld["Down"] := false
; return

arrowPressed(keyName) {
	if(keyRunOnce[keyName]) {
		keyHeld[keyName] := true
		return
	}
	
	addMoveForKey(keyName)
	
	keyRunOnce[keyName] := true
}

addMoveForKey(keyName) {
	if(keyName = "Left")
		moveX -= 1
	else if(keyName = "Right")
		moveX += 1
	else if(keyName = "Up")
		moveY -= 1
	else if(keyName = "Down")
		moveY += 1
}

arrowReleased(keyName) {
	keyRunOnce[keyName] := false
	keyHeld[keyName]    := false
}


#Include <commonHotkeys>
