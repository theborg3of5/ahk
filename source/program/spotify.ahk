; If Spotify is running.
#HotIf Config.doesWindowExist("Spotify")
	; Global search hotkey
	#j:: {
		Config.runProgram("Spotify")
		WinWaitActive(Config.windowInfo["Spotify"].titleString)
		Send("^l")
	}
#HotIf

#HotIf Config.isWindowActive("Spotify")
	; Alternative search hotkeys (that make more sense than the original)
	^j::
	^/:: {
		Send("^l")
	}
#HotIf
