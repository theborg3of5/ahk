[		NAME							PATH																						MACHINE							PATH_TYPE	]

~PATH_TYPE.defaultTo(EXE) {
	~PATH.addToStart(<PROGRAM_FILES_86>\) {
		Chrome						Google\Chrome\Application\chrome.exe
		Chrome Messages			Google\Chrome\Application\chrome_proxy.exe
		Chrome TickTick			Google\Chrome\Application\chrome_proxy.exe
		EpicStudio					EpicStudio\EpicStudio.exe
		Foobar						foobar2000\foobar2000.exe
		Launchy						Launchy\Launchy.exe
		Notepad++					Notepad++\notepad++.exe																HOME_LAPTOP | WORK_VDI
		OneNote						Microsoft Office\root\Office16\ONENOTE.EXE
		Putty							PuTTY\putty.exe
		Snapper						Epic\Snapper\Snapper.exe
		Thunder						Thunder\Thunder.exe
		VB6							Microsoft Visual Studio\VB98\VB6.EXE
		Visual Studio				Microsoft Visual Studio\2019\Professional\Common7\IDE\devenv.exe
		VMware Horizon Client	VMware\VMware Horizon View Client\vmware-view.exe
	} ~PATH.addToStart(<PROGRAM_FILES>\) {
		AutoHotkey WinSpy			AutoHotkey\WindowSpy.ahk
		Chrome						Google\Chrome\Application\chrome.exe											WORK_LAPTOP
		Chrome Messages			Google\Chrome\Application\chrome_proxy.exe 									WORK_LAPTOP
		Chrome TickTick			Google\Chrome\Application\chrome_proxy.exe 									WORK_LAPTOP
		Everything					Everything\Everything.exe
		Internet Explorer			Internet Explorer\iexplore.exe
		KDiff							KDiff3\kdiff3.exe
		Notepad++					Notepad++\notepad++.exe
		OneNote						Microsoft Office\root\Office16\ONENOTE.EXE									WORK_LAPTOP
		Outlook						Microsoft Office\root\Office16\OUTLOOK.EXE									WORK_LAPTOP
		TrueCrypt					TrueCrypt\TrueCrypt.exe
		GrepWin						grepWin\grepWin.exe
		yEd							yWorks\yEd\yEd.exe
	} ~PATH.addToStart(<WINDOWS>\) {
		Explorer						explorer.exe
		Notepad						System32\notepad.exe
	}
	
	~PATH_TYPE.replaceWith(URL) {
		Messenger					https://www.messenger.com
		Slack							https://app.slack.com/client/<SLACK_MAIN_ID>
		Gmail							https://mail.google.com/mail/u/0/#inbox
		Gmail							https://mail.google.com/mail/u/1/#inbox										WORK_LAPTOP
	}
	
		Process Explorer			<PROGRAM_FILES>\Process Explorer\procexp.exe									WORK_LAPTOP
		Process Explorer			<EPIC_PERSONAL>\Programs\Process Explorer\procexp.exe						WORK_VDI
		Process Explorer			<PROGRAM_FILES>\ProcessExplorer\procexp.exe
	
		EMC2							<EMC2_CURRENT_EXE>																	WORK_LAPTOP | WORK_VDI
		GitHub Desktop				<USER_APPDATA_LOCAL>\GitHubDesktop\GitHubDesktop.exe
		GrepWin						<USER_APPDATA_LOCAL>\Programs\grepWin\grepWin.exe							WORK_LAPTOP
		Slack							<USER_APPDATA_LOCAL>\slack\slack.exe											HOME_DESKTOP
		Spotify						<USER_APPDATA>\Spotify\Spotify.exe
		Teams							<USER_APPDATA_LOCAL>\Microsoft\Teams\current\Teams.exe					WORK_LAPTOP
		Telegram						<USER_APPDATA>\Telegram Desktop\Telegram.exe
		Firefox Portable			S:\FirefoxPortable\FirefoxPortable.exe											HOME_DESKTOP
	
; Windows apps - PATH is the logical path, found using instructions here:
; https://answers.microsoft.com/en-us/windows/forum/windows_10-windows_store/starting-windows-10-store-app-from-the-command/836354c5-b5af-4d6c-b414-80e40ed14675)
	~PATH.addToStart(shell:appsFolder\) | ~PATH_TYPE.replaceWith(APP) {
		Messenger					FACEBOOK.317180B0BB486_8xx8rvfyw5nnt!App										HOME_DESKTOP
	}
}
