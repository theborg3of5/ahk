; NAME = NAME from windows.tl
; X/Y/WIDTH/HEIGHT support special constant values from VisualWindow (i.e. RIGHT_EDGE for VisualWindow.X_RightEdge)

[			NAME							X					Y					WIDTH		HEIGHT	CONTEXT		ACTIVATE		MONITOR		PRESET	]

~PRESET.defaultTo(NORMAL) {
	~MONITOR.replaceWith(LEFT) {
			Outlook						-					-					MAX		MAX		WORK
		
			Explorer						CENTERED			CENTERED			1440		900
			GitHub Desktop				CENTERED			CENTERED			1440		900
			GrepWin						CENTERED			CENTERED			1440		900
			Steam							CENTERED			CENTERED			1440		900		HOME
			Teams							CENTERED			CENTERED			1440		900		WORK
		
# Social windows
		~WIDTH.replaceWith(950) | ~HEIGHT.replaceWith(750) | ~X.replaceWith(RIGHT_EDGE) | ~Y.replaceWith(TOP_EDGE) {
			Slack
			Republic Anywhere
			Messenger
			Telegram
		}
	}
	
	~MONITOR.replaceWith(MIDDLE) {
			Chrome						-					-					MAX		MAX
			EpicStudio					-					-					MAX		MAX		WORK
			Hyperspace					CENTERED			CENTERED			1920		1080		WORK
			Notepad++					-					-					MAX		MAX
			Process Explorer			CENTERED			CENTERED			1440		900
			VB6							-					-					MAX		MAX		WORK
			Visual Studio				-					-					MAX		MAX		WORK
			WebEx							CENTERED			CENTERED			1920		1080		WORK
			Zoom							-					-					MAX		MAX		HOME
	}
	
	~MONITOR.replaceWith(RIGHT) {
			Cisco AnyConnect VPN		LEFT_EDGE+25	300				-			-			HOME
			VMware Horizon Client	CENTERED			CENTERED			FULL		FULL		WORK
			EMC2							-					-					MAX		MAX		WORK
		
			Discord						RIGHT_EDGE		CENTERED			1460		FULL		HOME
			OneNote						RIGHT_EDGE		CENTERED			1460		FULL		HOME
			Spotify						RIGHT_EDGE		CENTERED			1460		FULL		HOME
			OneNote						-					-					MAX		MAX
			Spotify						-					-					MAX		MAX
	}
	
	
# Gaming presets - mostly quartered social windows on the non-gaming monitor
	~WIDTH.defaultTo(HALF) | ~HEIGHT.defaultTo(HALF) | ~ACTIVATE.defaultTo(1) {
		~PRESET.replaceWith(GAME_ON_LEFT) | ~MONITOR.replaceWith(MIDDLE) {
			Messenger					LEFT_EDGE		BOTTOM_EDGE
			Slack							RIGHT_EDGE		BOTTOM_EDGE
			Telegram						RIGHT_EDGE		TOP_EDGE
		}
		~PRESET.replaceWith(GAME_ON_MIDDLE) | ~MONITOR.replaceWith(LEFT) {
			Messenger					LEFT_EDGE		BOTTOM_EDGE
			Slack							RIGHT_EDGE		BOTTOM_EDGE
			Telegram						RIGHT_EDGE		TOP_EDGE
			Chrome						-					-					MAX		MAX
		}
	}
}
