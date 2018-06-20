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
		insertEpicStudioSnippet() {
			; First, remove a semicolon if that's all that's on this line.
			Send, {Shift Down}{Left}{Shift Up}
			if(getSelectedText() = ";")
				Send, {Backspace} ; Start with no semicolon in front.
			else
				Send, {End}
			
			s := new Selector("epicStudioSnippets.tl")
			data := s.selectGui()
			
			loopString := ""
			numIndents := 0
			prevIterators := ""
			if(data["TYPE"] = "LOOP") {
				iteratorList := data["ITERATOR_LIST"]
				iteratorAry := strSplit(iteratorList, ",")
				
				if(data["SUBTYPE"] = "ARRAY_GLO") {
					arrayName := data["ARRAY_INI"]
					baseString := MainConfig.getPrivate("EPICSTUDIO_LOOP_ARRAY_BASE")
					
					for i,iterator in iteratorAry {
						loopString .= replaceTags(baseString, {"ARY_NAME":arrayName, "ITERATOR":iterator, "PREV_ITERATORS":prevIterators}) "`n"
						
						prevIterators .= iterator ","
						numIndents++
						
						loopString .= "`t" ; Tab on each new line in EpicStudio
						loopString .= multiplyString(". ", numIndents)
					}
					
				} else if(data["SUBTYPE"] = "ID") {
					ini := data["ARRAY_INI"]
					id  := iteratorAry[1]
					
					if(!id)
						id := stringLower(ini) "Id"
					
					loopString := replaceTags(MainConfig.getPrivate("EPICSTUDIO_LOOP_ID_BASE"), {"INI":ini, "ID":id}) "`n`t. "
					
				} else if(data["SUBTYPE"] = "DAT") {
					ini  := data["ARRAY_INI"]
					id   := iteratorAry[1]
					dat  := iteratorAry[2]
					item := data["ITEM"]
					
					if(!id) ; GDB TODO replace these using tags in default iterator variables?
						id := stringLower(ini) "Id"
					if(!dat)
						dat := stringLower(ini) "Dat"
					
					loopString := replaceTags(MainConfig.getPrivate("EPICSTUDIO_LOOP_DAT_BASE"), {"INI":ini, "ID":id, "DAT":dat, "ITEM":item}) "`n`t. "
					
				} else if(data["SUBTYPE"] = "ID_DAT") {
					ini  := data["ARRAY_INI"]
					id   := iteratorAry[1]
					dat  := iteratorAry[2]
					item := data["ITEM"]
					
					if(!id) ; GDB TODO replace these using tags in default iterator variables?
						id := stringLower(ini) "Id"
					if(!dat)
						dat := stringLower(ini) "Dat"
					
					loopString := replaceTags(MainConfig.getPrivate("EPICSTUDIO_LOOP_ID_BASE"), {"INI":ini, "ID":id}) "`n`t. "
					loopString .= replaceTags(MainConfig.getPrivate("EPICSTUDIO_LOOP_DAT_BASE"), {"INI":ini, "ID":id, "DAT":dat, "ITEM":item}) "`n`t. . " ; GDB TODO turn dots into a loop with recursive function or something?
					
				} else if(data["SUBTYPE"] = "INI") {
					ini := iteratorAry[1]
					
					if(!ini)
						ini := "ini"
					
					loopString := replaceTags(MainConfig.getPrivate("EPICSTUDIO_LOOP_INI_BASE"), {"INI":ini}) "`n`t. "
					
				} else if(data["SUBTYPE"] = "ITEM") {
					ini  := iteratorAry[1]
					item := iteratorAry[2]
					
					if(!ini)
						ini := "ini"
					if(!item)
						item := "item"
					
					loopString := replaceTags(MainConfig.getPrivate("EPICSTUDIO_LOOP_ITEM_BASE"), {"INI":ini, "ITEM":item}) "`n`t. "
					
				} else if(data["SUBTYPE"] = "INI_ITEM") {
					ini  := iteratorAry[1]
					item := iteratorAry[2]
					
					if(!ini)
						ini := "ini"
					if(!item)
						item := "item"
					
					loopString := replaceTags(MainConfig.getPrivate("EPICSTUDIO_LOOP_INI_BASE"), {"INI":ini}) "`n`t. "
					loopString .= replaceTags(MainConfig.getPrivate("EPICSTUDIO_LOOP_ITEM_BASE"), {"INI":ini, "ITEM":item}) "`n`t. . "
					
				}
			}
			
			; DEBUG.popup("Data",data, "Loop string",loopString)
			sendTextWithClipboard(loopString)
		}
#IfWinActive
