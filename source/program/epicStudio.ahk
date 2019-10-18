; EpicStudio hotkeys and helpers.
#If Config.isWindowActive("EpicStudio")
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
	:X:.snip::MSnippets.insertMSnippet()
	
	; Debug, auto-search for workstation ID.
	~F5::EpicStudio.runDebug("ws:" Config.private["WORK_COMPUTER_NAME"])
	F6:: EpicStudio.runDebug("ws:" A_IPAddress1)
#If

class EpicStudio {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	; Debug window controls
	static Debug_OtherProcessButton := "WindowsForms10.BUTTON.app.0.141b42a_r9_ad11" ; "Other Process" radio button
	static Debug_OtherProcessField  := "Edit1" ; "Other Process" search field
	
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
		Send, {End}                        ; Start from end of line
		Send, {Shift Down}{Home}{Shift Up} ; Select whole line (excluding leading indentation/tab/etc.)
		line := SelectLib.getText()        ; Get selected text
		Send, {End}                        ; Get back to end of line
		Send, {Enter}                      ; Start new line with same indentation
		ClipboardLib.send(line)            ; Send duplicate line
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
		codeLocation := EpicLib.dropOffsetFromServerLocation(codeLocation)
		
		; Set the clipboard value to our new (plain-text, no link) code location and notify the user.
		ClipboardLib.setAndToast(codeLocation, "cleaned code location")
	}
	
	;---------
	; DESCRIPTION:    Put the current location in code (tag^routine) onto the clipboard.
	; SIDE EFFECTS:   Shows a toast letting the user know what we put on the clipboard.
	;---------
	copyLinkedCodeLocation() {
		if(!EpicStudio.copyCodeLocation())
			return
		
		; Notify the user of the new value.
		ClipboardLib.toastNewValue("linked code location")
	}
	
	;---------
	; DESCRIPTION:    Link the current routine to the DLG currently open in EMC2.
	;---------
	linkRoutineToCurrentDLG() {
		record := new EpicRecord()
		record.initFromEMC2Title()
		if(record.ini != "DLG" || record.id = "")
			return
		
		Send, ^!l
		WinWaitActive, Link DLG, , 5
		Send, % record.id
		Send, {Enter 2}
	}
	
	;---------
	; DESCRIPTION:    Run EpicStudio in debug mode, or continue debugging if we're already in it.
	; PARAMETERS:
	;  searchString (I,REQ) - String to automatically search for in the attach process popup
	;---------
	runDebug(searchString) {
		; Don't try and debug again if ES is already doing so.
		if(EpicStudio.isDebugging())
			return
		
		WinWait, Attach to Process, , 5
		if(ErrorLevel)
			return
		
		currFilter := ControlGet("Line", 1, EpicStudio.Debug_OtherProcessField, "A")
		if(currFilter) {
			ControlFocus, % EpicStudio.Debug_OtherProcessField, A
			return ; There's already something plugged into the field, so just put the focus there in case they want to change it.
		}
		
		; Pick the radio button for "Other existing process:".
		ControlFocus, % EpicStudio.Debug_OtherProcessButton, A
		ControlSend, % EpicStudio.Debug_OtherProcessButton, {Space}, A
		
		; Focus the filter field and send what we want to send.
		ControlFocus, % EpicStudio.Debug_OtherProcessField, A
		Send, % searchString
		Send, {Enter}{Down}
	}
	
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Determine whether EpicStudio is in debug mode right now.
	; RETURNS:        true if EpicStudio is in debug mode, false otherwise.
	;---------
	isDebugging() {
		isDebugging := false
		
		origMatchMode  := setTitleMatchMode(TitleMatchMode.Contains)
		origMatchSpeed := setTitleMatchSpeed("Slow")
		
		; Match on text in the window for the main debugging targets
		winId := WinActive("", Config.private["ES_PUTTY_EXE"])
		if(!winId)
			winId := WinActive("", Config.private["ES_HYPERSPACE_EXE"])
		if(!winId)
			winId := WinActive("", Config.private["ES_VB6_EXE"])
		
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
		if(ClipboardLib.copyWithHotkey("^{Numpad9}")) ; Hotkey to copy code location to clipboard
			return true
		
		new ErrorToast("Failed to get code location").showMedium()
		return false
	}
}

