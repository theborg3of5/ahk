[				NAME										EXE							CLASS								TITLE													EDGE_TYPE		TITLE_MATCH_MODE		PRIORITY	]

; Defaults across the board: window edges have padding, and title match mode is contains anywhere within.
~EDGE_TYPE.defaultTo(HAS_PADDING) | ~TITLE_MATCH_MODE.defaultTo(CONTAINS) {
	
	; Specific windows within a program (overlap with their less-specific counterparts below).
	~PRIORITY.replaceWith(0) {
				AutoHotkey WinSpy						AutoHotkey.exe				AutoHotkeyGUI					Window Spy
				AutoHotkey Toast						AutoHotkey.exe				AutoHotkeyGUI					[TOAST]												NO_PADDING
				Chrome Join								chrome.exe					-									Join
				Chrome TickTick						chrome.exe					-									All - TickTick
		
		; EMC2 windows
		~EXE.replaceWith(EpicD97.exe) {
			; Different sections of the main EMC2 window.
			~CLASS.replaceWith(ThunderRT6MDIForm) | ~TITLE_MATCH_MODE.replaceWith(START) {
				EMC2 DLG									-								-									DLG
				EMC2 PRJ									-								-									PRJ
				EMC2 QAN									-								-									QAN
				EMC2 XDS									-								-									XDS
			}
				EMC2 DLG Change Status				-								ThunderRT6FormDC				Change Decision:
				EMC2 DLG Email							-								-									E-mail Development Log
				EMC2 DLG Issue Email					-								-									Email Issue
				EMC2 DLG/XDS Issue Popup			-								-									Issue Response
				EMC2 DLG Resubmit						-								-									Resubmit for
				EMC2 DRN Quick Review				-								-									Quick Review -
				EMC2 PRJ Readiness Notes			-								ThunderRT6FormDC				Readiness Notes
				EMC2 QAN Change Status				-								ThunderRT6FormDC				Change Note Status
				EMC2 QAN Email							-								-									Send E-Mail
				EMC2 QAN Email Notify				-								-									EMC2 - QA Note E-Mail Notification
				EMC2 QAN Notes							-								-									Note													-					EXACT
				EMC2 Worklist							-								-									EMC2													-					EXACT
				EMC2 XDS Approval						-								ThunderRT6FormDC				A Reviewer Approved
				EMC2 XDS Wait for Changes			-								ThunderRT6FormDC				A Reviewer is Waiting for Changes
				EMC2 XDS Email							-								ThunderRT6FormDC				E-Mail Design
				EMC2 XDS Open Design					-								ThunderRT6FormDC				Open/New Design
				EMC2 XDS Magnify						-								ThunderRT6FormDC				Magnify
				EMC2 XDS Submit						-								-									Submit Design for Review
		}
		
				EpicStudio New Object Window		EpicStudio.exe				-									New Object
				EpicStudio Tokenize String			EpicStudio.exe				-									Tokenize String
				EpicStudio Attach to Process		EpicStudio.exe				-									Attach to Process
				OneTastic Macro Editor XML			ONENOTE.EXE					Onetastic Window				Edit XML
				OneTastic Macro Editor				ONENOTE.EXE					Onetastic Window
				Snapper Add Records					Snapper.exe					-									Add a Record
				Zoom Default Meeting					Zoom.exe						ZPContentViewWndClass		Zoom													-					EXACT
	}
	
	; Most general form of various windows (specifics above should override).
	~PRIORITY.replaceWith(1) {
				AutoHotkey								AutoHotkey.exe				AutoHotkeyGUI					-
				Chrome									chrome.exe					Chrome_WidgetWin_1			- Google Chrome
				Cisco AnyConnect VPN					vpnui.exe					-									Cisco AnyConnect Secure Mobility Client
				Discord									Discord.exe					-									-														NO_PADDING
				EMC2										EpicD97.exe					-									EMC2
				EpicStudio								EpicStudio.exe				-									EpicStudio
				Everything								Everything.exe				EVERYTHING
				Excel										EXCEL.EXE					-									-														NO_PADDING
				Explorer									explorer.exe				CabinetWClass
				Firefox Portable						firefox.exe
				Foobar									foobar2000.exe
				GitHub Desktop							GitHubDesktop.exe			-									-														NO_PADDING
				Greenshot Capture						Greenshot.exe				-									Greenshot capture form
				Greenshot Image Editor				Greenshot.exe				-									Greenshot image editor
				GrepWin									grepWin.exe
				Hyperspace								EpicD97.exe
				Internet Explorer						IEXPLORE.EXE
				KDiff										kdiff3.exe					-									- KDiff3
				Launchy									Launchy.exe
				Messenger								Messenger.exe				-									Messenger											NO_PADDING		EXACT
				Notepad									notepad.exe
				Notepad++								notepad++.exe				Notepad++
				OneNote									ONENOTE.EXE					Framework::CFrame				-														NO_PADDING
				Outlook									OUTLOOK.EXE					rctrl_renwnd32					-														NO_PADDING
				PowerPoint								POWERPNT.EXE				-									-														NO_PADDING
				Process Explorer						PROCEXP64.exe				PROCEXPL
				Putty										putty.exe
				Remote Desktop							mstsc.exe					TscShellContainerClass
				Remote Desktop Reconnecting		mstsc.exe					#32770
				Republic Anywhere						Republic Anywhere.exe
				Skype										Skype.exe
				Snapper									Snapper.exe					-									Snapper
				Slack										slack.exe					-									-														NO_PADDING
				SoundSwitch								SoundSwitch.exe
				Spotify									Spotify.exe					-									-														NO_PADDING
				Steam										Steam.exe					-									-														NO_PADDING
				Teams										Teams.exe					-									-														NO_PADDING
				Telegram									Telegram.exe				Qt5152QWindowIcon				-														NO_PADDING
				Thunder									Thunder.exe					-									Thunder
				TortoiseGit								TortoiseGitProc.exe
				TortoiseSVN								TortoiseProc.exe
				TrueCrypt								TrueCrypt.exe				CustomDlg
				VB6										VB6.exe						wndclass_desked_gsk
				VMware Horizon Client				vmware-view.exe
				Visual Studio							devenv.exe					-									(Administrator)
				WebEx										atmgr.exe					-									-														NO_PADDING
				Windows Taskbar						explorer.exe				Shell_TrayWnd
				Windows Taskbar Secondary			explorer.exe				Shell_SecondaryTrayWnd
				Word										WINWORD.EXE					-									-														NO_PADDING
				yEd										yEd.exe
				Zoom										Zoom.exe						ZPContentViewWndClass
	}
}
