; NAME = NAME from windows.tl
; X/Y/WIDTH/HEIGHT support special constant values from VisualWindow (i.e. RIGHT_EDGE for VisualWindow.X_RightEdge)

[			NAME						X				Y				WIDTH		HEIGHT		CONTEXT		ACTIVATE	MONITOR		PRESET	]

~PRESET.defaultTo(NORMAL) {
	~MONITOR.replaceWith(LEFT) {
			Outlook						-				-				MAX			MAX			WORK
			; Work Explorer is a little further left to allow Outlook calendar pane to peek thru nicely.
			Explorer					CENTERED		CENTERED		1440		900
			GitHub Desktop				CENTERED		CENTERED		1440		900
			GrepWin						CENTERED		CENTERED		1440		900
			Steam						CENTERED		CENTERED		1440		900			HOME
			Teams						CENTERED		CENTERED		1440		900			WORK
			Chrome TickTick				RIGHT_EDGE		TOP_EDGE		1200		750
			Putty						RIGHT_EDGE		TOP_EDGE		50%			100%		WORK
			Windows Terminal			RIGHT_EDGE		TOP_EDGE		1440		100%
		
# Social windows
		~WIDTH.replaceWith(950) | ~HEIGHT.replaceWith(750) | ~X.replaceWith(RIGHT_EDGE) | ~Y.replaceWith(TOP_EDGE) {
			Chrome Messages
			Messenger
			Slack
			Telegram
		}
	}
	
	~MONITOR.replaceWith(MIDDLE) {
			Chrome						-				-				MAX			MAX
			EpicStudio					-				-				MAX			MAX			WORK
			Hyperspace					CENTERED		CENTERED		1920		1080		WORK
			Hyperdrive					CENTERED		CENTERED		1920		1080		WORK
			Notepad++					-				-				MAX			MAX
			Process Explorer			CENTERED		CENTERED		1440		900
			VB6							-				-				MAX			MAX			WORK
			Visual Studio				-				-				MAX			MAX			WORK
			VSCode						-				-				MAX			MAX			WORK
			Zoom						-				-				MAX			MAX			HOME
	}
	
	~MONITOR.replaceWith(RIGHT) {
			Discord						RIGHT_EDGE		CENTERED		1460		100%		HOME
			OneNote						RIGHT_EDGE		CENTERED		1460		100%		HOME
			Spotify						RIGHT_EDGE		CENTERED		1460		100%		HOME		1
		
			Cisco AnyConnect VPN		LEFT_EDGE+25	300				-			-			HOME
			EMC2						-				-				MAX			MAX			WORK
			OneNote						-				-				MAX			MAX
			Spotify						-				-				MAX			MAX			-			1
			VMware Horizon Client		-				-				MAX			MAX			WORK
			WebEx						CENTERED		CENTERED		1440		900			WORK
	}
	
# Gaming presets - mostly quartered social windows on the non-gaming monitor
	~WIDTH.defaultTo(50%) | ~HEIGHT.defaultTo(50%) | ~ACTIVATE.defaultTo(1) {
		~PRESET.replaceWith(GAME_ON_LEFT) | ~MONITOR.replaceWith(MIDDLE) {
			Messenger					LEFT_EDGE		BOTTOM_EDGE
			Slack						RIGHT_EDGE		BOTTOM_EDGE
			Telegram					RIGHT_EDGE		TOP_EDGE
			Chrome Messages				LEFT_EDGE		TOP_EDGE
			Chrome						-				-				MAX			MAX
		}
		~PRESET.replaceWith(GAME_ON_MIDDLE) | ~MONITOR.replaceWith(LEFT) {
			Messenger					LEFT_EDGE		BOTTOM_EDGE
			Slack						RIGHT_EDGE		BOTTOM_EDGE
			Telegram					RIGHT_EDGE		TOP_EDGE
			Chrome Messages				LEFT_EDGE		TOP_EDGE
			Chrome						-				-				MAX			MAX
		}
	}
}
