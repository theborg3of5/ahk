; NAME = NAME from windows.tl
; X/Y/WIDTH/HEIGHT support special constant values from VisualWindow (i.e. RIGHT_EDGE for VisualWindow.X_RightEdge)

[			NAME						X				Y				WIDTH		HEIGHT		CONTEXT		ACTIVATE	MONITOR		PRESET	]

~PRESET.defaultTo(NORMAL) | X.defaultTo(CENTERED) | Y.defaultTo(CENTERED) {
	~MONITOR.replaceWith(LEFT) {
			Outlook						-				-				MAX			MAX			WORK
		~WIDTH.defaultTo(75%) | HEIGHT.defaultTo(75%) {
			Explorer
			GitHub Desktop
			GrepWin
			Steam						-				-				-			-			HOME
			Snapper
		
			; Main window for Teams (the generic Teams window covers meetings instead)
			Teams Activity				-				-				-			-			WORK
			Teams Chat					-				-				-			-			WORK
			Teams Calendar				-				-				-			-			WORK
			Teams Calls					-				-				-			-			WORK
		}
		
		~X.replaceWith(RIGHT_EDGE) | ~Y.replaceWith(TOP_EDGE) | ~WIDTH.defaultTo(70%) | ~HEIGHT.defaultTo(100%) {
			TickTick
			MTPutty						-				-				-			-			WORK
			Windows Terminal
		}
		
# Social windows
		~WIDTH.defaultTo(55%) | ~HEIGHT.defaultTo(75%) | ~X.replaceWith(RIGHT_EDGE) | ~Y.replaceWith(TOP_EDGE) {
			Beeper						-				-				65%			100%
			Messenger
			Slack
			Telegram
		}
	}
	
	~MONITOR.replaceWith(MIDDLE) {
			Chrome						-				-				MAX			MAX
			Chrome Hyperspace			-				-				2560		1440		WORK
			Hyperdrive					-				-				2560		1440		WORK
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
			Notepad++					-				-				MAX			MAX
			OneNote						-				-				MAX			MAX
			Spotify						-				-				MAX			MAX			-			1
			; This covers meeting windows, since the main window should be caught by the block above.
			Teams						-				-				MAX			MAX			WORK
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
