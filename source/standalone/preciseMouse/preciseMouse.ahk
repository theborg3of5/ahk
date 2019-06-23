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

; 200 hotkeys allowed per 2 seconds (to allow long holds for moving mouse further)
#MaxHotkeysPerInterval, 200
#HotkeyInterval, 2000

global moveX := 0
global moveY := 0
global keyRunOnce := {"Left":false, "Right":false, "Up":false, "Down":false}
global keyHeld    := {"Left":false, "Right":false, "Up":false, "Down":false}
global keyCounts  := {"Left":0,     "Right":0,     "Up":0,     "Down":0}

; Don't allow the mouse to move while this is running (automatically releases on exit).
; BlockInput, MouseMove

SetTimer, MainLoop, 10 ; GDB TODO ms, timer toggled by commonHotkeys' suspend hotkey.
MainLoop:
	For keyName,_ in keyCounts {
		if(!keyHeld[keyName]) ; Only add to counts here if the key is being held down (so first just adds 1, not potentially multiple depending on the timer)
			Continue
		if(!GetKeyState(keyName, "P")) ; Check physical state - logical state is cleared by triggering hotkeys
			Continue
		
		keyCounts[keyName] += 1
	}
	
	; if(keyHeld["Right"] && GetKeyState("Right", "P"))
		; moveX += 1
	; if(keyHeld["Down"] && GetKeyState("Down", "P"))
		; moveY += 1
	
	; Store off and clear key counts to make sure we're tracking any further updates that happen while we're handling the actual move
	tempCounts := keyCounts.clone()
	For keyName,_ in keyCounts
		keyCounts[keyName] := 0
	
	; Calculate actual x/y movement
	moveX := tempCounts["Right"] - tempCounts["Left"]
	moveY := tempCounts["Down"] - tempCounts["Up"]
	
	; ; Store off and clear X/Y values so we can track any updates that happen while we're actually moving the mouse
	; tempX := moveX
	; moveX := 0
	; tempY := moveY
	; moveY := 0
	
	if(moveX != 0 || moveY != 0)
		MouseMove, moveX, moveY, 0, R ; Speed of 0 moves mouse instantly, moving relative to current position
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
	
	keyCounts[keyName] += 1
	; addMoveForKey(keyName)
	
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
