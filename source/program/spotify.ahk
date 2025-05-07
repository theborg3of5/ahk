; If Spotify is running.
#If Config.doesWindowExist("Spotify")
	; Global search hotkey
	#j::
		Config.runProgram("Spotify")
		WinWaitActive, % Config.windowInfo["Spotify"].titleString
		Send, ^l
	return
#If

#If Config.isWindowActive("Spotify")
	; Alternative search hotkeys (that make more sense than the original)
	^j::
	^/::
		Send, ^l
	return
#If
