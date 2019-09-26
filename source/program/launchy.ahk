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
		new Toast("Launchy not yet running, launching...").showMedium()
		Config.runProgram("Launchy")
	return
#If
