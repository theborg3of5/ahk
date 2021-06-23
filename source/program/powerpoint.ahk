; PowerPoint hotkeys.

#If Config.isWindowActive("PowerPoint")
	; Copy the current document location
	!c::
		Send, !1 ; Document location (quick access position #1, should select field)
		ClipboardLib.copyFilePathWithHotkey("^c")
	return
	
; Presenting (either main screen or presenter view)
#If Config.isWindowActive("PowerPoint Presenting") || Config.isWindowActive("PowerPoint Presenter View")
	; Right-click goes back
	RButton::Left
#If
