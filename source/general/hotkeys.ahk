; General hotkeys that aren't program-specific.

; Different hotkeys based on machine
#If Config.machineIsHomeDesktop
	$Volume_Mute::DllCall("LockWorkStation")	; Lock computer.
#If Config.machineIsHomeLaptop || Config.machineIsWorkLaptop || Config.machineIsWorkVDI
	AppsKey::RWin ; No right windows key on these machines, so use the AppsKey (right-click key) instead.
#If Config.machineIsWorkLaptop || Config.machineIsWorkVDI
	Browser_Back::LButton
	Browser_Forward::RButton
#If

; Scroll horizontally with Shift held down.
#If !(Config.isWindowActive("EpicStudio") || Config.isWindowActive("Chrome")) ; Chrome and EpicStudio handle their own horizontal scrolling, and doesn't support WheelLeft/Right all the time.
	+WheelUp::WheelLeft
	+WheelDown::WheelRight
#If

; Release all modifier keys, for cases when some might be "stuck" down.
*#Space::HotkeyLib.releaseAllModifiers()

; Launchy normally uses CapsLock, but (very) occasionally, we need to use it for its intended purpose.
^!CapsLock::SetCapsLockState, On

; Use the extra mouse buttons to switch tabs in various programs
#If !Config.windowIsGame() && !Config.isWindowActive("Remote Desktop") && !Config.isWindowActive("VMware Horizon Client")
	XButton1::activateWindowUnderMouseAndSendKeys("^{Tab}")
	XButton2::activateWindowUnderMouseAndSendKeys("^+{Tab}")
	activateWindowUnderMouseAndSendKeys(keys) {
		idString := WindowLib.getIdTitleStringUnderMouse()
		windowName := Config.findWindowName(idString)
		if(windowName != "Windows Taskbar" && windowName != "Windows Taskbar Secondary") ; Don't try to focus Windows taskbar
			WinActivate, % idString
		
		startSendLevel := setSendLevel(1) ; Allow the keystrokes to be caught and handled by other hotkeys.
		Send, %keys%
		setSendLevel(startSendLevel)
	}
#If

; Call the Windows API function "SetSuspendState" to have the system suspend or hibernate.
; Parameter #1: Pass 1 instead of 0 to hibernate rather than suspend.
; Parameter #2: Pass 1 instead of 0 to suspend immediately rather than asking each application for permission.
; Parameter #3: Pass 1 instead of 0 to disable all wake events.
^!+#s::DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)

; Lock the computer. Good for when remote desktop'd in.
+#l::DllCall("LockWorkStation")
