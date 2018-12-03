; EpicStudio hotkeys and helpers.
#IfWinActive, ahk_exe EpicStudio.exe
	; Better access to INTermediate code.
	!i::ControlSend, , ^+v
	
	; Make copy line location !c.
	!c::Send, ^{Numpad9}
	
	; ; Debug, auto-search for workstation ID.
	~F5::epicStudioDebug("ws:" MainConfig.getPrivate("WORK_COMPUTER_NAME"))
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
		texts := [MainConfig.getPrivate("ES_PUTTY_EXE"), MainConfig.getPrivate("ES_HYPERSPACE_EXE"), MainConfig.getPrivate("ES_VB6_EXE")]
		return isWindowInState("active", "", texts, 2, "Slow")
	}
	
	; Link routine to currently open (in object explorer tab) DLG.
	^+l::
		linkRoutineToCurrentDLG() {
			text := WinGetText()
			; DEBUG.popup("Window Text", text)
			
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
			
			sendTextWithClipboard(snipString)
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
		}
		
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate nested M for loops using the given data.
	; PARAMETERS:
	;  data        (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          data["ARRAY_OR_INI"] - The name of the array or global (with @s around it)
	;                              ["ITERATORS"]    - Comma-delimited list of iterator variables to loop with.
	;  numIndents (IO,OPT) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMArrayLoop(data, ByRef numIndents := 0) {			
		arrayName   := data["ARRAY_OR_INI"]
		iteratorAry := strSplit(data["ITERATORS"], ",")
		
		prevIterators := ""
		for i,iterator in iteratorAry {
			loopString .= replaceTags(MainConfig.getPrivate("M_LOOP_ARRAY_BASE"), {"ARRAY_NAME":arrayName, "ITERATOR":iterator, "PREV_ITERATORS":prevIterators})
			
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
		loopString := replaceTags(MainConfig.getPrivate("M_LOOP_ID_BASE"), {"INI":ini, "ID_VAR":idVar})
		
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
		loopString := replaceTags(MainConfig.getPrivate("M_LOOP_DAT_BASE"), {"INI":ini, "ID_VAR":idVar, "DAT_VAR":datVar, "ITEM":""})
		
		loopString .= getMNewLinePlusIndent(numIndents)
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over IDs, then DATs, using the given data.
	; PARAMETERS:
	;  data        (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          data["ARRAY_OR_INI"] - The INI of the records to loop through
	;  numIndents (IO,OPT) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	getMNewLinePlusIndent(ByRef currNumIndents := 0) {
		outString := "`n`t" ; New line + tab (at the start of every line)
		
		; Increase indentation level and add indentation
		currNumIndents++
		outString .= multiplyString(". ", currNumIndents)
		
		return outString
	}
	
#IfWinActive
