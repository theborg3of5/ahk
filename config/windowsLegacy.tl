(	NAME							EXE					CLASS						TITLE						TEXT					ESC		MIN		SELECT_ALL	DELETE_WORD		CLOSE		WINDOW_EDGE_OFFSET_OVERRIDE

	Cisco AnyConnect VPN		vpnui.exe			#32770					-							-						CLOSE
	Explorer						explorer.exe		CabinetWClass			-							-						MIN		OTHER
	GitHub						GitHubDesktop.exe	-							-							-						CLOSE		-			-				-					-			0
	grepWin						grepWin.exe			-							-							-						CLOSE
	KDiff							kdiff3.exe			-							-							-						CLOSE
	Mattermost					Mattermost.exe		-							-							-						CLOSE		CLOSE
	Notepad						notepad.exe			-							-							-						CLOSE		-			-				CTRL_SHIFT
	Pidgin Buddy List			pidgin.exe			-							Buddy List				-						CLOSE		CLOSE
	RemoteDesktop				-						TscShellContainerClass
	RepublicAnywhere			Republic Anywhere.exe	-					-							-						CLOSE		CLOSE
	Skype Buddy List			Skype.exe			-							-							-						CLOSE
	Spotify						Spotify.exe			-							-							-						CLOSE		CLOSE		-				-					OTHER		0
	Telegram						Telegram.exe		Qt5QWindowIcon			-							-						CLOSE		CLOSE		-				-					-			0
	Thunder						Thunder.exe			-							-							-						CLOSE
	WinSpy						AU3_Spy.exe			-							-							-						CLOSE
	
	; VB6
	VB6							VB6.exe				wndclass_desked_gsk	-							-						-			POST_MESSAGE
	VB6 Object Browser		VB6.exe				-							Object Browser			-						CLOSE
	
	; EMC2 popups
[EXE.replaceWith(EpicD84.exe)|CLASS.replaceWith(ThunderRT6FormDC)]
[ESC.replaceWith(CLOSE)|DELETE_WORD.replaceWith(CTRL_SHIFT)]
	EMC2 DLG email				-						-							E-mail Development Log
	EMC2 QAN notes				-						-							Note
	EMC2 Issue email			-						-							Email Issue
	EMC2 Issue popup			-						-							Magnify
	EMC2 QAN email notify	-						-							EMC2 - QA Note E-Mail Notification
	EMC2 QAN email				-						-							Send E-Mail				-						-			-			HOME_END
[]
	
	; EMC2 activities/workspaces
	EMC2 DLG						EpicD84.exe			ThunderRT6MDIForm		{REGEX}^DLG
	EMC2 XDS						EpicD84.exe			ThunderRT6MDIForm		{REGEX}^XDS
	
	; EpicStudio popups
	ES New Object Window		EpicStudio.exe		New Object				-							-						-			-			-				CTRL_SHIFT
	ES Tokenize String		EpicStudio.exe		Tokenize String		-							-						-			-			-				CTRL_SHIFT
	
	AHK GUIs						AutoHotkey.exe		AutoHotkeyGUI			-							-						CLOSE		-			-				CTRL_SHIFT
	
	; Web popups - close on Escape.
[ESC.replaceWith(CLOSE)|EXE.replaceWith(chrome.exe)]
	Join							-						-							Join
	TickTick						-						-							All - TickTick
[]
	
	; Windows that have odd borders and need different offsets - mainly Office programs.
[WINDOW_EDGE_OFFSET_OVERRIDE.replaceWith(0)]
	Chrome						chrome.exe
	Excel							EXCEL.EXE
	OneNote						ONENOTE.EXE
	Outlook						OUTLOOK.EXE
	PowerPoint					POWERPNT.EXE
	Steam							Steam.exe
	WebEx							atmgr.exe
	Word							WINWORD.EXE
[]
