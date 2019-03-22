; If Spotify is indeed running.
#If MainConfig.doesWindowExist("Spotify")
	^!Space::Send, {Volume_Down}{Volume_Up} ; Makes Windows 10 media panel show up (for what's playing right now)
	
	; Global search hotkey
	#j::
		MainConfig.runProgram("Spotify")
		WinWaitActive, % MainConfig.windowInfo["Spotify"].titleString
		Send, ^l
	return
#If
