(			NAME									EXE							CLASS						TITLE												EDGE_TYPE		TITLE_STRING_MATCH_MODE_OVERRIDE		PRIORITY

; Specific windows within a program (overlap with their less-specific counterparts below).
[+1|PRIORITY.replaceWith(0)]
			AutoHotkey WinSpy					AutoHotkey.exe				AutoHotkeyGUI			Window Spy
			AutoHotkey Toast					AutoHotkey.exe				AutoHotkeyGUI			[TOAST]											NO_PADDING
			Chrome Join							chrome.exe					-							Join
			Chrome TickTick					chrome.exe					-							All - TickTick
	[+2|EXE.replaceWith(EpicD87.exe)]
		; Different sections of the main EMC2 window.
		[+3|CLASS.replaceWith(ThunderRT6MDIForm)|TITLE_STRING_MATCH_MODE_OVERRIDE.replaceWith(START)]
			EMC2 DLG								-								-							DLG
			EMC2 PRJ								-								-							PRJ
			EMC2 QAN								-								-							QAN
			EMC2 XDS								-								-							XDS
		[-3]
			EMC2 DLG Email						-								-							E-mail Development Log
			EMC2 DLG Issue Email				-								-							Email Issue
			EMC2 DLG/XDS Issue Popup		-								-							Magnify
			EMC2 DLG Resubmit					-								-							Resubmit for 
			EMC2 DRN Quick Review			-								-							Quick Review - 
			EMC2 QAN Change Status			-								ThunderRT6FormDC		Change Note Status
			EMC2 QAN Email						-								-							Send E-Mail
			EMC2 QAN Email Notify			-								-							EMC2 - QA Note E-Mail Notification
			EMC2 QAN Notes						-								-							Note												-					EXACT
			EMC2 XDS Approval					-								ThunderRT6FormDC		A Reviewer Approved
			EMC2 XDS Email						-								ThunderRT6FormDC		E-Mail Design
			EMC2 XDS Open Design				-								ThunderRT6FormDC		Open/New Design
			EMC2 XDS Submit					-								-							Submit Design for Review
	[-2]
			EpicStudio New Object Window	EpicStudio.exe				New Object
			EpicStudio Tokenize String		EpicStudio.exe				Tokenize String
			OneTastic Macro Editor XML		ONENOTE.EXE					Onetastic Window		Edit XML
			OneTastic Macro Editor			ONENOTE.EXE					Onetastic Window
			Outlook Calendar Main			OUTLOOK.EXE					rctrl_renwnd32			Calendar - <WORK_EMAIL> - Outlook		NO_PADDING
			Outlook Calendar TLG				OUTLOOK.EXE					rctrl_renwnd32			TLG - <WORK_EMAIL> - Outlook				NO_PADDING
			Pidgin Buddy List					pidgin.exe					-							Buddy List
[-1]

; Most general form of various windows (specifics above should override).
[PRIORITY.replaceWith(1)]
			AutoHotkey							AutoHotkey.exe				AutoHotkeyGUI			-													
			Chrome								chrome.exe					Chrome_WidgetWin_1	-
			Cisco AnyConnect VPN				vpnui.exe					#32770					Cisco AnyConnect Secure Mobility Client
			Discord								Discord.exe					-							-													NO_PADDING
			EMC2									EpicD87.exe					-							EMC2												-					START
			EpicStudio							EpicStudio.exe				-							EpicStudio
			Everything							Everything.exe				EVERYTHING
			Excel									EXCEL.EXE					-							-													NO_PADDING
			Explorer								explorer.exe				CabinetWClass
			Firefox Portable					firefox.exe
			Foobar								foobar2000.exe
			GitHub								GitHubDesktop.exe			-							-													NO_PADDING
			Greenshot Capture					Greenshot.exe				-							Greenshot capture form
			Greenshot Image Editor			Greenshot.exe				-							Greenshot image editor
			GrepWin								grepWin.exe
			Hyperspace							EpicD91.exe
			Internet Explorer					IEXPLORE.EXE
			KDiff									kdiff3.exe
			Launchy								Launchy.exe
			Mattermost							Mattermost.exe
			Notepad								notepad.exe
			Notepad++							notepad++.exe				Notepad++
			OneNote								ONENOTE.EXE					Framework::CFrame		-													NO_PADDING
			Outlook								OUTLOOK.EXE					rctrl_renwnd32			-													NO_PADDING
			PowerPoint							POWERPNT.EXE				-							-													NO_PADDING
			Process Explorer					PROCEXP64.exe				PROCEXPL
			Putty									putty.exe
			Remote Desktop						-								TscShellContainerClass
			Republic Anywhere					Republic Anywhere.exe
			Skype									Skype.exe
			Snapper								Snapper.exe
			Spotify								Spotify.exe					-							-													NO_PADDING
			Steam									Steam.exe					-							-													NO_PADDING
			Teams									Teams.exe					-							-													NO_PADDING
			Telegram								Telegram.exe				Qt5QWindowIcon			-													NO_PADDING
			Thunder								Thunder.exe					-							Thunder
			TrueCrypt							TrueCrypt.exe				CustomDlg
			VB6									VB6.exe						wndclass_desked_gsk
			VMware Horizon Client			vmware-view.exe
			Visual Studio						devenv.exe					-							(Administrator)
			WebEx									atmgr.exe					-							-													NO_PADDING
			Windows Taskbar					explorer.exe				Shell_TrayWnd
			Windows Taskbar Secondary		explorer.exe				Shell_SecondaryTrayWnd
			Word									WINWORD.EXE					-							-													NO_PADDING
			yEd									yEd.exe
[]
