; NAME = NAME from windows.tl
; X/Y/WIDTH/HEIGHT support special constant values from VisualWindow (i.e. RIGHT_EDGE for VisualWindow.X_RightEdge)

[		NAME							X					Y					WIDTH		HEIGHT	CONTEXT		MONITOR	]

~MONITOR.replaceWith(LEFT) {
		Outlook						-					-					MAX		MAX		WORK
	
		Explorer						CENTERED			CENTERED			1440		900
		GitHub Desktop				CENTERED			CENTERED			1440		900
		Teams							CENTERED			CENTERED			1440		900		WORK
		Steam							CENTERED			CENTERED			1440		900		HOME
		GrepWin						CENTERED			CENTERED			1440		900
	
# Social windows
	~WIDTH.replaceWith(950) | ~HEIGHT.replaceWith(750) | ~X.replaceWith(RIGHT_EDGE) {
		; GDB WFH
		; Messenger					-					BOTTOM_EDGE		-			-			WORK
		; Slack							-					BOTTOM_EDGE		-			-			WORK
		; Republic Anywhere			-					BOTTOM_EDGE		-			-			WORK
		; Telegram						-					BOTTOM_EDGE		-			-			WORK
		Messenger					-					TOP_EDGE
		Slack							-					TOP_EDGE
		Republic Anywhere			-					TOP_EDGE
		Telegram						-					TOP_EDGE
	}
}

~MONITOR.replaceWith(MIDDLE) {
		Chrome						-					-					MAX		MAX
		EpicStudio					-					-					MAX		MAX		WORK
		Notepad++					-					-					MAX		MAX
		VB6							-					-					MAX		MAX		WORK
		Visual Studio				-					-					MAX		MAX		WORK
		Hyperspace					CENTERED			CENTERED			1440		900		WORK
		Zoom							CENTERED			CENTERED			1440		900		HOME
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
