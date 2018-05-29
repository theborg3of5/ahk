(	NAME					EXE						CLASS						TITLE			TEXT							PATH																					ARGS									MACHINE

[{PATH}b:C:\Program Files (x86)\]
	Chrome				chrome.exe				Chrome_WidgetWin_1	-				-								Google\Chrome\Application\chrome.exe
	EMC2					EpicD84.exe				-							EMC2			-								Epic\v8.4\EMC2\Shared Files\EpicD84.exe									EMC2Update env=TRACKAPPTCP
	EpicStudio			EpicStudio.exe			-							EpicStudio	-								EpicStudio\EpicStudio.exe
	Outlook				OUTLOOK.EXE				rctrl_renwnd32			-				-								Microsoft Office\Office16\OUTLOOK.EXE
	Thunder				Thunder.exe				-							Thunder		-								Thunder\Thunder.exe
	VB6					VB6.exe					wndclass_desked_gsk	-				-								Microsoft Visual Studio\VB98\VB6.EXE
	VisualStudio		devenv.exe				-							-				-								Microsoft Visual Studio\2017\Professional\Common7\IDE\devenv.exe
	Pidgin				pidgin.exe				-							-				-								Pidgin\pidgin.exe
	Snapper				Snapper.exe				-							-				-								Epic\Snapper\Snapper.exe
	VMWareView			vmware-view.exe		-							-				-								VMware\VMware Horizon View Client\vmware-view.exe
	OneNote				ONENOTE.EXE				Framework::CFrame		-				-								Microsoft Office\Office16\ONENOTE.EXE										-										EPIC_LAPTOP
	OneNote				ONENOTE.EXE				Framework::CFrame		-				-								Microsoft Office\root\Office16\ONENOTE.EXE
	Putty					putty.exe				-							-				-								PuTTY\putty.exe
	Hyperspace			EpicD85.exe				-							-				-								Epic\v8.5\Shared Files\EpicD85.exe
	Launchy				Launchy.exe				-							-				-								Launchy\Launchy.exe
[]

[{PATH}b:C:\Program Files\]
	Everything			Everything.exe			EVERYTHING				-				-								Everything\Everything.exe
	Notepad++			notepad++.exe			Notepad++				-				-								Notepad++\notepad++.exe
	TrueCrypt			TrueCrypt.exe			CustomDlg				-				-								TrueCrypt\TrueCrypt.exe
	WinSpy				AutoHotkey.exe			AutoHotkeyGUI			-				-								AutoHotkey\WindowSpy.ahk
	yEd					yEd.exe					-							-				-								yWorks\yEd\yEd.exe
	ProcessExplorer	PROCEXP64.exe			PROCEXPL					-				-								Process Explorer\procexp.exe													-										EPIC_LAPTOP
	ProcessExplorer	PROCEXP64.exe			PROCEXPL					-				-								ProcessExplorer\procexp.exe
	grepWin				grepWin.exe				-							-				-								grepWin\grepWin.exe
	FileZilla			filezilla.exe			-							-				-								FileZilla FTP Client\filezilla.exe											--site="0/CowBox"
[]

[{PATH}b:C:\Windows\]
	Explorer				explorer.exe			CabinetWClass			-				-								explorer.exe
	Notepad				notepad.exe				-							-				-								System32\notepad.exe
[]

[{PATH}e:AppData\Local\GitHubDesktop\GitHubDesktop.exe]
	GitHub				GitHubDesktop.exe		-							-				-								C:\Users\thebo\
	GitHub				GitHubDesktop.exe		-							-				-								C:\Users\gborg\																	-										EPIC_LAPTOP
[]

[+1|{PATH}e:AppData\Roaming\]
	[+2|{PATH}e:Telegram Desktop\Telegram.exe]
	Telegram				Telegram.exe			Qt5QWindowIcon			-				-								C:\Users\thebo\
	Telegram				Telegram.exe			Qt5QWindowIcon			-				-								C:\Users\gborg\																	-										EPIC_LAPTOP
	[-2]
	[+2|{PATH}e:Spotify\Spotify.exe]
	Spotify				Spotify.exe				-							-				Chrome Legacy Window		C:\Users\thebo\
	Spotify				Spotify.exe				-							-				Chrome Legacy Window		C:\Users\gborg\																	-										EPIC_LAPTOP
	[-2]
[-1]

[+1|{PATH}e:AppData\Local\]
	[+2|{PATH}e:republicanywhere\app-1.5.8\Republic Anywhere.exe]
	RepublicAnywhere	Republic Anywhere.exe	-						-				-								C:\Users\thebo\
	RepublicAnywhere	Republic Anywhere.exe	-						-				-								C:\Users\gborg\																	-										EPIC_LAPTOP
	[-2]
[-1]
	
	FirefoxPortable	firefox.exe				-							-				-								S:\FirefoxPortable\FirefoxPortable.exe										-										HOME_DESKTOP
	