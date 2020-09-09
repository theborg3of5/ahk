; NAME = NAME from windows.tl
; X/Y/WIDTH/HEIGHT support special constant values from VisualWindow (i.e. RIGHT_EDGE for VisualWindow.X_RightEdge)

[	NAME										X					Y					WIDTH				HEIGHT			CONTEXT		MONITOR	]
	
~MONITOR.replaceWith(LEFT) {
		Outlook								-					-					MAX				MAX				WORK
		
		Explorer								CENTERED			CENTERED			1440				900
		GitHub Desktop						CENTERED			CENTERED			1440				900
		Teams									CENTERED			CENTERED			1440				900				WORK
	
	# Social windows
	~WIDTH.replaceWith(950) | ~HEIGHT.replaceWith(750) | ~X.replaceWith(RIGHT_EDGE) {
		Messenger							-					TOP_EDGE			-					-					HOME
		Slack									-					TOP_EDGE			-					-					HOME
		Republic Anywhere					-					TOP_EDGE			-					-					HOME
		Telegram								-					TOP_EDGE			-					-					HOME
		Messenger							-					BOTTOM_EDGE
		Slack									-					BOTTOM_EDGE
		Republic Anywhere					-					BOTTOM_EDGE
		Telegram								-					BOTTOM_EDGE
	}
}

~MONITOR.replaceWith(MIDDLE) {
		Chrome								-					-					MAX				MAX
		EpicStudio							-					-					MAX				MAX				WORK
		Notepad++							-					-					MAX				MAX
		Hyperspace							CENTERED			CENTERED			1440				900				WORK
}

~MONITOR.replaceWith(RIGHT) {
		Cisco AnyConnect VPN				LEFT_EDGE+25	300				-					-					HOME
		VMware Horizon Client			CENTERED			CENTERED			FULL				FULL				WORK
		EMC2									-					-					MAX				MAX				WORK
		
		Spotify								RIGHT_EDGE		CENTERED			1460				FULL				HOME
		OneNote								RIGHT_EDGE		CENTERED			1460				FULL				HOME
		Spotify								-					-					MAX				MAX
		OneNote								-					-					MAX				MAX
}
