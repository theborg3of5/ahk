; If Spotify is indeed running.
#If WinExist(MainConfig.getWindowTitleString("Spotify"))
	^!Space::Send, {Volume_Down}{Volume_Up} ; Makes Windows 10 media panel show up (for what's playing right now)
	
	; Global search hotkey
	#j::
		MainConfig.runProgram("Spotify")
		WinWaitActive, % MainConfig.getWindowTitleString("Spotify")
		Send, ^l
	return
#If
