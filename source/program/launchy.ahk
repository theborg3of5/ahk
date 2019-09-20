; Launchy keyword launcher

; Protect remote desktop Launchy from host AHK interference.
#If Config.doesWindowExist("Launchy") && !Config.isWindowActive("Remote Desktop") && !Config.isWindowActive("VMware Horizon Client")
	; Use Caps Lock as the trigger key.
	CapsLock::
		SetCapsLockState, AlwaysOff
		Send, #n
	return

#If !Config.doesWindowExist("Launchy")
	CapsLock::
		Toast.showMedium("Launchy not yet running, launching...")
		Config.runProgram("Launchy")
	return
#If
