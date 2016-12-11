; Central place for functions called from Selector.
; All of them should take just one argument, a SelectorRow object (defined in selectorRow.ahk), generally named actionRow.
; There's also a debug mode that most of these should support:
;	You can check whether we're in debug mode via the flag actionRow.debugResult (boolean)
;	If we're in debug mode, the function should NOT perform its usual action, but should instead set actionRow.debugResult to what it WOULD be doing otherwise.
;		For example, if a function normally runs an executable with arguments:
;			Run, C:\full\path\to\executable.exe /a fileNameAndStuff
;		Then when debug mode is on it might store the full string is WOULD have run:
;			actionRow.debugResult := "C:\full\path\to\executable.exe /a fileNameAndStuff"
;	The Selector itself will show that result via DEBUG.popup(), which will show the contents of that variable in a popup.
;		Note that DEBUG.popup() handles objects and will drill down into them, see that class (defined in debug.ahk) for details.


; == Return functions (just return the actionRow object or a specific piece of it) ==
; Just return the requested subscript (defaults to "DOACTION").
RET(actionRow, subToReturn = "DOACTION") {
	if(actionRow.isDebug) ; Debug mode.
		actionRow.debugResult := actionRow.data[subToReturn]
	
	return actionRow.data[subToReturn]
}

; Return data array, for when we want more than just one value back.
RET_DATA(actionRow) {
	if(actionRow.isDebug) ; Debug mode.
		actionRow.debugResult := actionRow.data
	
	return actionRow.data
}

; Return entire object.
RET_OBJ(actionRow) {
	if(actionRow.isDebug) ; Debug mode.
		actionRow.debugResult := actionRow
	
	return actionRow
}


; == Run functions (simply run DOACTION subscript of the actionRow object) ==
; Run the action.
DO(actionRow) {
	if(actionRow.isDebug) ; Debug mode.
		actionRow.debugResult := actionRow
	else
		Run, % actionRow.data["DOACTION"]
}
	
; Run the action, waiting for it to finish.
DO_WAIT(actionRow) {
	if(actionRow.isDebug) ; Debug mode.
		actionRow.debugResult := actionRow
	else
		RunWait, % actionRow.data["DOACTION"]
}


; == File operations ==
; Write to the windows registry.
REG_WRITE(actionRow) {
	keyName   := actionRow.data["KEY_NAME"]
	keyValue  := actionRow.data["KEY_VALUE"]
	keyType   := actionRow.data["KEY_TYPE"]
	rootKey   := actionRow.data["ROOT_KEY"]
	regFolder := actionRow.data["REG_FOLDER"]
	
	if(actionRow.isDebug) ; Debug mode.
		actionRow.debugResult := {"Key name":keyName, "Key value":keyValue, "Key Type":keyType, "Root key":rootKey, "Key folder":regFolder}
	else
		RegWrite, %keyType%, %rootKey%, %regFolder%, %keyName%, %keyValue%
}

; Change a value in an ini file.
INI_WRITE(actionRow) {
	offStrings := ["o", "f", "off", "0"]
	
	if(actionRow.data["FILE"]) {
		file := actionRow.data["FILE"]
		sect := actionRow.data["SECTION"]
		key  := actionRow.data["KEY"]
		val  := actionRow.data["VALUE"]
		
	; Special debug case - key from name, value from arbitrary end.
	} else {
		file := actionRow.data["KEY"]
		sect := actionRow.data["VALUE"]
		key  := actionRow.data["NAME"]
		val  := !contains(offStrings, actionRow.userInput)
	}
	
	if(actionRow.isDebug) { ; Debug mode.
		actionRow.debugResult := {"File":file, "Section":sect, "Key":key, "Value":val}
		return
	}
	
	if(!val) ; Came from post-pended arbitrary piece.
		IniDelete, %file%, %sect%, %key%
	else
		IniWrite, %val%, %file%, %sect%, %key%
}

; Updates specific settings out of the main script's configuration file, then reloads it.
UPDATE_AHK_SETTINGS(actionRow) {
	global MAIN_CENTRAL_SCRIPT
	INI_WRITE(actionRow) ; Has its own debug handling.
	
	; Also reload the script to reflect the updated settings.
	if(actionRow.isDebug) ; Debug mode.
		return ; actionRow.debugResult already set by INI_WRITE.
	else
		reloadScript(MAIN_CENTRAL_SCRIPT, true)
}


; == Open specific programs ==
; Run Hyperspace.
DO_HYPERSPACE(actionRow) {
	versionMajor := actionRow.data["MAJOR"]
	versionMinor := actionRow.data["MINOR"]
	environment  := actionRow.data["COMMID"]
	
	; Error check.
	if(!versionMajor || !versionMinor) {
		DEBUG.popup("DO_HYPERSPACE", "Missing info", "Major version", versionMajor, "Minor version", versionMinor)
		return
	}
	
	; Build run path.
	runString := callIfExists("buildHyperspaceRunString", versionMajor, versionMinor, environment) ; buildHyperspaceRunString(versionMajor, versionMinor, environment)
	
	; Do it.
	if(actionRow.isDebug) ; Debug mode.
		actionRow.debugResult := runString
	else
		Run, % runString
}

