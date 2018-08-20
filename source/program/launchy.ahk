; Launchy keyword launcher

; Protect remote desktop Launchy from host AHK interference.
#If WinExist(getProgramTitleString("Launchy")) && !childInstanceActive()
	; Use Caps Lock as the trigger key.
	CapsLock::
		SetCapsLockState, AlwaysOff
		Send, #n
	return

#If !WinExist(getProgramTitleString("Launchy"))
	CapsLock::
		Toast.showForTime("Launchy not yet running, launching...", 2)
		runProgram("Launchy")
	return
#If

childInstanceActive() {
	if(MainConfig.isWindowActive("Remote Desktop"))
		return true
	if(MainConfig.isWindowActive("VMware Horizon Client"))
		return true
	
	return false
}
