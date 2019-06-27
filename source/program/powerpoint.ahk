; Powerpoint hotkeys.
#If MainConfig.isWindowActive("PowerPoint")
	MButton & RButton::Send !sc

	; Reading mode - like slideshow, but doesn't fullscreen!
	^+r::Send, !wd

	RButton::
		if(WinActive("PowerPoint Slide Show - [")) {
			Send, {Up}
		} else {
			Click, Right
		}
	return
#If


; Powerpoint Slideshow hotkeys.
#IfWinActive, ahk_class screenClass
	j::Down
	k::Up
	RButton::Send, {Up}
	MButton & RButton::Send, {Esc}
#IfWinActive
