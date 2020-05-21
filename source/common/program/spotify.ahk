class Spotify {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Toggle play/pause.
	; SIDE EFFECTS:   Shows a toast with the current song info, if applicable.
	;---------
	playPause() {
		this.sendCommandAndShowInfo(MicrosoftLib.AppCommand_PlayPause)
	}
	
	;---------
	; DESCRIPTION:    Go to the previous track.
	; SIDE EFFECTS:   Shows a toast with the new song info, if applicable.
	;---------
	previousTrack() {
		this.sendCommandAndShowInfo(MicrosoftLib.AppCommand_PreviousTrack)
	}
	
	;---------
	; DESCRIPTION:    Go to the next track.
	; SIDE EFFECTS:   Shows a toast with the new song info, if applicable.
	;---------
	nextTrack() {
		this.sendCommandAndShowInfo(MicrosoftLib.AppCommand_NextTrack)
	}
	
	;---------
	; DESCRIPTION:    Show the current song's title and artist in a toast (if there's one playing right now).
	; PARAMETERS:
	;  idString    (I,OPT) - The identifying string for Spotify's main window. Will be retrieved from
	;                        .getMainWindowId() if not given.
	;  titleBefore (I,OPT) - If we just changed the title (like when we send a command), the old title.
	;                        Will be used to display previous song info if we just paused.
	;---------
	showCurrentInfo(idString := "", titleBefore := "") {
		if(idString = "")
			idString := "ahk_id " this.getMainWindowId()
		
		title := WinGetTitle(idString)
		if(!title.contains(" - ")) { ; No song information (presumably because we just paused or hit the end of a playlist)
			; If we just came from a state with song info, show what it was (for when we paused)
			if(titleBefore.contains(" - ")) {
				artist := titleBefore.beforeString(" - ")
				song   := titleBefore.afterString(" - ")
				this.showInfoToast(song " [Paused]" "`n`n" artist)
			} else {
				this.showInfoToast("Paused")
			}
			
			return
		}
		
		artist := title.beforeString(" - ")
		song   := title.afterString(" - ")
		this.showInfoToast(song "`n`n" artist)
	}
	
	;---------
	; DESCRIPTION:    Spotify has a whole bunch of windows that are difficult to tell apart from the
	;                 real thing. This finds and returns the window ID of the "main" one.
	; RETURNS:        ID/handle of Spotify's main window
	;---------
	getMainWindowId() {
		titleString     := WindowLib.buildTitleString("Spotify.exe", "", "Spotify") ; If not playing, title is just "Spotify" or "Spotify Premium"
		titleStringPlay := WindowLib.buildTitleString("Spotify.exe", "", " - ")     ; If playing, title includes a hyphen with spaces around it (between the title and artist)
		
		settings := new TempSettings()
		settings.detectHiddenWindows("On")
		settings.titleMatchMode(TitleMatchMode.Contains)
		winId := WinExist(titleString)
		if(!winId)
			winId := WinExist(titleStringPlay)
		settings.restore()
		
		return winId
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Send a specific app command to the main Spotify window, then show info about
	;                 the new song once it changes.
	; PARAMETERS:
	;  command (I,REQ) - The command (from MicrosoftLib.AppCommand_*) to send
	;---------
	sendCommandAndShowInfo(command) {
		idString := "ahk_id " this.getMainWindowId()
		titleBefore := WinGetTitle(idString)
		
		; Send the message
		PostMessage, MicrosoftLib.Message_AppCommand, , % command, , % idString
		
		; Wait for the title to change so we can get the new one
		WinWaitClose, % WindowLib.buildTitleString("Spotify.exe", , titleBefore), , 3 ; 3s timeout
		if(ErrorLevel = 1) ; Timed out
			return
		
		this.showCurrentInfo(idString, titleBefore)
	}
	
	;---------
	; DESCRIPTION:    Show the given string in a toast in the top-left.
	; PARAMETERS:
	;  infoString (I,REQ) - The string to show. May include newlines if desired.
	;---------
	showInfoToast(infoString) {
		styles := {}
		styles["BACKGROUND_COLOR"] := "000000" ; Black
		styles["FONT_COLOR"]       := "CCCCCC" ; Light gray
		styles["FONT_SIZE"]        := 20
		styles["FONT_NAME"]        := "Segoe UI"
		styles["MARGIN_X"]         := 40
		styles["MARGIN_Y"]         := 20
		
		t := new Toast(infoString, styles)
		t.blockingOn()
		t.showForSeconds(2, VisualWindow.X_LeftEdge "+50", VisualWindow.Y_TopEdge "+30")
	}
	
	; #END#
}
