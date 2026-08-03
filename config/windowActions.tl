[	NAME							ESC			MIN			SELECT_ALL		DELETE_WORD		CLOSE		ACTIVATE	BACKTICK	MACHINE	]

; Values for all columns (except NAME) come from WindowActions.Method_* (for how to do the action) or WindowActions.Action_* (to do some other action, like close on escape key) constants.

	AutoHotkey						CLOSE		-			-				SELECT
	AutoHotkey WinSpy				CLOSE
	Beeper							CLOSE		-			-				-				-			-			ESCAPE
	Cisco VPN						CLOSE
	EMC2 XDS Open					-			-			-				SELECT
	EMC2 DLG/QAN/PRJ Open			-			-			-				SELECT
	Explorer						MIN			-			-				-				-			-			ESCAPE
	GitHub Desktop					CLOSE		-			-				-				-			-			ESCAPE
	Messenger						MIN			-			-				-				-			-			ESCAPE		HOME_DESKTOP
	Putty							MIN			OTHER		-				-				-			-			ESCAPE
	Skype							CLOSE
	Slack							CLOSE		-			-				-				-			RUN			ESCAPE		HOME_DESKTOP
	Spotify							CLOSE		CLOSE		-				-				-			-			ESCAPE

	; Teams main window (default "Teams" window covers meetings and such now instead)
~ESC.defaultTo(CLOSE) | ~BACKTICK.defaultTo(ESCAPE) {
	Teams Activity
	Teams Chat
	Teams Calendar
	Teams Calls
}

	Telegram						CLOSE		CLOSE		-				-				-			RUN			ESCAPE
	Thunder							CLOSE

	; Web popups - close on Escape.
	Chrome Join						CLOSE		-			-				-				-			-			ESCAPE
	TickTick						CLOSE		-			-				-				-			-			ESCAPE

	; Windows taskbars - don't minimize.
	Windows Taskbar					-			NONE
	Windows Taskbar Secondary		-			NONE
