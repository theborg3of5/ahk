; Launchy keyword launcher

; Protect remote desktop Launchy from host AHK interference.
#IfWinNotActive, ahk_class TscShellContainerClass
	; Use Caps Lock as the trigger key.
	CapsLock::
		SetCapsLockState, AlwaysOff
		Send, #n
	return
#IfWinNotActive
