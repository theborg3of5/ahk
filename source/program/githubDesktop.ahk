#IfWinActive, ahk_exe GitHubDesktop.exe
	:*:.darktheme::
		sendGitHubDesktopDarkTheme() {
			FileRead, fileContents, % MainConfig.getFolder("AHK_ROOT") "\firstSetup\githubDesktopDarkTheme.txt"
			sendTextWithClipboard(fileContents)
			Send, {Enter}
		}
#IfWinActive

