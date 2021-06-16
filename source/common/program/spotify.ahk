class Spotify {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Spotify has a whole bunch of windows that are difficult to tell apart from the
	;                 real thing. This finds and returns the window ID of the "main" one.
	; RETURNS:        ID/handle of Spotify's main window
	;---------
	getMainWindowId() {
		titleString     := WindowLib.buildTitleString("Spotify.exe", "Chrome_WidgetWin_0", "Spotify") ; If not playing, title is just "Spotify" or "Spotify Premium"
		titleStringPlay := WindowLib.buildTitleString("Spotify.exe", "Chrome_WidgetWin_0", " - ")     ; If playing, title includes spaced hyphen (between the title and artist)
		
		settings := new TempSettings()
		settings.detectHiddenWindows("On")
		settings.titleMatchMode(TitleMatchMode.Contains)
		winId := WinExist(titleString)
		if(!winId)
			winId := WinExist(titleStringPlay)
		settings.restore()
		
		return winId
	}
	
	; #END#
}