/*
	Static class for inserting snippets of M code into EpicStudio.
*/
class MSnippets {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Generate and insert an M snippet.
	;---------
	insertMSnippet() {
		; Get current line for analysis.
		Send, {End}{Home 2}               ; Get to very start of line (before indentation)
		Send, {Shift Down}{End}{Shift Up} ; Select entire line (including indentation)
		line := SelectLib.getText()
		Send, {End}                       ; Get to end of line
		
		line := line.removeFromStart("`t") ; Tab at the start of every line
		
		numIndents := 0
		while(line.startsWith(". ")) {
			numIndents++
			line := line.removeFromStart(". ")
		}
		
		; If it's an empty line with just a semicolon, remove the semicolon.
		if(line = ";")
			Send, {Backspace}
		
		data := new Selector("MSnippets.tls").selectGui()
		
		if(data["TYPE"] = "LOOP")
			snipString := MSnippets.buildMLoop(data, numIndents)
		else if(data["TYPE"] = "LIST")
			snipString := MSnippets.buildList(data, numIndents)
		
		ClipboardLib.send(snipString) ; Better to send with the clipboard, otherwise we have to deal with EpicStudio adding in dot-levels itself.
	}
	
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Generate an M for loop with the given data.
	; PARAMETERS:
	;  data       (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          ["SUBTYPE"] - The type of loop this is.
	;  numIndents (I,REQ) - The starting indentation (so that the line after can be indented 1 more).
	; RETURNS:        String containing the generated for loop.
	;---------
	buildMLoop(data, numIndents) {
		loopString := ""
		
		if(data["SUBTYPE"] = "ARRAY_GLO") {
			loopString .= MSnippets.buildMArrayLoop(data, numIndents)
		
		} else if(data["SUBTYPE"] = "ID") {
			loopString .= MSnippets.buildMIdLoop(data, numIndents)
		
		} else if(data["SUBTYPE"] = "DAT") {
			loopString .= MSnippets.buildMDatLoop(data, numIndents)
			
		} else if(data["SUBTYPE"] = "ID_DAT") {
			loopString .= MSnippets.buildMIdLoop(data, numIndents)
			loopString .= MSnippets.buildMDatLoop(data, numIndents)
			
		} else if(data["SUBTYPE"] = "INDEX_REG_VALUE") {
			loopString .= MSnippets.buildMIndexRegularValueLoop(data, numIndents)
			
		} else if(data["SUBTYPE"] = "INDEX_REG_ID") {
			loopString .= MSnippets.buildMIndexRegularIDLoop(data, numIndents)
			
		}
		
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate code to populate an array in M with the given values.
	; PARAMETERS:
	;  data       (I,REQ) - Array of data needed to generate the list. Important subscripts:
	;                         ["ARRAY_OR_INI"]   - The name of the array to populate
	;                         ["VARS_OR_VALUES"] - The list of values to add to the array
	;  numIndents (I,REQ) - The starting indentation for the list.
	; RETURNS:        String containing the generated code.
	;---------
	buildList(data, numIndents) {
		if(data["SUBTYPE"] = "INDEX")
			return MSnippets.buildMListIndex(data, numIndents)
	}
	
	;---------
	; DESCRIPTION:    Generate nested M for loops using the given data.
	; PARAMETERS:
	;  data        (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          ["ARRAY_OR_INI"]   - The name of the array or global (with @s around it)
	;                          ["VARS_OR_VALUES"] - Comma-delimited list of iterator variables to loop with.
	;  numIndents (IO,REQ) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMArrayLoop(data, ByRef numIndents) {
		arrayName   := data["ARRAY_OR_INI"]
		iteratorAry := data["VARS_OR_VALUES"].split(",")
		
		if(arrayName.startsWith("@") && !arrayName.endsWith("@"))
			arrayName .= "@" ; End global references with the proper @ if they're not already.
		
		prevIterators := ""
		for i,iterator in iteratorAry {
			loopString .= Config.private["M_LOOP_ARRAY_BASE"].replaceTags({"ARRAY_NAME":arrayName, "ITERATOR":iterator, "PREV_ITERATORS":prevIterators})
			
			prevIterators .= iterator ","
			numIndents++
			loopString .= MSnippets.getMNewLinePlusIndent(numIndents)
		}
		
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over IDs using the given data.
	; PARAMETERS:
	;  data        (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          ["ARRAY_OR_INI"] - The INI of the records to loop through
	;  numIndents (IO,REQ) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMIdLoop(data, ByRef numIndents) {
		ini := stringUpper(data["ARRAY_OR_INI"])
		
		idVar := stringLower(ini) "Id"
		loopString := Config.private["M_LOOP_ID_BASE"].replaceTags({"INI":ini, "ID_VAR":idVar})
		
		numIndents++
		loopString .= MSnippets.getMNewLinePlusIndent(numIndents)
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over DATs using the given data.
	; PARAMETERS:
	;  data        (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          ["ARRAY_OR_INI"] - The INI of the records to loop through
	;  numIndents (IO,REQ) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMDatLoop(data, ByRef numIndents) {
		ini := stringUpper(data["ARRAY_OR_INI"])
		
		idVar  := stringLower(ini) "Id"
		datVar := stringLower(ini) "Dat"
		loopString := Config.private["M_LOOP_DAT_BASE"].replaceTags({"INI":ini, "ID_VAR":idVar, "DAT_VAR":datVar, "ITEM":""})
		
		numIndents++
		loopString .= MSnippets.getMNewLinePlusIndent(numIndents)
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over regular index values for the given data.
	; PARAMETERS:
	;  data        (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          ["ARRAY_OR_INI"]   - The INI of the records to loop through
	;                          ["VARS_OR_VALUES"] - The name of the iterator variable to use for values
	;  numIndents (IO,REQ) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMIndexRegularValueLoop(data, ByRef numIndents) {
		ini := stringUpper(data["ARRAY_OR_INI"])
		valueVar := data["VARS_OR_VALUES"]
		
		loopString := Config.private["M_LOOP_INDEX_REGULAR_NEXT_VALUE"].replaceTags({"INI":ini, "ITEM":"", "VALUE_VAR":valueVar})
		
		numIndents++
		loopString .= MSnippets.getMNewLinePlusIndent(numIndents)
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over regular index IDs with a particular value for the
	;                 given data.
	; PARAMETERS:
	;  data        (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          ["ARRAY_OR_INI"]   - The INI of the records to loop through
	;                          ["VARS_OR_VALUES"] - The name of the iterator variable to use for values
	;  numIndents (IO,REQ) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMIndexRegularIDLoop(data, ByRef numIndents) {
		ini := stringUpper(data["ARRAY_OR_INI"])
		valueVar := data["VARS_OR_VALUES"]
		
		idVar  := stringLower(ini) "Id"
		loopString := Config.private["M_LOOP_INDEX_REGULAR_NEXT_ID"].replaceTags({"INI":ini, "ITEM":"", "VALUE_VAR":valueVar, "ID_VAR":idVar})
		
		numIndents++
		loopString .= MSnippets.getMNewLinePlusIndent(numIndents)
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an indexed [ary(value)=""] array in M code.
	; PARAMETERS:
	;  data       (I,REQ) - Array of data needed to generate the list. Important subscripts:
	;                         ["ARRAY_OR_INI"]   - The name of the array to populate
	;                         ["VARS_OR_VALUES"] - The list of values to add to the array
	;  numIndents (I,REQ) - The starting indentation for the list.
	; RETURNS:        String for generated array
	;---------
	buildMListIndex(data, numIndents) {
		arrayName := data["ARRAY_OR_INI"]
		valueList := data["VARS_OR_VALUES"]
		
		listAry := new FormatList(valueList).getList(FormatList.Format_Array)
		
		newLine := MSnippets.getMNewLinePlusIndent(numIndents)
		lineBase := Config.private["M_LIST_ARRAY_INDEX"]
		
		listString := ""
		For _,value in listAry {
			line := lineBase.replaceTags({"ARRAY_NAME":arrayName, "VALUE":value})
			listString := listString.appendPiece(line, newLine)
		}
		
		return listString
	}
	
	;---------
	; DESCRIPTION:    Get the text for a new line in M code.
	; PARAMETERS:
	;  currNumIndents (I,REQ) - The number of indents on the current line.
	; RETURNS:        The string to start a new line with 1 indent more.
	;---------
	getMNewLinePlusIndent(currNumIndents) {
		outString := "`n`t" ; New line + tab (at the start of every line)
		
		; Add indentation
		outString .= StringLib.duplicate(". ", currNumIndents)
		
		return outString
	}
}