; EpicStudio hotkeys and helpers.
#IfWinActive, ahk_exe EpicStudio.exe
	; Better access to INTermediate code.
	!i::ControlSend, , ^+v
	
	; Make copy line location !c.
	!c::Send, ^!{Numpad9}
	
	; ; Debug, auto-search for workstation ID.
	~F5::
		epicStudioDebug() {
			if(isESDebugging())
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
			otherProcessRadioButtonClass := WindowsForms10.BUTTON.app.0.2bf8098_r9_ad11
			ControlFocus, %otherProcessRadioButtonClass%, A
			ControlSend, %otherProcessRadioButtonClass%, {Space}, A
			
			; Focus the filter field and send what we want to send.
			ControlFocus, Edit1, A
			Send, % "ws:" MainConfig.getPrivate("WORK_COMPUTER_NAME")
			Send, {Enter}{Down}
		}
	
	; Run EpicStudio in debug mode, given a particular string to search for.
	esRunDebug(searchString) {
		; Always send F5, even in debug mode - continue.
		Send, {F5}
		
		; Don't try and debug again if ES is already doing so.
		if(!isESDebugging()) {
			WinWait, Attach to Process, , 5
			if(!ErrorLevel) {
				currFilter := ControlGet("Line", 1, "Edit1", "A")
				if(!currFilter) {
					ControlFocus, WindowsForms10.BUTTON.app.0.141b42a_r12_ad11, A
					ControlSend, WindowsForms10.BUTTON.app.0.141b42a_r12_ad11, {Space}, A
					ControlFocus, Edit1, A
					
					Send, % "ws:" MainConfig.getPrivate("WORK_COMPUTER_NAME")
					Send, {Enter}{Down}
				}
			} else {
				; DEBUG.popup("ES Debug WinWait ErrorLevel", ErrorLevel)
			}
		
		}
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
			; First, remove a semicolon if that's all that's on this line.
			Send, {Shift Down}{Left}{Shift Up}
			if(getSelectedText() = ";")
				Send, {Backspace} ; Start with no semicolon in front.
			else
				Send, {End}
			
			; Determine how indented we are to start with
			numIndents := 0 ; GDB TODO
			
			s := new Selector("MSnippets.tl")
			data := s.selectGui()
			
			type := data["TYPE"]
			if(data["TYPE"] = "LOOP") {
				snipString := buildMLoop(data, numIndents)
			}
			
			sendTextWithClipboard(snipString)
		}
	
	buildMLoop(data, numIndents := 0) {
		snipString := ""
		
		subType := data["SUBTYPE"]
		if(subType = "ARRAY_GLO") {
			snipString .= buildMArrayLoop(data)
		
		} else if(subType = "ID") {
			snipString .= buildMIdLoop(data)
		
		} else if(subType = "DAT") {
			snipString .= buildMDatLoop(data)
			
		} else if(subType = "ID_DAT") {
			snipString .= buildMIdLoop(data, numIndents)
			snipString .= buildMDatLoop(data, numIndents)
		}
		
		return snipString
	}
	
	buildMArrayLoop(data, ByRef numIndents := 0) {			
		arrayName   := data["ARRAY_OR_INI"]
		iteratorAry := strSplit(data["ITERATORS"], ",")
		
		prevIterators := ""
		for i,iterator in iteratorAry {
			loopString .= replaceTags(MainConfig.getPrivate("M_LOOP_ARRAY_BASE"), {"ARRAY_NAME":arrayName, "ITERATOR":iterator, "PREV_ITERATORS":prevIterators})
			
			prevIterators .= iterator ","
			loopString .= getMNewLineAndIndent(numIndents)
		}
		
		return loopString
	}
	
	buildMIdLoop(data, ByRef numIndents := 0) {
		ini := stringUpper(data["ARRAY_OR_INI"])		
		
		idVar := stringLower(ini) "Id"
		loopString := replaceTags(MainConfig.getPrivate("M_LOOP_ID_BASE"), {"INI":ini, "ID_VAR":idVar})
		
		loopString .= getMNewLineAndIndent(numIndents)
		return loopString
	}
	
	buildMDatLoop(data, ByRef numIndents := 0) {
		ini := stringUpper(data["ARRAY_OR_INI"])		
		
		idVar  := stringLower(ini) "Id"
		datVar := stringLower(ini) "Dat"
		loopString := replaceTags(MainConfig.getPrivate("M_LOOP_DAT_BASE"), {"INI":ini, "ID_VAR":idVar, "DAT_VAR":datVar, "ITEM":""})
		
		loopString .= getMNewLineAndIndent(numIndents)
		return loopString
	}
	
	getMNewLineAndIndent(ByRef numIndents := 0) {
		numIndents++
		return "`n`t" multiplyString(". ", numIndents) ; Newline + tab on each new line + indentation
	}
	
#IfWinActive
