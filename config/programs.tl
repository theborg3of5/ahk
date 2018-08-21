(		NAME							PATH																					ARGS									MACHINE

[PATH.addToStart(C:\Program Files (x86)\)]
		Chrome						Google\Chrome\Application\chrome.exe
		EMC2							Epic\v8.4\EMC2\Shared Files\EpicD84.exe									EMC2Update env=TRACKAPPTCP
		EpicStudio					EpicStudio\EpicStudio.exe
		Hyperspace					Epic\v8.5\Shared Files\EpicD85.exe
		Launchy						Launchy\Launchy.exe
		OneNote						Microsoft Office\Office16\ONENOTE.EXE										-										EPIC_LAPTOP
		OneNote						Microsoft Office\root\Office16\ONENOTE.EXE
		Outlook						Microsoft Office\Office16\OUTLOOK.EXE
		Pidgin						Pidgin\pidgin.exe
		Putty							PuTTY\putty.exe
		Snapper						Epic\Snapper\Snapper.exe
		Thunder						Thunder\Thunder.exe
		VB6							Microsoft Visual Studio\VB98\VB6.EXE
		Visual Studio				Microsoft Visual Studio\2017\Professional\Common7\IDE\devenv.exe
		VMware Horizon Client	VMware\VMware Horizon View Client\vmware-view.exe
[]

[PATH.addToStart(C:\Program Files\)]
		Everything					Everything\Everything.exe
		FileZilla					FileZilla FTP Client\filezilla.exe											--site="0/CowBox"
		grepWin						grepWin\grepWin.exe
		Notepad++					Notepad++\notepad++.exe
		Process Explorer			Process Explorer\procexp.exe													-										EPIC_LAPTOP
		Process Explorer			ProcessExplorer\procexp.exe
		TrueCrypt					TrueCrypt\TrueCrypt.exe
		AutoHotkey WinSpy			AutoHotkey\WindowSpy.ahk
		yEd							yWorks\yEd\yEd.exe
[]

[PATH.addToStart(C:\Windows\)]
		Explorer						explorer.exe
		Notepad						System32\notepad.exe
[]

[+1|PATH.addToEnd(AppData\Local\)]
	[+2|PATH.addToEnd(GitHubDesktop\GitHubDesktop.exe)]
		GitHub						C:\Users\thebo\
		GitHub						C:\Users\gborg\																	-										EPIC_LAPTOP
	[-2]
[-1]

[+1|PATH.addToEnd(AppData\Roaming\)]
	[+2|PATH.addToEnd(Telegram Desktop\Telegram.exe)]
		Telegram						C:\Users\thebo\
		Telegram						C:\Users\gborg\																	-										EPIC_LAPTOP
	[-2]
	[+2|PATH.addToEnd(Spotify\Spotify.exe)]
		Spotify						C:\Users\thebo\
		Spotify						C:\Users\gborg\																	-										EPIC_LAPTOP
	[-2]
[-1]
		
		Firefox Portable			S:\FirefoxPortable\FirefoxPortable.exe										-										HOME_DESKTOP
	