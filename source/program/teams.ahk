#If Config.isWindowActive("Teams")
	`::Send, {Esc} ; Escape closes the window, so add another hotkey to duplicate the functionality
	
	!a:: Send, ^+m ; Toggle mute
	!z:: Send, ^+o ; Toggle video
	!o:: Send, ^,  ; Settings
	^+/::Send, ^.  ; Show hotkeys
#If
