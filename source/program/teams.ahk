#If Config.isWindowActive("Teams")
	`::Send, {Esc} ; Escape closes the window, so add another hotkey to duplicate the functionality
	
	!a::^+m ; Toggle mute
	!v::^+o ; Toggle video
#If
