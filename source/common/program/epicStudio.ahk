#Include mSnippets.ahk
class EpicStudio {
	; #PUBLIC#

	;---------
	; DESCRIPTION:    Open the DLG found in the active window's title in EpicStudio.
	;---------
	openCurrentDLG() {
		record := EpicLib.getBestEMC2RecordFromText(WinGetActiveTitle())
		if(record.ini != "DLG" || record.id = "") {
			Toast.ShowError("Could not open DLG in EpicStudio", "Record ID was blank or was not a DLG ID")
			return
		}
		
		this.openDLG(record.id)
	}

	;---------
	; DESCRIPTION:    Open the given DLG in EpicStudio.
	; PARAMETERS:
	;  dlgId (I,REQ) - DLG ID
	;---------
	openDLG(dlgId) {
		if(!dlgId) {
			Toast.ShowError("Could not open DLG in EpicStudio", "DLG ID was blank")
			return
		}

		t := new Toast("Opening DLG in EpicStudio: " dlgId).show()
		
		new ActionObjectEpicStudio(dlgId, ActionObjectEpicStudio.DescriptorType_DLG).openEdit()
		WinWaitActive, % Config.windowInfo["EpicStudio"].titleString, , 10 ; 10-second timeout
		
		t.close()
	}

	
	; #INTERNAL#
	
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
	
	;---------
	; DESCRIPTION:    Select and copy the current line, then add it as the next line.
	;---------
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
		
		; If we got "routine^routine", just return "^routine".
		if(codeLocation.beforeString("^") = codeLocation.afterString("^"))
			codeLocation := "^" codeLocation.afterString("^")

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
		
		; While the RTF link is on the clipboard, it doesn't paste cleanly into places like OneNote, so
		; generate the link and do our newline-separated thing instead.
		location := clipboard
		link := new ActionObjectEpicStudio(location, ActionObjectEpicStudio.DescriptorType_Routine).getLink()
		locationAndLink := location.appendLine(link)
		
