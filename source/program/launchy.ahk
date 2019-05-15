; Launchy keyword launcher

; Protect remote desktop Launchy from host AHK interference.
#If MainConfig.doesWindowExist("Launchy") && !MainConfig.isWindowActive("Remote Desktop") && !MainConfig.isWindowActive("VMware Horizon Client")
	; Use Caps Lock as the trigger key.
	CapsLock::
		SetCapsLockState, AlwaysOff
		Send, #n
	return

#If !MainConfig.doesWindowExist("Launchy")
	CapsLock::
		Toast.showMedium("Launchy not yet running, launching...")
		MainConfig.runProgram("Launchy")
	return
#If
