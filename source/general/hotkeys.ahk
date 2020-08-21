; General hotkeys that aren't program-specific.

; Different hotkeys based on machine
; #If Config.machineIsHomeDesktop ; GDB WFH
	; $Volume_Mute::DllCall("LockWorkStation")	; Lock computer.
#If Config.machineIsWorkLaptop
	; Suppress certain buttons on my work keyboard (for when using my work keyboard from home)
	Launch_App2:: ; Calculator key
	Browser_Home::
	Browser_Search::
	Launch_Mail::
	return
#If ; #If Config.machineIsWorkLaptop || Config.machineIsWorkVDI
	; Extra buttons on the ergonomic keyboard as left/right clicks
	Browser_Back::LButton
	Browser_Forward::RButton
; #If Config.machineIsHomeLaptop || Config.machineIsWorkLaptop || Config.machineIsWorkVDI
	AppsKey::RWin ; No right windows key on these machines, so use the AppsKey (right-click key) instead.
; #If

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
		
		; Ignore Windows taskbars entirely.
		if(Config.windowInfo["Windows Taskbar"].windowMatches(idString))
			return
		if(Config.windowInfo["Windows Taskbar Secondary"].windowMatches(idString))
			return
		
		WinActivate, % idString
		
		settings := new TempSettings().sendLevel(1) ; Allow the keystrokes to be caught and handled by other hotkeys.
		Send, %keys%
		settings.restore()
	}
#If

; Call the Windows API function "SetSuspendState" to have the system suspend or hibernate.
; Parameter #1: Pass 1 instead of 0 to hibernate rather than suspend.
; Parameter #2: Pass 1 instead of 0 to suspend immediately rather than asking each application for permission.
; Parameter #3: Pass 1 instead of 0 to disable all wake events.
~^!+#s::DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)

; Lock the computer. Good for when remote desktop'd in.
+#l::DllCall("LockWorkStation")
