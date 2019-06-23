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
global keyRunOnce := []
global keyHeld    := []

; Don't allow the mouse to move while this is running (automatically releases on exit).
; BlockInput, MouseMove

SetTimer, MainLoop, 10 ; GDB TODO ms, timer toggled by commonHotkeys' suspend hotkey.
MainLoop:
	
	
	if(keyHeld["Right"] && GetKeyState("Right", "P"))
		moveX += 1
	if(keyHeld["Down"] && GetKeyState("Down", "P"))
		moveY += 1
	
	; Store off and clear X/Y values so we can track any updates that happen while we're actually moving the mouse
	tempX := moveX
	moveX := 0
	tempY := moveY
	moveY := 0
	
	if(tempX != 0 || tempY != 0)
		MouseMove, tempX, tempY, 0, R ; Speed of 0 moves mouse instantly, moving relative to current position
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