		; Set the clipboard value and notify the user.
		ClipboardLib.setAndToast(locationAndLink, "linked code location")
	}
	
	;---------
	; DESCRIPTION:    Link the current routine to the DLG currently open in EMC2.
	;---------
	linkRoutineToCurrentDLG() {
		record := EMC2.getCurrentRecord()
		if(record.ini != "DLG" || record.id = "")
			return
		
		Send, ^!l
		WinWaitActive, Link DLG, , 5
		Send, % record.id
		Send, {Enter 2}
	}

	;---------
	; DESCRIPTION:    Add a contact comment, but also include the REVISIONS: header.
	;---------
	insertContactCommentWithHeader() {
		; Figure out if we're already on a new line or if we need to insert one.
		Send, {End}{Home}                 ; Get to start of line (after indentation)
		Send, {Shift Down}{End}{Shift Up} ; Select line (not including indentation)
		line := SelectLib.getText().withoutWhitespace()
		
		; Non-empty line: add a new line and select it
		if(line != "" && line != ";") {
			Send, {End}{Enter}
			Send, {Shift Down}{Home}{Shift Up}
		}

		Send, `;
		Send, {Space}REVISIONS:{Enter}{Space}
		Send, ^8 ; Normal contact comment hotkey for EpicStudio
	}
	
	;---------
	; DESCRIPTION:    Wrap the current line in a top and bottom "border".
	; PARAMETERS:
	;  borderChar (I,REQ) - The character to use as the border (-, =, etc.)
	;---------
	wrapLineInCommentBorder(borderChar) {
		if(borderChar = "")
			return
		
		; Get the current line to determine the border's length
		Send, {End} ; Get to the end of the line, removing any selection
		line := SelectLib.getCleanFirstLine() ; Grab the line, ignore indentation
		if(line = "") {
			Toast.ShowError("Could not create border", "Could not get current line")
			return
		}
		if(!line.startsWith(";")) {
			Toast.ShowError("Could not create border", "Current line is not a comment")
			return
		}

		; Ask the user how wide they want the "box" to be
		width := InputBox("Enter comment box width", "How many characters wide do you want the borders to be?`n`nLeave blank to match (padded) width of text.")
		Sleep, 100 ; Make sure the InputBox has fully closed and EpicStudio has focus again.
		
		; Get content of line, re-indent as needed
		content := line.removeFromStart(";").withoutWhitespace()
		if(width = "") {
			width := content.length() + 2 ; 1 char of overhang on each side
			indent := " "
		} else {
			indent := StringLib.duplicate(" ", (width - content.length()) // 2)
		}
		newLine := ";" indent content
		
		; Generate border
		borderLine := ";" StringLib.duplicate(borderChar, width)
		
		; Generate new lines and replace the original
		newLines := borderLine "`n`t" newLine "`n`t" borderLine
		Send, {Shift Down}{Home}{Shift Up}
		ClipboardLib.send(newLines)
	}
	
	;---------
	; DESCRIPTION:    Run EpicStudio in debug mode, adding in a search to find my processes.
	;---------
	launchDebug() {
		; Don't do anything if we're already debugging (the F5 already passed thru).
		if(EpicStudio.isDebugging())
			return
		
		WinWaitActive, % WindowLib.buildTitleString("EpicStudio.exe", "", "Attach to Process")
		
		this.runDebugSearch(true)
	}
	
	;---------
	; DESCRIPTION:    Run a debug search to find relevant processes to attach to.
	; PARAMETERS:
	;  keepExistingValue (I,OPT) - Set to true to keep any existing search values (useful if there's a process ID in there we want to
	;                              reattach to, for example).
	;---------
	runDebugSearch(keepExistingValue := false) {
		; If the "other process" search field isn't enabled, select the corresponding radio button to enable it.
		filterField := EpicStudio.Debug_OtherProcessField
		if(!ControlGet("Enabled", "", filterField, "A"))
			ControlSend, % EpicStudio.Debug_OtherProcessButton, {Space}, A
		
		; Focus the search field (may already be focused, but we want a consistent starting point).
		ControlFocus, % filterField, A
		
		; Keep the existing value if requested (unless it's blank).
		currentFilter := ControlGet("Line", 1, filterField, "A")
		if(keepExistingValue && currentFilter != "") {
			ControlSend, % filterField, {Enter}, A
			return
		}

		; Otherwise, cycle thru our normal filters.
		filters := ["user:" Config.private["WORK_ID"], "user:" Config.private["WORK_USERNAME"]] ; Different environments use different values for whatever reason.
		currIndex := filters.contains(currentFilter)
		currIndex := DataLib.forceNumber(currIndex)
		newIndex := mod(currIndex, filters.Length()) + 1 ; Mod current index and add 1 after because the array is base-1.
		ControlSetText, % filterField, % filters[newIndex], A
		
		; Submit the search.
		ControlSend, % filterField, {Enter}, A
	}
	
	
	
	; #PRIVATE#
	
	; Debug window controls
	static Debug_OtherProcessButton := "WindowsForms10.BUTTON.app.0.141b42a_r7_ad12" ; "Other Process" radio button
	static Debug_OtherProcessField  := "Edit1" ; "Other Process" search field
	
	;---------
	; DESCRIPTION:    Determine whether EpicStudio is in debug mode right now.
	; RETURNS:        true if EpicStudio is in debug mode, false otherwise.
	;---------
	isDebugging() {
		isDebugging := false
		
		settings := new TempSettings()
		settings.titleMatchMode(TitleMatchMode.Contains)
		settings.titleMatchSpeed("Slow")
		
		; Match on text in the window for the main debugging targets
		if(WinActive("", Config.private["ES_PUTTY_EXE"]))
			isDebugging := true
		else if(WinActive("", Config.private["ES_HYPERSPACE_EXE"]))
			isDebugging := true
		else if(WinActive("", Config.private["ES_VB6_EXE"]))
			isDebugging := true
		
		settings.restore()
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
		
		Toast.ShowError("Failed to get code location")
		return false
	}
	; #END#
}
