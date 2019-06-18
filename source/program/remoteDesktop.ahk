; Disconnect hotkey (for computer that's being remoted into).
$!Esc::
	runCommand("tsdiscon")
	SetNumLockState, AlwaysOn
return

#If MainConfig.isWindowActive("Remote Desktop")
	; Allow escape from remote desktop with hotkey (for computer you're remoting from).
	!CapsLock::	; One of a few keys that the host still captures.
		Suspend, Off
		Sleep 50 ; Need a short sleep here for focus to restore properly.
		WinMinimize, A ; need A to specify Active window
	return
#IfWinActive

#If !MainConfig.isWindowActive("Remote Desktop") && MainConfig.doesWindowExist("Remote Desktop")
	; Switch back into remote desktop with same hotkey (for computer you're remoting from).
	!CapsLock::
		WindowActions.activateWindowByName("Remote Desktop")
	return
#If 