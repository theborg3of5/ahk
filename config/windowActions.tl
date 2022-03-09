[	NAME										ESC		MIN				SELECT_ALL		DELETE_WORD		CLOSE		ACTIVATE		BACKTICK		MACHINE	]

; Values for all columns (except NAME) come from WindowActions.Method_* (for how to do the action) or WindowActions.Action_* (to do some other action, like close on escape key) constants.

	AutoHotkey								CLOSE		-					-					SELECT
	AutoHotkey WinSpy						CLOSE
	Cisco AnyConnect VPN					CLOSE
	EMC2 DLG Email							CLOSE		-					-					SELECT
	EMC2 DLG Issue Email					CLOSE		-					-					SELECT
	EMC2 DLG Resubmit						-			-					-					SELECT
	EMC2 QAN Email							CLOSE		-					HOME_END			SELECT
	EMC2 QAN Email Notify				CLOSE		-					-					SELECT
	EMC2 XDS Approval						-			-					HOME_END			SELECT
	EMC2 XDS Email							-			-					HOME_END			SELECT
	EMC2 XDS Open Design					-			-					-					SELECT
	EMC2 XDS Submit						-			-					HOME_END			SELECT
	Explorer									MIN		OTHER				-					-					-			-				ESCAPE
	Explorer									MIN		-					-					-					-			-				ESCAPE		WORK_VDI
	GitHub Desktop							CLOSE		-					-					-					-			-				ESCAPE
	Messenger								MIN		-					-					-					-			-				ESCAPE		HOME_DESKTOP
	Notepad									CLOSE
	Skype										CLOSE
	Slack										CLOSE		-					-					-					-			RUN			ESCAPE		HOME_DESKTOP
	Spotify									CLOSE		CLOSE				-					-					-			-				ESCAPE
	Teams										CLOSE		CLOSE				-					-					-			-				ESCAPE
	Telegram									CLOSE		CLOSE				-					-					-			RUN			ESCAPE
	Thunder									CLOSE
	VB6										-			POST_MESSAGE

	; EpicStudio popups - handle Ctrl+Backspace.
	EpicStudio New Object Window		-			-					-					SELECT
	EpicStudio Tokenize String			-			-					-					SELECT
	EpicStudio Bookmark Comment		-			-					-					SELECT

	; Web popups - close on Escape.
	Chrome Join								CLOSE		-					-					-					-			-				ESCAPE
	Chrome TickTick						CLOSE		-					-					-					-			-				ESCAPE
	Chrome Messages						CLOSE		-					-					-					-			-				ESCAPE

	; Windows taskbars - don't minimize.
	Windows Taskbar						-			NONE
	Windows Taskbar Secondary			-			NONE
