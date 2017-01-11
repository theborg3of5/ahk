; Launchy keyword launcher

; Protect remote desktop Launchy from host AHK interference.
#If !WinActive("ahk_class TscShellContainerClass") && !WinActive("ahk_exe vmware-view.exe")
	; Use Caps Lock as the trigger key.
	CapsLock::
		SetCapsLockState, AlwaysOff
		Send, #n
	return
#IfWinNotActive
