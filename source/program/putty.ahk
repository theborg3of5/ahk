#If MainConfig.isWindowActive("Putty")
	^c::return ; Disable breaking behavior for easy-to-hit-accidentally ^c, PuTTY already has a ^+c hotkey that works too.
	^v::Send, +{Insert} ; Normal paste, without all the inserting of spaces.
	+Tab::Send, {Left} ; Allow reverse field navigation.
	
	; Insert arbitrary text, inserting needed spaces to overwrite.
	^i::Putty.insertArbitraryText()
	
	; Screen wipe
	^l::
		Send, !{Space}
		Send, t
		Send, {Enter}
	return
	; Screen wipe and clear scrollback
	^+l::
		Send, !{Space}
		Send, l
	return
	
	; Search within record edit screens
	^F9::Putty.recordEditSearch()
	^g::Putty.recordEditSearch(true)
	
	; Open up settings window.
	!o::Putty.openSettingsWindow()
	
	; Open up the current log file.
	^+o::Putty.openCurrentLogFile()
	
	; Send specific commands
	^r:: Putty.sendCommand()
	^a:: Putty.sendCommand("BRIDGES")
	^e:: Putty.sendCommand("CHRONICLES")
	^+s::Putty.sendCommand("CR_STATUS")
	^o:: Putty.sendCommand("HS_CONFIG")
	^h:: Putty.sendCommand("HB")
	^z:: Putty.sendCommand("LOOKITT")
	^p:: Putty.sendCommand("PB")
	^+e::Putty.sendCommand("VIEW_RECORD")
#If

class Putty {

; ==============================
; == Public ====================
; ==============================
	static ChangeSettingsOption := 0x50 ; IDM_RECONF, found in Putty's source code in window.c: https://github.com/codexns/putty/blob/master/windows/window.c
	
	; For Home+F9 searching repeatedly.
	static lastSearchType := ""
	static lastSearchText := ""
	
	;---------
	; DESCRIPTION:    Prompt for some text, then insert it (without overwriting) by inserting spaces.
	;---------
	insertArbitraryText() {
		; Popup to get the text.
		textIn := InputBox("Insert text (without overwriting)", , , 500, 100)
		if(textIn = "")
			return
		
		; Get the length of the string we're going to add.
		inputLength := textIn.length()
		
		; Insert that many spaces.
		Send, {Insert %inputLength%}
		
		; Actually send our input text.
		SendRaw, % textIn
	}
	
	;---------
	; DESCRIPTION:    Search within record edit screens with Home+F9 functionality.
	; PARAMETERS:
	;  usePrevious (I,OPT) - Set to true to use the last search type/text instead of prompting the
	;                        user. This is ignored if there was no last search type/text.
	; SIDE EFFECTS:   Sets Putty.lastSearch* to whatever is chosen here for re-use later.
	;---------
	recordEditSearch(usePrevious := false) {
		; Start with the last search type/text if requested.
		if(usePrevious) {
			searchType := Putty.lastSearchType
			searchText := Putty.lastSearchText
		}
	
		; If no previous values (or not using them), prompt the user for how/what to search.
		if(searchType = "" || searchText = "") {
			data := new Selector("puttyRecordEditSearch.tls").selectGui()
			searchType := data["SEARCH_TYPE"]
			searchText := data["SEARCH_TEXT"]
		}
		
		; If still nothing, bail.
		if(searchType = "" || searchText = "")
			return
		
		; Run the search.
		Send, {Home}{F9}
		Send, %searchType%{Enter}
		SendRaw, % searchText
		Send, {Enter}
		
		; Store off the latest search for use with ^g later.
		Putty.lastSearchType := searchType
		Putty.lastSearchText := searchText
	}

	;---------
	; DESCRIPTION:    Open the Change Settings menu
	;---------
	openSettingsWindow() {
		PostMessage, WM_SYSCOMMAND, Putty.ChangeSettingsOption, 0
	}
	
	;---------
	; DESCRIPTION:    Open the current log file
	;---------
	openCurrentLogFile() {
		logFilePath := Putty.getLogFilePath()
		if(logFilePath)
			Run(logFilePath)
	}
	
	;---------
	; DESCRIPTION:    Send a specific command to Putty.
	; PARAMETERS:
	;  key (I,OPT) - A key (from puttyCommands.tls) for which command to send. If left blank, we
	;                will prompt the user for which command to send with a Selector popup.
	;---------
	sendCommand(key := "") {
		data := new Selector("puttyCommands.tls").select(key)
		
		command   := data["COMMAND"]
		sendAfter := data["SEND_AFTER"]
		ini       := stringUpper(data["INI"])
		id        := data["ID"]
		if(!command)
			return
		
		command := command.replaceTags({"INI":ini, "ID":id})
		
		if(!MainConfig.isWindowActive("Putty"))
			WindowActions.activateWindowByName("Putty")
		
		SendRaw, % command
		Send, % sendAfter
	}
	
	
; ==============================
; == Private ===================
; ==============================
	;---------
	; DESCRIPTION:    Get the log file for the current Putty session via the settings window.
	; RETURNS:        The path to the log file
	; SIDE EFFECTS:   Temporarily opens the settings window, then closes it.
	;---------
	getLogFilePath() {
		if(!WinActive("ahk_class PuTTY"))
			return ""
		
		Putty.openSettingsWindow()
		
		; Wait for the popup to show up
		WinWaitActive, ahk_class PuTTYConfigBox
		
		Send, !g ; Category pane
		Send, l  ; Logging tree node
		Send, !f ; Log file name field
		
		logFile := getSelectedText()
		
		Send, !c ; Cancel
		return logFile
	}
}