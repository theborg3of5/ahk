; If Spotify is running.
#If Config.doesWindowExist("Spotify")
	^!Space::
		Send, {Volume_Down}{Volume_Up} ; Makes Windows 10 media panel show up (for what's playing right now)
		HotkeyLib.waitForRelease()
	return
	
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
