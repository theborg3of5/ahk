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
	
	
	playPause() {
		this.sendCommandAndShowInfo(0xE0000)
		return
		
		idString := "ahk_id " this.getMainWindowId()
		; titleString := WindowLib.buildTitleString("Spotify.exe", "", WinGetTitle(idString))
		
		titleBefore := WinGetTitle(idString)
		; if(titleBefore.startsWith("Spotify"))
			; isPaused := true
		
		PostMessage, 0x319, , 0xE0000, , % idString
		
		; ; Wait for the title to change so we can get the new one
		; WinWaitClose, % WindowLib.buildTitleString("Spotify.exe", , titleBefore), , 3 ; 3s timeout
		; if(ErrorLevel = 1) ; Timed out
			; return
		
		this.showInfoOnChange(titleBefore)
		; this.showCurrentInfo()
		
		; title := WinGetTitle(idString)
		; if(!title.contains("-")) ; No song information (presumably because we just paused or hit the end of a playlist)
			; return
		
		; ; ; Default to the new title, unless it doesn't have song/artist info (presumably because we just paused)
		; ; titleAfter := WinGetTitle(titleString)
		; ; if(titleAfter.contains("-"))
			; ; title := titleAfter
		; ; else
			; ; title := titleBefore
		
		; ; Debug.popup("titleBefore",titleBefore, "titleAfter",titleAfter, "title",title)
		; titleAry := title.split("-", A_Space)
		; artist := titleAry[1]
		; song   := titleAry[2]
		
		; styles := {}
		; styles["BACKGROUND_COLOR"] := "000000" ; Black
		; styles["FONT_COLOR"]       := "CCCCCC" ; Light gray
		; styles["FONT_SIZE"]        := 20
		; styles["FONT_NAME"]        := "Segoe UI"
		; styles["MARGIN_X"]         := 40
		; styles["MARGIN_Y"]         := 20
		
		; t := new Toast(song "`n" artist, styles)
		; t.blockingOn()
		; t.showForSeconds(2, VisualWindow.X_LeftEdge "+50", VisualWindow.Y_TopEdge "+30")
	}
	
	previousTrack() {
		this.sendCommandAndShowInfo(0xC0000)
		; winId := this.getMainWindowId()
		; PostMessage, 0x319, , 0xC0000, , % "ahk_id " winId
	}
	
	nextTrack() {
		this.sendCommandAndShowInfo(0xB0000)
		; winId := this.getMainWindowId()
		; PostMessage, 0x319, , 0xB0000, , % "ahk_id " winId
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
	
	
	sendCommandAndShowInfo(command) {
		idString := "ahk_id " this.getMainWindowId()
		titleBefore := WinGetTitle(idString)
		
		PostMessage, 0x319, , % command, , % idString
		
		
		; Wait for the title to change so we can get the new one
		WinWaitClose, % WindowLib.buildTitleString("Spotify.exe", , titleBefore), , 3 ; 3s timeout
		if(ErrorLevel = 1) ; Timed out
			return
		
		this.showCurrentInfo(idString)
	}
	
	
	showCurrentInfo(idString := "") {
		if(idString = "")
			idString := "ahk_id " this.getMainWindowId()
		
		title := WinGetTitle(idString)
		if(!title.contains("-")) ; No song information (presumably because we just paused or hit the end of a playlist)
			return
		
		; ; Default to the new title, unless it doesn't have song/artist info (presumably because we just paused)
		; titleAfter := WinGetTitle(titleString)
		; if(titleAfter.contains("-"))
			; title := titleAfter
		; else
			; title := titleBefore
		
		; Debug.popup("titleBefore",titleBefore, "titleAfter",titleAfter, "title",title)
		artist := title.beforeString(" - ")
		song   := title.afterString(" - ")
		; titleAry := title.split("-", A_Space)
		; artist := titleAry[1]
		; song   := titleAry[2]
		
		styles := {}
		styles["BACKGROUND_COLOR"] := "000000" ; Black
		styles["FONT_COLOR"]       := "CCCCCC" ; Light gray
		styles["FONT_SIZE"]        := 20
		styles["FONT_NAME"]        := "Segoe UI"
		styles["MARGIN_X"]         := 40
		styles["MARGIN_Y"]         := 20
		
		t := new Toast(song "`n`n" artist, styles)
		t.blockingOn()
		t.showForSeconds(2, VisualWindow.X_LeftEdge "+50", VisualWindow.Y_TopEdge "+30")
	}
	
	; #END#
}
