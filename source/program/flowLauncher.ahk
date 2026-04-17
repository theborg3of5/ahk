; Flow Launcher

; Protect remote desktop Flow Launcher from host AHK interference.
#If Config.doesWindowExist("Flow Launcher") && !Config.isWindowActive("Remote Desktop") && !Config.isWindowActive("VMware Horizon Client")
	; Use Caps Lock as the trigger key.
	CapsLock::
		SetCapsLockState, AlwaysOff
		Send, #{End}
	return

#If !Config.doesWindowExist("Flow Launcher")
	CapsLock::
		Toast.ShowMedium("Flow Launcher not yet running, launching...")
		Config.runProgram("Flow Launcher")
	return
#If
