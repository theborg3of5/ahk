#Include XInput.ahk

XInput_Init()
Loop {
	if State := XInput_GetState(0) { ; 0 - First controller
		if(State.wButtons & XINPUT_GAMEPAD_DPAD_UP) {
			sendEmulatorKey("F2") ; Switch state
		}
	}
	if State := XInput_GetState(0) { ; 0 - First controller
		if(State.wButtons & XINPUT_GAMEPAD_DPAD_DOWN) {
			sendEmulatorKey("F4") ; Lock/unlock framerate
		}
	}
	
	Sleep, 100
}

#IfWinActive, ahk_class EPSX ; GDB TODO - structure this vs infinite loop better?
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

; GDB TODO - add in rest of framework so this stops on !+x, etc.