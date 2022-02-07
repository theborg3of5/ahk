#Include mSnippets.ahk
class EpicStudio {
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
		record := new EMC2Record().initFromEMC2Title()
		if(record.ini != "DLG" || record.id = "")
			return
		
		Send, ^!l
		WinWaitActive, Link DLG, , 5
		Send, % record.id
		Send, {Enter 2}
	}
	
	;---------
	; DESCRIPTION:    Open the current DLG in web.
	;---------
	openCurrentDLGWeb() {
		new ActionObjectEMC2(this.getCurrentDLG(), "DLG").openWeb()
	}
	
	;---------
	; DESCRIPTION:    Open the current DLG in EMC2.
	;---------
	openCurrentDLGEdit() {
		new ActionObjectEMC2(this.getCurrentDLG(), "DLG").openEdit()
	}
	
	;---------
	; DESCRIPTION:    Run EpicStudio in debug mode, or continue debugging if we're already in it.
	; PARAMETERS:
	;  searchStringKey (I,REQ) - A key describing which search string to automatically search for in
	;                            the attach process popup. See .doDebugSearch for options.
	;---------
	runDebug(searchStringKey) {
		; Don't try and debug again if ES is already doing so.
		if(EpicStudio.isDebugging())
			return
		
		WinWait, % Config.windowInfo["EpicStudio Attach to Process"].titleString, , 5
		if(ErrorLevel)
			return
		
		; Pick the radio button for "Other existing process:"
		ControlSend,  % EpicStudio.Debug_OtherProcessButton, {Space}, A
			
		; There's already something plugged into the field (like a specific process ID), just focus the field and leave it be.
		if(ControlGet("Line", 1, EpicStudio.Debug_OtherProcessField, "A")) {
			ControlFocus, % EpicStudio.Debug_OtherProcessField, A
			return
		}
		
		; Perform the search
		this.doDebugSearch(searchStringKey)
	}
	
	;---------
	; DESCRIPTION:    Generate a search string given a type, then search with it.
	; PARAMETERS:
	;  key (I,REQ) - A key describing the type of search string. Options: WORKSTATION, USER
	;---------
	doDebugSearch(key) {
		if(!key)
			return
		
		Switch key {
			Case "WORKSTATION":
				searchString := "ws:" Config.private["WORK_COMPUTER_NAME"]
			Case "USER":
				searchString := "user:" Config.private["WORK_USERNAME"]
		}
		if(!searchString)
			return
		
		Send, % searchString
		Send, {Enter} ; Submit search
	}
	
	
	; #PRIVATE#
	
	; Specific controls
	static ClassNN_MainEditor            := "WindowsForms10.Window.8.app.0.141b42a_r9_ad163" ; Primary edit pane
	static ClassNN_ObjectExplorerDLGEdit := "WindowsForms10.EDIT.app.0.141b42a_r9_ad13"      ; Object explorer DLG field
	
	; Debug window controls
	static Debug_OtherProcessButton := "WindowsForms10.BUTTON.app.0.141b42a_r7_ad12" ; "Other Process" radio button
	static Debug_OtherProcessField  := "Edit1" ; "Other Process" search field
	
	;---------
	; DESCRIPTION:    Determine the DLG that we're currently working in, pulling from different locations depending on
	;                 what's focused.
	; RETURNS:        DLG ID if found, otherwise ""
	;---------
	getCurrentDLG() {
		; If the editor is focused, prefer the DLG in the title (in case the Object Explorer DLG field is out of date).
		if(ControlGetFocus("A") = this.ClassNN_MainEditor) {
			dlgId := WinGetActiveTitle().firstBetweenStrings(" (DLG ",")")
			if(dlgId)
				return dlgId
		}
		
		; If the sidebar is focused or the title has no DLG, use DLG field at the bottom of Object Explorer.
		return ControlGetText(this.ClassNN_ObjectExplorerDLGEdit, "A").beforeString(" - ")
	}
	
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
		winId := WinActive("", Config.private["ES_PUTTY_EXE"])
		if(!winId)
			winId := WinActive("", Config.private["ES_HYPERSPACE_EXE"])
		if(!winId)
			winId := WinActive("", Config.private["ES_VB6_EXE"])
		
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
