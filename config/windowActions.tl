[	NAME										ESC		MIN				SELECT_ALL		DELETE_WORD		CLOSE		ACTIVATE		BACKTICK		MACHINE	]

; Values for all columns (except NAME) come from WindowActions.Method_* (for how to do the action) or WindowActions.Action_* (to do some other action, like close on escape key) constants.

	AutoHotkey								CLOSE		-					-					CTRL_SHIFT
	AutoHotkey WinSpy						CLOSE
	Cisco AnyConnect VPN					CLOSE
	EMC2 DLG Email							CLOSE		-					-					CTRL_SHIFT
	EMC2 DLG Issue Email					CLOSE		-					-					CTRL_SHIFT
	EMC2 DLG Resubmit						-			-					-					CTRL_SHIFT
	EMC2 QAN Email							CLOSE		-					HOME_END			CTRL_SHIFT
	EMC2 QAN Email Notify				CLOSE		-					-					CTRL_SHIFT
	EMC2 XDS Approval						-			-					HOME_END			CTRL_SHIFT
	EMC2 XDS Email							-			-					HOME_END			CTRL_SHIFT
	EMC2 XDS Open Design					-			-					-					CTRL_SHIFT
	EMC2 XDS Submit						-			-					HOME_END			CTRL_SHIFT
	Explorer									MIN		OTHER
	Explorer									MIN		-					-					-					-			-				-				WORK_VDI
	GitHub Desktop							CLOSE		-					-					-					-			-				ESCAPE
	GrepWin									CLOSE
	KDiff										CLOSE
	Messenger								MIN		-					-					-					-			-				ESCAPE		HOME_DESKTOP
	Notepad									CLOSE		-					-					CTRL_SHIFT
	OneTastic Macro Editor XML			-			-					HOME_END
	Pidgin Buddy List						CLOSE		CLOSE
	Republic Anywhere						CLOSE		CLOSE
	Skype										CLOSE
	Slack										CLOSE		-					-					-					-			-				ESCAPE		HOME_DESKTOP
	Spotify									CLOSE		CLOSE				-					-					OTHER		OTHER			ESCAPE
	Teams										CLOSE		CLOSE				-					-					-			-				ESCAPE
	Telegram									CLOSE		CLOSE				-					-					-			-				ESCAPE
	Thunder									CLOSE
	VB6										-			POST_MESSAGE

	; EpicStudio popups - handle Ctrl+Backspace.
	EpicStudio New Object Window		-			-					-					CTRL_SHIFT
	EpicStudio Tokenize String			-			-					-					CTRL_SHIFT

	; Web popups - close on Escape.
	Chrome Join								CLOSE
	Chrome TickTick						CLOSE
	
	; Windows taskbars - don't minimize.
	Windows Taskbar						-			NONE
	Windows Taskbar Secondary			-			NONE
