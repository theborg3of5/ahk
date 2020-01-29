; Disconnect hotkey (for computer that's being remoted into).
$!Esc::
	if(!GuiLib.showConfirmationPopup("Are you sure you want to disconnect from this computer?", "Disconnect?"))
		return
	RunLib.runCommand("tsdiscon")
	SetNumLockState, AlwaysOn
return

#If Config.isWindowActive("Remote Desktop")
	; Allow escape from remote desktop with hotkey (for computer you're remoting from).
	!CapsLock::	; One of a few keys that the host still captures.
		Suspend, Off
		Sleep, 50 ; Need a short sleep here for focus to restore properly.
		WinMinimize, A ; need A to specify Active window
	return
#If !Config.isWindowActive("Remote Desktop") && Config.doesWindowExist("Remote Desktop")
	; Switch back into remote desktop with same hotkey (for computer you're remoting from).
	!CapsLock::
		WindowActions.activateWindowByName("Remote Desktop")
	return
#If !Config.doesWindowExist("Remote Desktop")
	; Block this hotkey if there's no remote desktop at play at all (because I'm not interested in task view).
	!CapsLock::return
#If
