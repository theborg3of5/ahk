; EpicStudio hotkeys and helpers.
#If MainConfig.isWindowActive("EpicStudio")
	; Remap some of the tools to get easier access to those I use often.
	!1::!3 ; EZParse
	!2::!5 ; Error List
	!3::!6 ; Call Hierarchy
	!4::!8 ; Item expert
	
	; Line operations
	$^d::EpicStudio.deleteLinePreservingClipboard()
	^l::EpicStudio.duplicateLine()
	
	; Copy current code location
	!c:: EpicStudio.copyCleanCodeLocation()  ; Cleaned, just the actual location
	!#c::EpicStudio.copyLinkedCodeLocation() ; RTF location with link.
	
	; Link routine to currently open DLG in EMC2.
	^+l::EpicStudio.linkRoutineToCurrentDLG()
	
	; Generate and insert snippet
	::.snip::EpicStudio.insertMSnippet()
	
	; Debug, auto-search for workstation ID.
	~F5::EpicStudio.runDebug("ws:" MainConfig.private["WORK_COMPUTER_NAME"])
	F6:: EpicStudio.runDebug("ws:" A_IPAddress1)
#If

class EpicStudio {

; ==============================
; == Public ====================
; ==============================
	;---------
	; DESCRIPTION:    Delete the current line in EpicStudio, but preserve the clipboard (delete line
	;                 hotkey puts the line on the clipboard)
	;---------
	deleteLinePreservingClipboard() {
		originalClipboard := clipboardAll ; Save off the entire clipboard
		clipboard := ""                   ; Clear the clipboard (so we can wait for the new value)
		
		Send, ^d    ; Delete line hotkey in EpicStudio (also unfortunately overwrites the clipboard with deleted line)
		ClipWait, 2 ; Wait for 2 seconds for clipboard to be overwritten
		
		clipboard := originalClipboard    ; Restore the original clipboard. Note we're using clipboard (not clipboardAll).
	}
	
	
	duplicateLine() {
		Send, {End}   ; If anything is selected, deselect it
		Send, ^c      ; Copy the whole line (since nothing is selected), including the newline at the end
		Send, {Home}  ; Get to start of line so the newline comes before the existing line
		Send, ^v      ; Paste the duplicate line
		
	}
	
	;---------
	; DESCRIPTION:    Put the current location in code (tag^routine) onto the clipboard, stripping
	;                 off any offset ("+4" in "tag+4^routine") and the RTF link that EpicStudio adds.
	; SIDE EFFECTS:   Shows a toast letting the user know what we put on the clipboard.
	;---------
	copyCleanCodeLocation() {
		if(!EpicStudio.copyCodeLocation())
			return
		
		codeLocation := clipboard
		
		; Initial value copied potentially has the offset (tag+<offsetNum>) included, strip it off.
		codeLocation := dropOffsetFromServerLocation(codeLocation)
		
		; Set the clipboard value to our new (plain-text, no link) code location and notify the user.
		setClipboardAndToastValue(codeLocation, "cleaned code location")
	}
	
	;---------
	; DESCRIPTION:    Put the current location in code (tag^routine) onto the clipboard.
	; SIDE EFFECTS:   Shows a toast letting the user know what we put on the clipboard.
	;---------
	copyLinkedCodeLocation() {
		if(!EpicStudio.copyCodeLocation())
			return
		
		; Notify the user of the new value.
		toastNewClipboardValue("linked code location")
	}
	
	;---------
	; DESCRIPTION:    Link the current routine to the DLG currently open in EMC2.
	;---------
	linkRoutineToCurrentDLG() {
		record := new EpicRecord()
		record.initFromEMC2Title()
		if(record.ini != "DLG" || record.id = "")
			return
		
		Send, ^l
		WinWaitActive, Link DLG, , 5
		Send, % record.id
		Send, {Enter 2}
	}
	
	;---------
	; DESCRIPTION:    Generate and insert an M snippet.
	;---------
	insertMSnippet() {
		; Get current line for analysis.
		Send, {End}{Home 2} ; Get to very start of line (before indentation)
		Send, {Shift Down}{End}{Shift Up} ; Select entire line (including indentation)
		line := getSelectedText()
		Send, {End} ; Get to end of line
		
		line := removeStringFromStart(line, "`t") ; Tab at the start of every line
		
		numIndents := 0
		while(stringStartsWith(line, ". ")) {
			numIndents++
			line := removeStringFromStart(line, ". ")
		}
		
		; If it's an empty line with just a semicolon, remove the semicolon.
		if(line = ";")
			Send, {Backspace}
		
		s := new Selector("MSnippets.tls")
		data := s.selectGui()
		
		type := data["TYPE"]
		if(data["TYPE"] = "LOOP")
			snipString := EpicStudio.buildMLoop(data, numIndents)
		
		sendTextWithClipboard(snipString) ; Better to send with the clipboard, otherwise we have to deal with EpicStudio adding in dot-levels itself.
	}
	
