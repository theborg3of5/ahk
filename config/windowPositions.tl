; NAME = NAME from windows.tl
; X/Y/WIDTH/HEIGHT support special constant values from VisualWindow (i.e. RIGHT_EDGE for VisualWindow.X_RightEdge)

[			NAME						X				Y				WIDTH		HEIGHT		CONTEXT		ACTIVATE	MONITOR		PRESET	]

~PRESET.defaultTo(NORMAL) | X.defaultTo(CENTERED) | Y.defaultTo(CENTERED) {
	~MONITOR.replaceWith(LEFT) {
			Outlook						-				-				MAX			MAX			WORK
			; Work Explorer is a little further left to allow Outlook calendar pane to peek thru nicely.
			Explorer					-				-				1440		900
			GitHub Desktop				-				-				1440		900
			GrepWin						-				-				1440		900
			Steam						-				-				1440		900			HOME
			Teams						-				-				1440		900			WORK
			TickTick					RIGHT_EDGE		TOP_EDGE		1200		100%
			Putty						RIGHT_EDGE		TOP_EDGE		1350		100%		WORK
			MTPutty						RIGHT_EDGE		TOP_EDGE		1440		100%		WORK
			Windows Terminal			RIGHT_EDGE		TOP_EDGE		1440		100%
		
# Social windows
		~WIDTH.defaultTo(950) | ~HEIGHT.defaultTo(750) | ~X.replaceWith(RIGHT_EDGE) | ~Y.replaceWith(TOP_EDGE) {
			Beeper						-				-				65%			100%
			Messenger
			Slack
			Telegram
		}
	}
	
	~MONITOR.replaceWith(MIDDLE) {
			Chrome						-				-				MAX			MAX
			Chrome Hyperspace			-				-				1920		1080		WORK
			Hyperspace					-				-				1920		1080		WORK
			Hyperdrive					-				-				1920		1080		WORK
			Process Explorer			-				-				1440		900
			Visual Studio				-				-				MAX			MAX			WORK
			VSCode						-				-				MAX			MAX			WORK
			Zoom						-				-				MAX			MAX			HOME
	}
	
	~MONITOR.replaceWith(RIGHT) {
			Discord						RIGHT_EDGE		-				1460		100%		HOME
			OneNote						RIGHT_EDGE		-				1460		100%		HOME
			Spotify						RIGHT_EDGE		-				1460		100%		HOME		1
		
			Cisco VPN					LEFT_EDGE+25	300				-			-			HOME
			EMC2						-				-				MAX			MAX			WORK
			EpicStudio					-				-				MAX			MAX			WORK
			Notepad++					-				-				MAX			MAX
			OneNote						-				-				MAX			MAX
			Spotify						-				-				MAX			MAX			-			1
			VMware Horizon Client		-				-				MAX			MAX			WORK
	}
	
# Gaming presets - mostly quartered social windows on the non-gaming monitor
	~WIDTH.defaultTo(50%) | ~HEIGHT.defaultTo(50%) | ~ACTIVATE.defaultTo(1) {
		~PRESET.replaceWith(GAME_ON_LEFT) | ~MONITOR.replaceWith(MIDDLE) {
			Messenger					LEFT_EDGE		BOTTOM_EDGE
			Slack						RIGHT_EDGE		BOTTOM_EDGE
			Telegram					RIGHT_EDGE		TOP_EDGE
			Beeper						LEFT_EDGE		TOP_EDGE
			Chrome						-				-				MAX			MAX
		}
		~PRESET.replaceWith(GAME_ON_MIDDLE) | ~MONITOR.replaceWith(LEFT) {
			Messenger					LEFT_EDGE		BOTTOM_EDGE
			Slack						RIGHT_EDGE		BOTTOM_EDGE
			Telegram					RIGHT_EDGE		TOP_EDGE
			Beeper						LEFT_EDGE		TOP_EDGE
			Chrome						-				-				MAX			MAX
		}
	}
}
