; Windows terminal hotkeys.
#If Config.isWindowActive("Windows Terminal")
	; On clearing screen, hit enter an extra time so we get the full prompt.
	~^+l::Send, {Enter}
#If