	;---------
	; DESCRIPTION:    Run EpicStudio in debug mode, or continue debugging if we're already in it.
	; PARAMETERS:
	;  searchString (I,REQ) - String to automatically search for in the attach process popup
	;---------
	runDebug(searchString) {
		; Always send F5, even in debug mode - continue.
		Send, {F5}
		
		; Don't try and debug again if ES is already doing so.
		if(EpicStudio.isDebugging())
			return
		
		WinWait, Attach to Process, , 5
		if(ErrorLevel)
			return
		
		currFilter := ControlGet("Line", 1, "Edit1", "A")
		if(currFilter) {
			ControlFocus, Edit1, A
			return ; There's already something plugged into the field, so just put the focus there in case they want to change it.
		}
		
		; Pick the radio button for "Other existing process:" and pick it.
		otherProcessRadioButtonClass := "WindowsForms10.BUTTON.app.0.2bf8098_r9_ad11"
		ControlFocus, %otherProcessRadioButtonClass%, A
		ControlSend, %otherProcessRadioButtonClass%, {Space}, A
		
		; Focus the filter field and send what we want to send.
		ControlFocus, Edit1, A
		Send, % searchString
		Send, {Enter}{Down}
	}
	
	
; ==============================
; == Private ===================
; ==============================
	;---------
	; DESCRIPTION:    Determine whether EpicStudio is in debug mode right now.
	; RETURNS:        true if EpicStudio is in debug mode, false otherwise.
	;---------
	isDebugging() {
		isDebugging := false
		
		origMatchMode  := setTitleMatchMode(TITLE_MATCH_MODE_Contain)
		origMatchSpeed := setTitleMatchSpeed("Slow")
		
		; Match on text in the window for the main debugging targets
		winId := WinActive("", MainConfig.private["ES_PUTTY_EXE"])
		if(!winId)
			winId := WinActive("", MainConfig.private["ES_HYPERSPACE_EXE"])
		if(!winId)
			winId := WinActive("", MainConfig.private["ES_VB6_EXE"])
		
		setTitleMatchMode(origMatchMode)
		setTitleMatchSpeed(origMatchSpeed)
		
		return isDebugging
	}
	
