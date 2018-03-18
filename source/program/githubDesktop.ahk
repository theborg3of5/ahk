#IfWinActive, ahk_exe GitHubDesktop.exe
	:*:.darktheme::
		sendGitHubDesktopDarkTheme() {
			fileContents := FileRead(MainConfig.getFolder("AHK_ROOT") "\firstSetup\githubDesktopDarkTheme.txt")
			sendTextWithClipboard(fileContents)
			Send, {Enter}
		}
#IfWinActive

