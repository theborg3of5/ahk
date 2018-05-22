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
		runProgram("Launchy")
	return
#If

childInstanceActive() {
	if(WinActive("ahk_class TscShellContainerClass"))
		return true
	if(WinActive("ahk_exe vmware-view.exe"))
		return true
	
	return false
}
