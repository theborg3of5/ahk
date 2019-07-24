#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
trayInfo := new ScriptTrayInfo("AHK: Precise Mouse Movement", "mouseGreen.ico", "mouseRed.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone, trayInfo)

; 200 hotkeys allowed per 2 seconds (to allow long holds for moving mouse further)
#MaxHotkeysPerInterval, 200
#HotkeyInterval, 2000

; Global flags/counts per arrow key
global keyRunOnce := {"Left":false, "Right":false, "Up":false, "Down":false}
global keyHeld    := {"Left":false, "Right":false, "Up":false, "Down":false}
global keyCounts  := {"Left":0,     "Right":0,     "Up":0,     "Down":0}

SetTimer, MainLoop, 10 ; 10 ms, timer toggled by commonHotkeys' suspend hotkey.
MainLoop:
	; For keys held down, add to the counts too
	For keyName,_ in keyCounts {
		if(!keyHeld[keyName]) ; Only add to counts here if the key is being held down (so first just adds 1, not potentially multiple depending on the timer)
			Continue
		if(!GetKeyState(keyName, "P")) ; Check physical state - logical state is cleared by triggering hotkeys
			Continue
		
		addToKeyCount(keyName)
	}
	
	; Store off and clear key counts to make sure we're tracking any further updates that happen while we're handling the actual move
	tempCounts := keyCounts.clone()
	For keyName,_ in keyCounts
		keyCounts[keyName] := 0
	
	; Calculate actual x/y movement
	moveX := tempCounts["Right"] - tempCounts["Left"]
	moveY := tempCounts["Down"] - tempCounts["Up"]
	
	; Move the mouse
	if(moveX != 0 || moveY != 0)
		MouseMove, moveX, moveY, 0, R ; Speed of 0 moves mouse instantly, moving relative to current position
return

; Arrow keys (plus any modifiers) move the mouse in that direction. These can also be held down, see loop above.
*Left:: arrowPressed("Left")
*Right::arrowPressed("Right")
*Up::   arrowPressed("Up")
*Down:: arrowPressed("Down")

; Releasing the hotkeys clears some flags used to tell what's held down.
Left Up:: arrowReleased("Left")
Right Up::arrowReleased("Right")
Up Up::   arrowReleased("Up")
Down Up:: arrowReleased("Down")

; Both space and numpad 0 double as a click
Space::  LButton
NumPad0::LButton

;---------
; DESCRIPTION:    Handle an arrow key being pressed, turning on flags and adding to the key counts.
; PARAMETERS:
;  keyName (I,REQ) - Name of the key that was released, from "Left"/"Right"/"Up"/"Down".
;---------
arrowPressed(keyName) {
	; The first press doesn't count as holding down the key (for the main loop above) - that's only
	; turned on by the second trigger of this hotkey without releasing.
	if(keyRunOnce[keyName]) {
		keyHeld[keyName] := true
		return
	}
	
	addToKeyCount(keyName)
	keyRunOnce[keyName] := true
}

;---------
; DESCRIPTION:    Add to the keyCounts array for the given key. The amount added varies depending on
;                 which modifier keys are held down.
; PARAMETERS:
;  keyName (I,REQ) - Name of the key that was released, from "Left"/"Right"/"Up"/"Down".
;---------
addToKeyCount(keyName) {
	addAmount := 5 ; Basic, no modifier keys pressed
	
	; Ctrl/Shift modifiers change mouse move speed
	if(GetKeyState("LCtrl",  "P")) ; Check physical state for these keys, in case logical state was cleared by triggering hotkeys
		addAmount *= 5 ; 5x faster
	if(GetKeyState("LShift", "P"))
		addAmount /= 5 ; 5x slower
	
	keyCounts[keyName] := addAmount
}

;---------
; DESCRIPTION:    Handle an arrow key being released, by clearing flags as needed.
; PARAMETERS:
;  keyName (I,REQ) - Name of the key that was released, from "Left"/"Right"/"Up"/"Down".
;---------
arrowReleased(keyName) {
	keyRunOnce[keyName] := false
	keyHeld[keyName]    := false
}
