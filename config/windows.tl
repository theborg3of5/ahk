(		NAME									EXE							CLASS						TITLE												WINDOW_EDGE_OFFSET_OVERRIDE		TITLE_STRING_MATCH_MODE_OVERRIDE		PRIORITY

; Specific windows within a program (overlap with their less-specific counterparts below).
[+1|PRIORITY.replaceWith(0)]
			AutoHotkey WinSpy					AutoHotkey.exe				AutoHotkeyGUI			Window Spy
			Chrome Join							chrome.exe					-							Join
			Chrome TickTick					chrome.exe					-							All - TickTick
	[+2|EXE.replaceWith(EpicD85.exe)]
		; Different sections of the main EMC2 window.
		[+3|CLASS.replaceWith(ThunderRT6MDIForm)|TITLE_STRING_MATCH_MODE_OVERRIDE.replaceWith(CONTAINS_BEG)]
			EMC2 DLG								-								-							DLG
			EMC2 PRJ								-								-							PRJ
			EMC2 QAN								-								-							QAN
			EMC2 XDS								-								-							XDS
		[-3]
			EMC2 Design submit				-								-							Submit Design for Review
			EMC2 DLG email						-								-							E-mail Development Log
			EMC2 DLG resubmit					-								-							Resubmit for 
			EMC2 Issue email					-								-							Email Issue
			EMC2 Issue popup					-								-							Magnify
			EMC2 Open Design					-								ThunderRT6FormDC		Open/New Design
			EMC2 QAN change status			-								ThunderRT6FormDC		Change Note Status
			EMC2 QAN email						-								-							Send E-Mail
			EMC2 QAN email notify			-								-							EMC2 - QA Note E-Mail Notification
			EMC2 QAN notes						-								-							Note
			EMC2 XDS email						-								ThunderRT6FormDC		E-Mail Design
			EMC2 XDS approval					-								ThunderRT6FormDC		A Reviewer Approved
	[-2]
			EpicStudio New Object Window	EpicStudio.exe				New Object
			EpicStudio Tokenize String		EpicStudio.exe				Tokenize String
			OneTastic Macro Editor XML		ONENOTE.EXE					Onetastic Window		Edit XML
			OneTastic Macro Editor			ONENOTE.EXE					Onetastic Window
			Outlook Calendar Main			OUTLOOK.EXE					rctrl_renwnd32			Calendar - <WORK_EMAIL> - Outlook	0
			Outlook Calendar TLG				OUTLOOK.EXE					rctrl_renwnd32			TLG - <WORK_EMAIL> - Outlook			0
			Pidgin Buddy List					pidgin.exe					-							Buddy List
[-1]

; Most general form of various windows (specifics above should override).
[+1|PRIORITY.replaceWith(1)]
			AutoHotkey GUIs					AutoHotkey.exe				AutoHotkeyGUI			-												0
			Chrome								chrome.exe					Chrome_WidgetWin_1	-												
			Cisco AnyConnect VPN				vpnui.exe					#32770
			Discord								Discord.exe					-							-												0
			EMC2									EpicD85.exe					-							EMC2											-											2
			EpicStudio							EpicStudio.exe				-							EpicStudio
			Everything							Everything.exe				EVERYTHING
			Excel									EXCEL.EXE					-							-												0
			Explorer								explorer.exe				CabinetWClass
			FileZilla							filezilla.exe
			Firefox Portable					firefox.exe
			Foobar								foobar2000.exe
			GitHub								GitHubDesktop.exe			-							-												0
			Greenshot							Greenshot.exe
			Hyperspace							EpicD88.exe
			KDiff									kdiff3.exe
			Launchy								Launchy.exe
			Mattermost							Mattermost.exe
			Notepad								notepad.exe
			Notepad++							notepad++.exe				Notepad++
			OneNote								ONENOTE.EXE					Framework::CFrame		-												0
			Outlook								OUTLOOK.EXE					rctrl_renwnd32			-												0
			Pidgin								pidgin.exe
			PowerPoint							POWERPNT.EXE				-							-												0
			Process Explorer					PROCEXP64.exe				PROCEXPL
			Putty									putty.exe
			Remote Desktop						-								TscShellContainerClass
			Republic Anywhere					Republic Anywhere.exe
			Skype									Skype.exe
			Snapper								Snapper.exe
			Spotify								Spotify.exe					-							-												0
			Steam									Steam.exe					-							-												0
			Telegram								Telegram.exe				Qt5QWindowIcon			-												0
			Thunder								Thunder.exe					-							Thunder
			TrueCrypt							TrueCrypt.exe				CustomDlg
			VB6									VB6.exe						wndclass_desked_gsk
			VMware Horizon Client			vmware-view.exe
			Visual Studio						devenv.exe
			WebEx									atmgr.exe					-							-												0
			Word									WINWORD.EXE					-							-												0
			grepWin								grepWin.exe
			yEd									yEd.exe
[-1]
