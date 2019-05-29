; EpicStudio hotkeys and helpers.
#IfWinActive, ahk_exe EpicStudio.exe
	; Remap some of the tools to get easier access to those I use often.
	!1::!3 ; EZParse
	!2::!5 ; Error List
	!3::!6 ; Call Hierarchy
	!4::!8 ; Item expert
	
	; Better access to INTermediate code.
	!i::ControlSend, , ^+v
	
	; Make copy line location !c.
	!c:: epicStudioCopyCleanCodeLocation()
	!#c::epicStudioCopyLinkedCodeLocation()
	
	; Delete line hotkey
	$^d::
		epicStudioDeleteLinePreservingClipboard() {
			originalClipboard := clipboardAll ; Save off the entire clipboard
			clipboard := ""                   ; Clear the clipboard (so we can wait for the new value)
			
			Send, ^d ; Delete line hotkey in EpicStudio (also unfortunately overwrites the clipboard with deleted line)
			ClipWait, 2 ; Wait for 2 seconds for clipboard to be overwritten
			
			clipboard := originalClipboard    ; Restore the original clipboard. Note we're using clipboard (not clipboardAll).
		}
	
	; ; Debug, auto-search for workstation ID.
	~F5::epicStudioDebug("ws:" MainConfig.private["WORK_COMPUTER_NAME"])
	F6:: epicStudioDebug("ws:" A_IPAddress1)
	
	; Run EpicStudio in debug mode, given a particular string to search for.
	epicStudioDebug(searchString) {
		; Always send F5, even in debug mode - continue.
		Send, {F5}
		
		; Don't try and debug again if ES is already doing so.
		if(isESDebugging())
			return
		
		WinWait, Attach to Process, , 5
		if(ErrorLevel)
			return
		
		currFilter := ControlGet("Line", 1, "Edit1", "A")
		currFilter := ControlGet("Line", 1, "Edit1", "A")
		if(currFilter) {
			ControlFocus, Edit1, A
			return ; There's already something plugged into the field, so just put the focus there in case they want to change it.
		}
		
		; Pick the radio button for "Other existing process:" and pick it.
		otherProcessRadioButtonClass := WindowsForms10.BUTTON.app.0.2bf8098_r9_ad11
		ControlFocus, %otherProcessRadioButtonClass%, A
		ControlSend, %otherProcessRadioButtonClass%, {Space}, A
		
		; Focus the filter field and send what we want to send.
		ControlFocus, Edit1, A
		Send, % searchString
		Send, {Enter}{Down}
	}
	
	; Checks if ES is already in debug mode or not.
	isESDebugging() {
		isDebugging := false
		
		origMatchMode := setTitleMatchMode(TITLE_MATCH_MODE_Contain)
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
	
	; Link routine to currently open (in object explorer tab) DLG.
	^+l::
		linkRoutineToCurrentDLG() {
			text := WinGetText()
			
			Loop, Parse, text, `n
			{
				if(stringStartsWith(A_LoopField, "DLG ")) {
					dlgNum := getStringAfterStr(A_LoopField, "DLG ")
					; DEBUG.popup("On line", A_Index, "With DLG number", dlgNum)
					break
				}
			}
			
			if(!dlgNum)
				return
			
			Send, ^l
			WinWaitActive, Link DLG, , 5
			Send, % dlgNum
			Send, {Enter}
		}
	return
	
	::.snip::
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
			if(data["TYPE"] = "LOOP") {
				snipString := buildMLoop(data, numIndents)
			}
			
			sendTextWithClipboard(snipString) ; Better to send with the clipboard, otherwise we have to deal with EpicStudio adding in dot-levels itself.
		}
	
	
	;---------
	; DESCRIPTION:    Put the current location in code (tag^routine) onto the clipboard.
	; SIDE EFFECTS:   Shows a toast letting the user know what we put on the clipboard.
	;---------
	epicStudioCopyLinkedCodeLocation() {
		if(!epicStudioCopyCodeLocation())
			return
		
		; Notify the user of the new value.
		toastNewClipboardValue("linked code location")
	}
	
	;---------
	; DESCRIPTION:    Put the current location in code (tag^routine) onto the clipboard, stripping
	;                 off any offset ("+4" in "tag+4^routine") and the RTF link that EpicStudio adds.
	; SIDE EFFECTS:   Shows a toast letting the user know what we put on the clipboard.
	;---------
	epicStudioCopyCleanCodeLocation() {
		if(!epicStudioCopyCodeLocation())
			return
		
		codeLocation := clipboard
		
		; Initial value copied potentially has the offset (tag+<offsetNum>) included, strip it off.
		codeLocation := dropOffsetFromServerLocation(codeLocation)
		
		; Set the clipboard value to our new (plain-text, no link) code location and notify the user.
		setClipboardAndToastValue(codeLocation, "cleaned code location")
	}
	
	;---------
	; DESCRIPTION:    Copy the current code location (with offset and RTF link) from EpicStudio to
	;                 the clipboard.
	; RETURNS:        True if we got a code location on the clipboard, False otherwise.
	; SIDE EFFECTS:   Waits for the clipboard to contain the location, and shows an error toast if
	;                 it doesn't when we time out.
	;---------
	epicStudioCopyCodeLocation() {
		clipboard := "" ; Clear the clipboard so we can tell when we have the code location on it
		Send, ^{Numpad9} ; Hotkey to copy code location to clipboard
		ClipWait, 2 ; Wait for 2 seconds for the clipboard to contain the code location
		
		if(clipboard = "") {
			Toast.showError("Failed to get code location")
			return false
		}
		
		return true
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
			loopString .= buildMArrayLoop(data, numIndents)
		
		} else if(subType = "ID") {
			loopString .= buildMIdLoop(data, numIndents)
		
		} else if(subType = "DAT") {
			loopString .= buildMDatLoop(data, numIndents)
			
		} else if(subType = "ID_DAT") {
			loopString .= buildMIdLoop(data, numIndents)
			loopString .= buildMDatLoop(data, numIndents)
			
		} else if(subType = "INDEX_REG_VALUE") {
			loopString .= buildMIndexRegularValueLoop(data, numIndents)
			
		} else if(subType = "INDEX_REG_ID") {
			loopString .= buildMIndexRegularIDLoop(data, numIndents)
			
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
			loopString .= getMNewLinePlusIndent(numIndents)
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
		
		loopString .= getMNewLinePlusIndent(numIndents)
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
		
		loopString .= getMNewLinePlusIndent(numIndents)
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
		
		loopString .= getMNewLinePlusIndent(numIndents)
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
		
		loopString .= getMNewLinePlusIndent(numIndents)
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
	
#IfWinActive
