#If Config.isWindowActive("Teams")
	!a:: Send, ^+m ; Toggle mute
	!z:: Send, ^+o ; Toggle video
	!o:: Send, ^,  ; Settings
	^+/::Send, ^.  ; Show hotkeys
	:*:xD:::laugh: ; Change my laughing emoji
	
	^+c:: ; Code formatting
		teamsCodeFormatText() { ; Markdown-style, just wrap it in backticks.
			text := SelectLib.getText()
			SendRaw, ``%text%``
		}
#If