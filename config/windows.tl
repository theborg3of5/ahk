@PlaceholderChar=-

(	NAME							EXE								CLASS								TITLE							CONTROL_CLASS				ESC				MIN				SELECT_ALL		DELETE_WORD		WINDOW_EDGE_OFFSET_OVERRIDE

	Skype Buddy List			Skype.exe						-									-								-								CLOSE_WINDOW	
	KDiff							kdiff3.exe						-									-								-								CLOSE_WINDOW
	Notepad						notepad.exe						-									-								-								CLOSE_WINDOW	-					-					CTRL_SHIFT
	WinSpy						AU3_Spy.exe						-									-								-								CLOSE_WINDOW
	Thunder						Thunder.exe						-									-								-								CLOSE_WINDOW	
	Pidgin Buddy List			pidgin.exe						-									Buddy List					-								CLOSE_WINDOW	CLOSE_WINDOW
	Cisco AnyConnect VPN		vpnui.exe						-									Cisco AnyConnect Secure Mobility Client			CLOSE_WINDOW	
	Foobar						foobar2000.exe					{97E27FAA-C0B3-4b8e-A693-ED7881E99FC1}	-				-								MIN				POST_MESSAGE
	Windows Explorer			explorer.exe					CabinetWClass					-								-								MIN				OTHER
	Process Explorer			PROCEXP64.exe					-									-								-								CLOSE_WINDOW	CLOSE_WINDOW
	
	; VB6
	VB6							VB6.exe							wndclass_desked_gsk			-								-								-					POST_MESSAGE
	VB6 Object Browser		VB6.exe							-									Object Browser				-								CLOSE_WINDOW	
	
	; EMC2/Hyperspace (main and popups) GDBTODO - update these as needed
	EMC2 Email box				GDBTODO							ThunderRT6FormDC				-								ThunderRT6TextBox1		-					-					HOME_END
	Hyperspace/EMC2			GDBTODO							ThunderRT6MDIForm				-								-								-					-					-					CTRL_SHIFT
	Hyperspace/EMC2			GDBTODO							ThunderRT6FormDC				-								-								-					-					-					CTRL_SHIFT
	Hyperspace/EMC2			GDBTODO							ThunderMDIForm					-								-								-					-					-					CTRL_SHIFT
	Hyperspace/EMC2			GDBTODO							ThunderFormDC					-								-								-					-					-					CTRL_SHIFT
	
	; EpicStudio popups
	ES New Object Window		EpicStudio.exe					New Object						-								-								-					-					-					CTRL_SHIFT
	ES Tokenize String		EpicStudio.exe					Tokenize String				-								-								-					-					-					CTRL_SHIFT
	
	Selector GUI				AutoHotkey.exe					-									[SLCT]						-								-					-					-					CTRL_SHIFT
	
	; Web popups - close on Escape.
[{ESC}r:CLOSE_WINDOW]
	Pushbullet					chrome.exe						Chrome_WidgetWin_1			Pushbullet
	TickTick						chrome.exe						Chrome_WidgetWin_1			All - TickTick
[]
	
	; Windows that have odd borders and need different offsets - mainly Office programs.
[{WINDOW_EDGE_OFFSET_OVERRIDE}r:0]
	Outlook						OUTLOOK.EXE
	Word							WINWORD.EXE
	Excel							EXCEL.EXE
	PowerPoint					POWERPNT.EXE
	; OneNote						ONENOTE.EXE
	GitHub						GitHubDesktop.exe
	Chrome						chrome.exe
	Steam							Steam.exe
	Spotify						Spotify.exe						-									-								-								CLOSE_WINDOW	CLOSE_WINDOW
[]
