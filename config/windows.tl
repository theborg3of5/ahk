@PlaceholderChar=-

(	NAME							WIN_CLASS						WIN_TITLE					CONTROL_CLASS				EXE				ESC				MIN				SELECT_ALL		DELETE_WORD		WINDOW_EDGE_OFFSET_OVERRIDE

	7-zip							FM									-								-								-					CLOSE_WINDOW	
	Skype Buddy List			tSkMainForm						-								-								-					CLOSE_WINDOW	
	KDiff							Qt5QWindowIcon					-								-								-					CLOSE_WINDOW	
	KDiff (Widget?)			QWidget							-								-								-					CLOSE_WINDOW
	Notepad						Notepad							-								-								-					CLOSE_WINDOW	-					-					CTRL_SHIFT
	WinSpy						AutoHotkeyGUI					-								-								-					CLOSE_WINDOW
	Windows Photo Viewer		Photo_Lightweight_Viewer	-								-								-					CLOSE_WINDOW	
	Thunder						-									Thunder						-								-					CLOSE_WINDOW	
	Pidgin Buddy List			-									Buddy List					-								-					CLOSE_WINDOW	CLOSE_WINDOW
	Cisco AnyConnect VPN		-									Cisco AnyConnect Secure Mobility Client	-		-					CLOSE_WINDOW	
	VB6 Object Browser		-									Object Browser				-								-					CLOSE_WINDOW	
	Foobar						{97E27FAA-C0B3-4b8e-A693-ED7881E99FC1}	-				-								-					MIN				POST_MESSAGE
	Windows Explorer			CabinetWClass					-								-								-					MIN				OTHER
	Guru Quick Dial			-									Quick Dial					-								-					MIN				HIDE_TOOL_WIN
	Guru Quick Dial Popup	WindowsForms10.Window.8.app.0.1517e87	-				-								-					OTHER
	VB								wndclass_desked_gsk			-								-								-					-					POST_MESSAGE
	Process Explorer			PROCEXPL							-								-								-					CLOSE_WINDOW	CLOSE_WINDOW
	EMC2 Email box				ThunderRT6FormDC				-								ThunderRT6TextBox1		-					-					-					HOME_END
	Hyperspace/EMC2			ThunderRT6MDIForm				-								-								-					-					-					-					CTRL_SHIFT
	Hyperspace/EMC2			ThunderRT6FormDC				-								-								-					-					-					-					CTRL_SHIFT
	Hyperspace/EMC2			ThunderMDIForm					-								-								-					-					-					-					CTRL_SHIFT
	Hyperspace/EMC2			ThunderFormDC					-								-								-					-					-					-					CTRL_SHIFT
	
	ES New Object Window		New Object						-								-								-					-					-					-					CTRL_SHIFT
	ES Tokenize String		Tokenize String				-								-								-					-					-					-					CTRL_SHIFT
	Selector GUI				-									[SLCT]						-								-					-					-					-					CTRL_SHIFT
	
	; Web popups
	Pushbullet					Chrome_WidgetWin_1			Pushbullet					-								-					CLOSE_WINDOW
	TickTick						Chrome_WidgetWin_1			All - TickTick				-								-					CLOSE_WINDOW
	
	; Windows that have odd borders and need different offsets - mainly Office programs.
[+1|{WINDOW_EDGE_OFFSET_OVERRIDE}r:0]
	Outlook						-									-								-								OUTLOOK.EXE
	Word							-									-								-								WINWORD.EXE
	Excel							-									-								-								EXCEL.EXE
	PowerPoint					-									-								-								POWERPNT.EXE
	OneNote						-									-								-								ONENOTE.EXE
[-1]
