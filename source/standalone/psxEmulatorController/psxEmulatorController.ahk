#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#Include <autoInclude>

; State flag and icons
global suspended := 0
setUpTrayIconsSimple("suspended", "controllerGreen.ico", "controllerRed.ico")

loopDuration := 100 ; 100 ms
SetTimer, MainLoop, %loopDuration% ; Timer for "MainLoop" will be toggled by commonHotkeys' suspend hotkey.
XInput_Init()

MainLoop:
	if(!WinActive("ahk_class EPSX"))
		return
	
	Loop, 4 {
		controllerNum := A_Index - 1 ; Controllers are 0-3
		if State := XInput_GetState(controllerNum) {
			if(State.wButtons & XINPUT_GAMEPAD_DPAD_UP)
				sendEmulatorKey("F2") ; Switch save state
			if(State.wButtons & XINPUT_GAMEPAD_DPAD_DOWN)
				sendEmulatorKey("F4") ; Lock/unlock framerate
		}
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
	; DEBUG.popup("Sending key", key)
	SendInput, {%key% Down}
	Sleep, 50
	SendInput, {%key% Up}
	Sleep, 100
}


; Universal suspend, reload, and exit hotkeys.
#Include %A_ScriptDir%\..\..\common\commonHotkeys.ahk