; PowerPoint hotkeys.

#HotIf Config.isWindowActive("PowerPoint")
	; Copy the current document location
	!c:: {
		Send("!fi") ; File > Info
		Sleep(1000) ; Wait for File pane to finish appearing
		ClipboardLib.copyFilePath("c") ; Copy Path
		Send("{Esc}") ; Close the File pane
	}

; Presenting (either main screen or presenter view)
#HotIf Config.isWindowActive("PowerPoint Presenting") || Config.isWindowActive("PowerPoint Presenter View")
	; Right-click goes back
	RButton::Left
#HotIf
