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

class Spotify {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Spotify has a whole bunch of windows that are difficult to tell apart from the
	;                 real thing. This finds and returns the window ID of the "main" one.
	; RETURNS:        ID/handle of Spotify's main window
	;---------
	getMainWindowId() {
		exe := Config.windowInfo["Spotify"].exe
		titleString     := WindowLib.buildTitleString(exe, "", "Spotify") ; If not playing, title is just "Spotify"
		titleStringPlay := WindowLib.buildTitleString(exe, "", "-")       ; If playing, title includes a hyphen (between the title and artist)
		
		settings := new TempSettings().titleMatchMode(TitleMatchMode.Contains)
		winId := WinExist(titleString)
		if(!winId)
			winId := WinExist(titleStringPlay)
		settings.restore()
		
		return winId
	}
	; #END#
}
