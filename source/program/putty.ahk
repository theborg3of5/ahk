global lastPuttySearchType, lastPuttySearchText ; For Home+F9 searching repeatedly.

#IfWinActive, ahk_class PuTTY
	; Insert arbitrary text, inserting needed spaces to overwrite.
	^i::
		insertArbitraryText() {
			; Popup to get the text.
			textIn := InputBox("Insert text (without overwriting)", , , 500, 100)
			if(textIn = "")
				return
			
			; Get the length of the string we're going to add.
			inputLength := StrLen(textIn)
			
			; Insert that many spaces.
			Send, {Insert %inputLength%}
			
			; Actually send our input text.
			SendRaw, % textIn
		}
	
	; Search within record edit screens
	^F9::recordEditSearch()
	^g::recordEditSearch(lastPuttySearchType, lastPuttySearchText)
	recordEditSearch(searchType = "", searchText = "") {
		; If nothing given, prompt the user for how/what to search.
		if(searchType = "" || searchText = "") {
			s := new Selector("puttyRecordEditSearch.tls")
			data := s.selectGui()
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
		lastPuttySearchType := searchType
		lastPuttySearchText := searchText
	}
	
	; Normal paste, without all the inserting of spaces.
	^v::Send, +{Insert}
	
	; Disable breaking behavior for easy-to-hit-accidentally ^c, PuTTY already has a ^+c hotkey that works too.
	^c::return
	
	; Screen wipe
	^l::
		Send, !{Space}
		Send, t
		Send, {Enter}
	return
	^+l::
		Send, !{Space}
		Send, l
	return
	
	; Allow reverse field navigation.
	+Tab::
		Send, {Left}
	return
	
	; Open up settings window.
	!o::
		openPuttySettingsWindow()
	return
	
	; Open up the current log file.
	^+o::
		openCurrentLogFile() {
			logFilePath := GetPuttyLogFile()
			if(logFilePath)
				Run(logFilePath)
		}
	
	; Make page up/down actually move a page up/down (each Shift+Up/Down does a half a page).
	^PgUp::
		Send, +{PgUp 2}
	return
	^PgDn::
		Send, +{PgDn 2}
	return
	
	{ ; Various commands.
		^r:: sendPuttyRoutine()
		^z:: sendPuttyRoutine("LOOKITT")
		^o:: sendPuttyRoutine("HS_CONFIG")
		^h:: sendPuttyRoutine("HB")
		^p:: sendPuttyRoutine("PB")
		^+e::sendPuttyRoutine("VIEW_RECORD")
		
		^e::
			Send, e{Space}
		return
		
		^+s::
			SendRaw, % "d ^" getPuttyRoutine("CR")
			Send, {Enter}
			Send, 1{Enter}
		return
		
		::.lock::
			SendRaw, w $$zlock(" ; Extra comment/quote here to fix syntax highlighting. "
		return
		::.unlock::
			SendRaw, w $$zunlock(" ; Extra comment/quote here to fix syntax highlighting. "
		return
	}
#IfWinActive


; Opens the Change Settings menu for putty. 0x50 is IDM_RECONF, the change settings option. 
; It's found in putty's source code in window.c:
; https://github.com/codexns/putty/blob/master/windows/window.c
openPuttySettingsWindow() {
	PostMessage, WM_SYSCOMMAND, 0x50, 0
}

; Modified from http://wiki.epic.com/main/PuTTY#AutoHotKey_for_PuTTY_Macros
getPuttyLogFile() {
	if(!WinActive("ahk_class PuTTY"))
		return ""
	
	openPuttySettingsWindow()
	
	; need to wait a bit for the popup to show up
	Sleep, 50 ; GDB TODO - replace this with a WinWait?
	
	Send, !g ; Category pane
	Send, l  ; Logging tree node
	Send, !f ; Log file name field
	
	logFile := getSelectedText()
	
	Send, !c ; Cancel
	return logFile
}

sendPuttyRoutine(key := "") {
	routine := getPuttyRoutine(key)
	if(!routine)
		return
	
	SendRaw, % "d ^" routine
	Send, {Enter}
}

getPuttyRoutine(key := "") {
	s := new Selector("puttyRoutines.tls")
	if(key)
		routine := s.selectChoice(key, "ROUTINE")
	else
		routine := s.selectGui("ROUTINE")
	
	return routine
}
