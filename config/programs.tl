[		NAME						PATH																MACHINE						PATH_TYPE	]

~PATH_TYPE.defaultTo(EXE) {
	~PATH.addToStart(<PROGRAM_FILES_86>\) {
		Chrome						Google\Chrome\Application\chrome.exe
		Chrome Messages				Google\Chrome\Application\chrome_proxy.exe
		Chrome TickTick				Google\Chrome\Application\chrome_proxy.exe
		EpicStudio					EpicStudio\EpicStudio.exe
		Foobar						foobar2000\foobar2000.exe
		Launchy						Launchy\Launchy.exe
		Notepad++					Notepad++\notepad++.exe												HOME_LAPTOP | WORK_VDI
		OneNote						Microsoft Office\root\Office16\ONENOTE.EXE
		Putty						PuTTY\putty.exe
		Snapper						Epic\Snapper\Snapper.exe
		Thunder						Thunder\Thunder.exe
		VB6							Microsoft Visual Studio\VB98\VB6.EXE
		Hyperdrive					Epic\Hyperdrive\VersionIndependent\Hyperspace.exe
	} ~PATH.addToStart(<PROGRAM_FILES>\) {
		AutoHotkey WinSpy			AutoHotkey\WindowSpy.ahk
		Chrome						Google\Chrome\Application\chrome.exe								WORK_DESKTOP
		Chrome Messages				Google\Chrome\Application\chrome_proxy.exe 							WORK_DESKTOP
		Chrome TickTick				Google\Chrome\Application\chrome_proxy.exe 							WORK_DESKTOP
		Everything					Everything\Everything.exe
		Internet Explorer			Internet Explorer\iexplore.exe
		KDiff						KDiff3\kdiff3.exe
		GrepWin						grepWin\grepWin.exe
		Notepad++					Notepad++\notepad++.exe
		OneNote						Microsoft Office\root\Office16\ONENOTE.EXE							WORK_DESKTOP
		Outlook						Microsoft Office\root\Office16\OUTLOOK.EXE							WORK_DESKTOP
		TrueCrypt					TrueCrypt\TrueCrypt.exe
		Visual Studio				Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.exe
		VMware Horizon Client		VMware\VMware Horizon View Client\vmware-view.exe
		VSCode						Microsoft VS Code\Code.exe
	} ~PATH.addToStart(<WINDOWS>\) {
		Explorer					explorer.exe
		Notepad						System32\notepad.exe
	}
	
	~PATH_TYPE.replaceWith(URL) {
		Messenger					https://www.messenger.com
		Slack						https://app.slack.com/client/<SLACK_MAIN_ID>
		Gmail						https://mail.google.com/mail/u/0/#inbox
		Gmail						https://mail.google.com/mail/u/1/#inbox								WORK_DESKTOP
		Teams						https://teams.microsoft.com
	}
	
		Process Explorer			<PROGRAM_FILES>\Process Explorer\procexp.exe						WORK_DESKTOP
		Process Explorer			<EPIC_PERSONAL>\Programs\Process Explorer\procexp.exe				WORK_VDI
		Process Explorer			<PROGRAM_FILES>\ProcessExplorer\procexp.exe
	
	~PATH.addToStart(<USER_APPDATA_LOCAL>\) {
		GitHub Desktop				GitHubDesktop\GitHubDesktop.exe
		GrepWin						Programs\grepWin\grepWin.exe										WORK_DESKTOP
		Slack						slack\slack.exe														HOME_DESKTOP
	}
	
	~PATH.addToStart(<USER_APPDATA>\) {
		Spotify						Spotify\Spotify.exe
		Telegram					Telegram Desktop\Telegram.exe
	}
	
		Firefox Portable			S:\FirefoxPortable\FirefoxPortable.exe								HOME_DESKTOP
		EMC2						<EMC2_CURRENT_EXE>													WORK_DESKTOP | WORK_VDI
	
	; Programs that can be launched by commands
	~PATH_TYPE.replaceWith(COMMAND) {
		Windows Terminal			wt
		Teams						ms-teams															WORK_DESKTOP
	}
}