	;---------
	; DESCRIPTION:    Copy the current code location (with offset and RTF link) from EpicStudio to
	;                 the clipboard.
	; RETURNS:        True if we got a code location on the clipboard, False otherwise.
	; SIDE EFFECTS:   Waits for the clipboard to contain the location, and shows an error toast if
	;                 it doesn't when we time out.
	;---------
	copyCodeLocation() {
		if(copyWithHotkey("^{Numpad9}")) ; Hotkey to copy code location to clipboard
			return true
		
		Toast.showError("Failed to get code location")
		return false
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop with the given data.
	; PARAMETERS:
	;  data       (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          data["SUBTYPE"] - The type of loop this is.
	;  numIndents (I,OPT) - The starting indentation (so that the line after can be indented 1
	;                       more). Defaults to 0 (no indentation).
	; RETURNS:        String of the text for the generated for loop.
	;---------
	buildMLoop(data, numIndents := 0) {
		loopString := ""
		
		subType := data["SUBTYPE"]
		
		if(subType = "ARRAY_GLO") {
			loopString .= EpicStudio.buildMArrayLoop(data, numIndents)
		
		} else if(subType = "ID") {
			loopString .= EpicStudio.buildMIdLoop(data, numIndents)
		
		} else if(subType = "DAT") {
			loopString .= EpicStudio.buildMDatLoop(data, numIndents)
			
		} else if(subType = "ID_DAT") {
			loopString .= EpicStudio.buildMIdLoop(data, numIndents)
			loopString .= EpicStudio.buildMDatLoop(data, numIndents)
			
		} else if(subType = "INDEX_REG_VALUE") {
			loopString .= EpicStudio.buildMIndexRegularValueLoop(data, numIndents)
			
		} else if(subType = "INDEX_REG_ID") {
			loopString .= EpicStudio.buildMIndexRegularIDLoop(data, numIndents)
			
		}
		
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate nested M for loops using the given data.
	; PARAMETERS:
	;  data        (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          data["ARRAY_OR_INI"] - The name of the array or global (with @s around it)
	;                              ["VAR_NAMES"]    - Comma-delimited list of iterator variables to loop with.
	;  numIndents (IO,OPT) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMArrayLoop(data, ByRef numIndents := 0) {
		arrayName   := data["ARRAY_OR_INI"]
		iteratorAry := strSplit(data["VAR_NAMES"], ",")
		
		if(stringStartsWith(arrayName, "@") && !stringEndsWith(arrayName, "@"))
			arrayName .= "@" ; End global references with the proper @ if they're not already.
		
		prevIterators := ""
		for i,iterator in iteratorAry {
			loopString .= replaceTags(MainConfig.private["M_LOOP_ARRAY_BASE"], {"ARRAY_NAME":arrayName, "ITERATOR":iterator, "PREV_ITERATORS":prevIterators})
			
			prevIterators .= iterator ","
			loopString .= EpicStudio.getMNewLinePlusIndent(numIndents)
		}
		
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over IDs using the given data.
	; PARAMETERS:
	;  data        (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          data["ARRAY_OR_INI"] - The INI of the records to loop through
	;  numIndents (IO,OPT) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMIdLoop(data, ByRef numIndents := 0) {
		ini := stringUpper(data["ARRAY_OR_INI"])
		
		idVar := stringLower(ini) "Id"
		loopString := replaceTags(MainConfig.private["M_LOOP_ID_BASE"], {"INI":ini, "ID_VAR":idVar})
		
		loopString .= EpicStudio.getMNewLinePlusIndent(numIndents)
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over DATs using the given data.
	; PARAMETERS:
	;  data        (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          data["ARRAY_OR_INI"] - The INI of the records to loop through
	;  numIndents (IO,OPT) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMDatLoop(data, ByRef numIndents := 0) {
		ini := stringUpper(data["ARRAY_OR_INI"])
		
		idVar  := stringLower(ini) "Id"
		datVar := stringLower(ini) "Dat"
		loopString := replaceTags(MainConfig.private["M_LOOP_DAT_BASE"], {"INI":ini, "ID_VAR":idVar, "DAT_VAR":datVar, "ITEM":""})
		
		loopString .= EpicStudio.getMNewLinePlusIndent(numIndents)
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over regular index values for the given data.
	; PARAMETERS:
	;  data        (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          data["ARRAY_OR_INI"] - The INI of the records to loop through
	;                              ["VAR_NAMES"]    - The name of the iterator variable to use for values
	;  numIndents (IO,OPT) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMIndexRegularValueLoop(data, ByRef numIndents := 0) {
		ini := stringUpper(data["ARRAY_OR_INI"])
		valueVar := data["VAR_NAMES"]
		
		loopString := replaceTags(MainConfig.private["M_LOOP_INDEX_REGULAR_NEXT_VALUE"], {"INI":ini, "ITEM":"", "VALUE_VAR":valueVar})
		
		loopString .= EpicStudio.getMNewLinePlusIndent(numIndents)
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over regular index IDs with a particular value for the
	;                 given data.
	; PARAMETERS:
	;  data        (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          data["ARRAY_OR_INI"] - The INI of the records to loop through
	;                              ["VAR_NAMES"]    - The name of the iterator variable to use for values
	;  numIndents (IO,OPT) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMIndexRegularIDLoop(data, ByRef numIndents := 0) {
		ini := stringUpper(data["ARRAY_OR_INI"])
		valueVar := data["VAR_NAMES"]
		
		idVar  := stringLower(ini) "Id"
		loopString := replaceTags(MainConfig.private["M_LOOP_INDEX_REGULAR_NEXT_ID"], {"INI":ini, "ITEM":"", "VALUE_VAR":valueVar, "ID_VAR":idVar})
		
		loopString .= EpicStudio.getMNewLinePlusIndent(numIndents)
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Get the text for a new line in M code, adding 1 indent more than the current line.
	; PARAMETERS:
	;  currNumIndents (IO,REQ) - The number of indents on the current line. Will be incremented by 1.
	; RETURNS:        The string to start a new line with 1 indent more.
	;---------
	getMNewLinePlusIndent(ByRef currNumIndents) {
		outString := "`n`t" ; New line + tab (at the start of every line)
		
		; Increase indentation level and add indentation
		currNumIndents++
		outString .= multiplyString(". ", currNumIndents)
		
		return outString
	}
}
