@PlaceholderChar=-

(	NAME							EXE					CLASS						TITLE					TEXT	ESC		MIN		SELECT_ALL	DELETE_WORD		CLOSE		WINDOW_EDGE_OFFSET_OVERRIDE

	Skype Buddy List			Skype.exe			-							-						-		CLOSE
	KDiff							kdiff3.exe			-							-						-		CLOSE
	Notepad						notepad.exe			-							-						-		CLOSE		-			-				CTRL_SHIFT
	WinSpy						AU3_Spy.exe			-							-						-		CLOSE
	Thunder						Thunder.exe			-							-						-		CLOSE
	Pidgin Buddy List			pidgin.exe			-							Buddy List			-		CLOSE		CLOSE
	Cisco AnyConnect VPN		vpnui.exe			#32770					-						-		CLOSE
	Explorer						explorer.exe		CabinetWClass			-						-		MIN		OTHER
	Process Explorer			PROCEXP64.exe		-							-						-		CLOSE		CLOSE
	
	; VB6
	VB6							VB6.exe				wndclass_desked_gsk	-						-		-			POST_MESSAGE
	VB6 Object Browser		VB6.exe				-							Object Browser		-		CLOSE
	
	; EMC2 popups
	EMC2 Email box				EpicD82.exe			ThunderRT6FormDC		-						-		CLOSE		-			HOME_END		CTRL_SHIFT
	
	; EpicStudio popups
	ES New Object Window		EpicStudio.exe		New Object				-						-		-			-			-				CTRL_SHIFT
	ES Tokenize String		EpicStudio.exe		Tokenize String		-						-		-			-			-				CTRL_SHIFT
	
	AHK GUIs						AutoHotkey.exe		AutoHotkeyGUI			-						-		-			-			-				CTRL_SHIFT
	
	; Web popups - close on Escape.
[{ESC}r:CLOSE]
	Pushbullet					chrome.exe			-							Pushbullet
	TickTick						chrome.exe			-							All - TickTick
	Join							chrome.exe			-							Join
[]
	
	; Windows that have odd borders and need different offsets - mainly Office programs.
[{WINDOW_EDGE_OFFSET_OVERRIDE}r:0]
	Outlook						OUTLOOK.EXE
	Word							WINWORD.EXE
	Excel							EXCEL.EXE
	PowerPoint					POWERPNT.EXE
	OneNote						ONENOTE.EXE
	GitHub						GitHubDesktop.exe
	Chrome						chrome.exe
	Steam							Steam.exe
	Spotify						Spotify.exe			-							-						-		CLOSE		CLOSE		-				-					OTHER
[]
