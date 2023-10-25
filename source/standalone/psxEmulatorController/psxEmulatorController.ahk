; Extra hotkeys when emulating a PSX with a controller.

#Include <includeCommon>
#Include XInput.ahk
ScriptTrayInfo.Init("AHK: Controller Emulator", "controllerGreen.ico", "controllerRed.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)
CommonHotkeys.setSuspendTimerLabel("CheckInputState")

SetTimer, CheckInputState, 100
XInput_Init()


CheckInputState:
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
	; Debug.popup("Sending key", key)
	SendInput, {%key% Down}
	Sleep, 50
	SendInput, {%key% Up}
	Sleep, 100
}