; Run something through Thunder, generally a text session or Citrix.
DO_THUNDER(actionRow) {
	runString := ""
	thunderID := actionRow.data["THUNDERID"]
	
	; Error check.
	if(!thunderID) {
		DEBUG.popup("DO_THUNDER", "Missing info", "Thunder ID", thunderID)
		return
	}
	
	if(isNum(thunderID))
		runString := MainConfig.getProgram("Thunder", "PATH") " " thunderID
	else if(thunderID = "SHOWTHUNDER") ; Special keyword - just show Thunder itself, don't launch an environment.
		runString := thunderID
	
	; Do it.
	if(actionRow.isDebug) ; Debug mode.
		actionRow.debugResult := runString
	else if(runString = "SHOWTHUNDER")
		activateProgram("Thunder")
	else
		Run, % runString
}

; Run a citrix session through Thunder.
DO_CITRIX(actionRow) {
	actionRow.data["THUNDERID"] := actionRow.data["CITRIXTHUNDERID"]
	DO_THUNDER(actionRow)
}

; Open a homebrew timer (script located in the filepath below).
TIMER(actionRow) {
	time := actionRow.data["TIME"]
	runString := ahkRootPath "\source\standalone\timer\timer.ahk " time
	
	; Do it.
	if(actionRow.isDebug) ; Debug mode.
		actionRow.debugResult := runString
	else
		Run, % runString
}


; == Other assorted action functions ==
; Call a phone number.
CALL(actionRow) {
	num := actionRow.data["NUMBER"]
	special := actionRow.data["SPECIAL"]
	
	if(actionRow.isDebug) { ; Debug mode.
		actionRow.debugResult := {"Number":num, "Special":special}
		return
	}
	
	if(special = "SEARCH") { ; Use QuickDial to search for the given name (not a number)
		callIfExists("activateProgram", "QuickDialer") ; activateProgram("QuickDialer")
		WinWaitActive, Quick Dial
		if(num != "SEARCH")
			SendRaw, %num%
	} else {
		callIfExists("callNumber", num, actionRow.data["NAME"]) ; callNumber(num, actionRow.data["NAME"])
	}
}

; Resizes the active window to the given dimensions.
RESIZE(actionRow) {
	width  := actionRow.data["WIDTH"]
	height := actionRow.data["HEIGHT"]
	ratioW := actionRow.data["WRATIO"]
	ratioH := actionRow.data["HRATIO"]
	
	if(ratioW)
		width *= ratioW
	if(ratioH)
		height *= ratioH
	
	; Do it.
	if(actionRow.isDebug) ; Debug mode.
		actionRow.debugResult := {"Width":width, "Height":height}
	else
		WinMove, A, , , , width, height
}

; Builds a string to add to a calendar event (with the format the outlook/tlg calendar needs to import happily into Delorean), then sends it and an Enter keystroke to save it.
OUTLOOK_TLG(actionRow) {
	tlp      := actionRow.data["TLP"]
	message  := actionRow.data["MSG"]
	dlg      := actionRow.data["DLG"]
	customer := actionRow.data["CUST"]
	
	actionRow.data["DOACTION"] := tlp "/" customer "///" dlg ", " message
	
	; Do it.
	if(actionRow.isDebug) { ; Debug mode.
		actionRow.debugResult := actionRow.data["DOACTION"]
	} else {
		; focusedControl := getFocusedControl()
		textToSend := actionRow.data["DOACTION"]
		SendRaw, % textToSend
		Send, {Enter}
		; ControlSendRaw, %focusedControl%, %textToSend%, ahk_class rctrl_renwnd32
		; ControlSend, %focusedControl%, {Enter}, ahk_class rctrl_renwnd32
	}
}

; Change the windows and VB themes.
CHANGE_THEME(actionRow) {
	actionType := actionRow.data["ACTIONTYPE"]
	
	if(actionType = "COPY" || actionType = "MOVE") {
		fromFile := actionRow.data["FROMFILE"]
		toFile := actionRow.data["TOFILE"]
		fromFolder := actionRow.data["FROMFOLDER"]
		toFolder := actionRow.data["TOFOLDER"]
		
		; Empty toFolder means stay in same folder.
		if(toFolder = "")
			toFolder := fromFolder
		
		if(actionRow.isDebug) { ; Debug mode.
			actionRow.debugResult := {"Action Type":actionType, "From folder":fromFolder, "From file":fromFile, "To folder":toFolder, "To file":toFile}
			return
		}
		
		if(actionType = "COPY")
			FileCopy, %fromFolder%\%fromFile%, %toFolder%\%toFile%, 1
		else
			FileMove, %fromFolder%\%fromFile%, %toFolder%\%toFile%, 1
		
		if(ErrorLevel)
			DEBUG.popup("Number of files that failed to copy/move due to errors", ErrorLevel)
	} else if(actionType = "RUN") {
		fileToRun := actionRow.data["FROMFILE"]
		mouseFix := actionRow.data["TOFILE"]
		otherKey1 := actionRow.data["FROMFOLDER"]
		otherKey2 := actionRow.data["TOFOLDER"]
		
		if(actionRow.isDebug) { ; Debug mode.
			actionRow.debugResult := {"Action Type":actionType, "Runfile 1":fileToRun, "Mouse fix":mouseFix, "Other key 1":otherKey1, "Other key 2":otherKey2}
			return
		}
		
		RunWait, %fileToRun%
		
		if(mouseFix = "MOUSEFIX") {
			Run, C:\Windows\System32\control.exe main.cpl,,1
			WinWaitActive, Mouse Properties
			Sleep, 100
			Send, ^{Tab}
			Sleep, 100
			Send, {Enter}
		}
		
		if(otherKey1)
			Selector.select("theme.tl", "CHANGE_THEME", otherKey1)
		if(otherKey2)
			Selector.select("theme.tl", "CHANGE_THEME", otherKey2)
		
	} else {
		DEBUG.popup("Undefined theme change operation", actionType)
	}
}
