#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <autoInclude>

; State flags.
global suspended := 0

; Icon setup.
states                 := []
states["suspended", 0] := "controllerGreen.ico"
states["suspended", 1] := "controllerRed.ico"
setupTrayIcons(states)

loopDuration := 100 ; 100 ms
SetTimer, MainLoop, %loopDuration% ; Timer for "MainLoop" will be toggled by commonHotkeys' suspend hotkey.


MainLoop:
	if(!WinActive("ahk_class EPSX"))
		return
	
	if State := XInput_GetState(0) { ; 0 - First controller
		if(State.wButtons & XINPUT_GAMEPAD_DPAD_UP)
			sendEmulatorKey("F2") ; Switch save state
		if(State.wButtons & XINPUT_GAMEPAD_DPAD_DOWN)
			sendEmulatorKey("F4") ; Lock/unlock framerate
	}
return


#IfWinActive, ahk_class EPSX
	Joy9::
		sendEmulatorKey("F1") ; Save state
	return
	Joy10::
		sendEmulatorKey("F3") ; Load state
	return
#IfWinActive


; Emulator checks for key being down, not an actual keypress, so this is needed.
sendEmulatorKey(key) {
	SendInput, {%key% Down}
	Sleep, 50
	SendInput, {%key% Up}
	Sleep, 100
}


; Universal suspend, reload, and exit hotkeys.
#Include %A_ScriptDir%\..\..\common\commonHotkeys.ahk