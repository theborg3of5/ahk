; Reminder: if you use REGEX, you'll need to escape pipes: | => \|

[				NAME								EXE							CLASS											TITLE									EDGE_TYPE		TITLE_MATCH_MODE	MACHINE			PRIORITY	]

; Defaults across the board: window edges have padding, and title match mode is contains anywhere within.
~EDGE_TYPE.defaultTo(HAS_PADDING) | ~TITLE_MATCH_MODE.defaultTo(CONTAINS) {
	
	; Specific windows within a program (overlap with their less-specific counterparts below).
	~PRIORITY.replaceWith(0) {
				AutoHotkey WinSpy					-							AutoHotkeyGUI									Window Spy
				AutoHotkey Toast					-							AutoHotkeyGUI									[TOAST]									NO_PADDING
		
		; Special Chrome windows
		~EXE.replaceWith(chrome.exe) {
				Chrome Join							-							-												Join
				Beeper								-							-												(Beeper)\|(Beeper \\| .+)				-				REGEX				WORK_DESKTOP
				TickTick							-							-												 - TickTick
				Chrome Workplans					-							-												Week of \d{1,2}\/\d{1,2}\/\d{4}			-				REGEX
				Chrome Hyperspace					-							-												– Hyperspace –
		}
		
		; EMC2 windows - we use RegEx match mode for EXE, so we can match any version (and also check the path for EMC2, to differentiate from Hyperspace).
		~EXE.replaceWith(EMC2.+EpicD.+\.exe) | ~TITLE_MATCH_MODE.replaceWith(REGEX) {
			; Different sections of the main EMC2 window.
			~CLASS.replaceWith(ThunderRT6MDIForm) {
				EMC2 QAN							-							-												QAN \d+
				EMC2 XDS							-							-												XDS \d+
				EMC2 DLG							-							-												DLG [I]?\d+
				EMC2 PRJ							-							-												PRJ \d+
			}
				EMC2 Worklist						-							-												^EMC2$
			
			; Popups
				EMC2 Email Popup					-							-												\[(I\|CS)?\d+\] .*
			
				; Basic popups that need ctrl+backspace support
				EMC2 XDS Open						-							-												Open/New Design
				EMC2 DLG/QAN/PRJ Open				-							-												Open/Create (Log\|QA Note\|Project)
			
				; Any popup (used to rope in popups that fail the generic EMC2 case below)
				EMC2 Popup							-							ThunderRT6FormDC
		}
		
				EpicStudio New Object Window		EpicStudio.exe				-												New Object
				EpicStudio Tokenize String			EpicStudio.exe				-												Tokenize String
				EpicStudio Bookmark Comment			EpicStudio.exe				-												Bookmark Comment
				EpicStudio Debug Window				EpicStudio.exe				-												Attach to Process
				Onetastic Macro Editor				ONENOTE.EXE					Onetastic Window
				PowerPoint Presenting				POWERPNT.EXE				screenClass
				PowerPoint Presenter View			POWERPNT.EXE				PodiumParent
				Snapper Add Records					Snapper.exe					-												Add a Record
				TortoiseSVN Blame Popup				TortoiseProc.exe			-												 - Blame - TortoiseSVN
				Zoom Default Meeting				Zoom.exe					ZPContentViewWndClass							Zoom									-				EXACT
	}
	
	; Most general form of various windows (specifics above should override).
	~PRIORITY.replaceWith(1) {
				AutoHotkey							-							AutoHotkeyGUI									-
				Beeper								Beeper.exe					-												-										-				-					HOME_DESKTOP
				Chrome								chrome.exe					Chrome_WidgetWin_1								- Google Chrome
				Cisco VPN							csc_ui.exe					-												Cisco Secure Client
				Discord								Discord.exe					-												-										NO_PADDING
				EMC2								EMC2.+EpicD\d+\.exe			ThunderRT6MDIForm								-										-				REGEX
				EpicStudio							EpicStudio.exe				-												EpicStudio
				Everything							Everything.exe				EVERYTHING
				Excel								EXCEL.EXE
				Explorer							explorer.exe				CabinetWClass
				Firefox Portable					firefox.exe
				Foobar								foobar2000.exe
				GitExtensions						GitExtensions.exe
				GitHub Desktop						GitHubDesktop.exe			-												-										NO_PADDING
				GrepWin								grepWin.exe
				Hyperspace							EpicD\d+\.exe				-												-										-				REGEX
				Hyperdrive							Hyperdrive.exe
				Internet Explorer					IEXPLORE.EXE
				KDiff								kdiff3.exe					-												- KDiff3
				Launchy								Launchy.exe
				MBuilder							MBuilder.exe
				Messenger							Messenger.exe				-												Messenger								NO_PADDING		EXACT
				Notepad++							notepad++.exe				Notepad++
				OneNote								ONENOTE.EXE					Framework::CFrame
				Outlook								OUTLOOK.EXE					rctrl_renwnd32
				PowerPoint							POWERPNT.EXE
				Process Explorer					PROCEXP64.exe				PROCEXPL
				Putty								putty.exe
				Remote Desktop						mstsc.exe					TscShellContainerClass
				Remote Desktop Reconnecting			mstsc.exe					#32770
				Skype								Skype.exe
				Snapper								Snapper.exe					-												Snapper
				Slack								slack.exe					-												-										NO_PADDING
				SoundSwitch							SoundSwitch.exe
				Spotify								Spotify\.exe				Chrome_WidgetWin_1								(Spotify Premium)\|( - )				NO_PADDING		REGEX
				Steam								steamwebhelper.exe			-												-										NO_PADDING
				Teams								ms-teams.exe				-												\| Microsoft Teams
				Telegram							Telegram.exe				Qt[\d]+QWindowIcon								-										-				REGEX
				Thunder								Thunder.exe					-												Thunder
				TortoiseGit							TortoiseGitProc.exe
				TortoiseSVN							TortoiseProc.exe
				TrueCrypt							TrueCrypt.exe				CustomDlg
				VMware Horizon Client				vmware-view.exe
				Visual Studio						devenv.exe
				VSCode								Code.exe
				Windows Alt Tab						explorer.exe				XamlExplorerHostIslandWindow
				Windows Taskbar						explorer.exe				Shell_TrayWnd
				Windows Taskbar Secondary			explorer.exe				Shell_SecondaryTrayWnd
				Windows Taskbar Jump Menu			ShellExperienceHost.exe		Windows.UI.Core.CoreWindow						Jump List for
				Windows Terminal					WindowsTerminal.exe
				WinMerge							WinMergeU.exe
				Word								WINWORD.EXE
				Zoom								Zoom.exe					ZPContentViewWndClass
	}
}
