class EMC2 {
	; #INTERNAL#
	
	;---------
	; DESCRIPTION:    Insert a specific SmartText in the current field.
	; PARAMETERS:
	;  smartTextName (I,REQ) - Name of the SmartText to insert. Should be part of the user's
	;                          favorites as we pick the first one with a matching name.
	; SIDE EFFECTS:   Focuses the first "field" in the SmartText after inserting.
	;---------
	insertSmartText(smartTextName) {
		Send, ^{F10}
		WinWaitActive, SmartText Lookup
		Sleep, 500
		SendRaw, % smartTextName
		Send, {Enter}
		Sleep, 500
		Send, {Enter}
		
		WinWaitClose, SmartText Lookup
		Sleep, 500 ; EMC2 takes a while to get back to ready.
		Send, {F2} ; Focus the first "field" in the SmartText.
	}
	
	;---------
	; DESCRIPTION:    Insert a specific SmartPhrase and select the first element in it.
	; PARAMETERS:
	;  phraseName (I,REQ) - The name of the phrase (to be sent with a . in front)
	;---------
	insertSmartPhrase(phraseName) {
		HotkeyLib.waitForRelease() ; Held-down keys mess with the SmartPhrase butler, so wait for them to be released first.
		Send, .%phraseName%{F2}    ; Insert the SmartPhrase, selecting the first field inside
	}
	
	;---------
	; DESCRIPTION:    Use the right-click menu to launch the currently-selected worklist item in web. Useful because we
	;                 don't have title information to pull from when we're in a worklist.
	;---------
	openCurrentWorklistItemWeb() {
		Send, {AppsKey} ; Right-click simulation
		Sleep, 100      ; Wait for right-click menu to appear
		Send, v{Enter}  ; "View * as HTML", "View *", or "View * in Browser" are all the first "V" item in the menu
		return
	}
	
	;---------
	; DESCRIPTION:    Open/focus the current DLG in EpicStudio.
	;---------
	openCurrentDLGInEpicStudio() {
		record := EpicLib.getBestEMC2RecordFromText(WinGetActiveTitle())
		if(record.ini != "DLG" || record.id = "")
			return
		
		t := new Toast("Opening DLG in EpicStudio: " record.id).show()
		new ActionObjectEpicStudio(record.id, ActionObjectEpicStudio.DescriptorType_DLG).openEdit()
		WinWaitActive, % Config.windowInfo["EpicStudio"].titleString, , 10 ; 10-second timeout
		t.close()
	}
	
	;---------
	; DESCRIPTION:    Run linting for the current DLG using MBuilder.
	;---------
	openCurrentDLGInMBuilder() {
		record := EpicLib.getBestEMC2RecordFromText(WinGetActiveTitle())
		if(record.ini != "DLG" || record.id = "")
			return
		
		t := new Toast("Opening DLG in MBuilder: " record.id).show()
		Config.runProgram("MBuilder")
		WinWaitActive, % Config.windowInfo["MBuilder"].titleString, , 10 ; 10-second timeout
		if(ErrorLevel != 1) {
			; Plug in the DLG ID.
			Send, 2{Enter} ; Check for errors on a DLG's Routines
			Sleep, 500
			Send, % record.id
			Send, {Enter}
		}
		t.close()
	}
	
	;---------
	; DESCRIPTION:    Send a list of DBC developer TLGs to a grid column (for emailing designs out for reviewers).
	;---------
	sendDBCDevIDs() {
		IDs := Config.private["WORK_DBC_IDS"].split(",")
		IDs.removeFirstInstanceOf(Config.private["WORK_ID"]) ; Don't include myself, don't need to email myself separately.
		
		For _,id in IDs {
			SendRaw, % id
			Send, {Enter}
		}
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Get an array of QAN IDs from the related QANs table on an EMC2 object.
	; RETURNS:        Array of QAN IDs.
	; NOTES:          This assumes that you're already in the first row of the related QANs table.
	;---------
	getRelatedQANsAry() {
		if(!Config.isWindowActive("EMC2"))
			return ""
		
		outAry := []
		Loop {
			; Select just the QAN ID
			Send, {End}
			Send, {Left}
			Send, {Ctrl Down}{Shift Down}
			Send, {Left}
			Send, {Ctrl Up}
			Send, {Right}
			Send, {Shift Up}
			
			qanId := SelectLib.getText()
			if(!qanId)
				Break
			
			; Get to next column for version
			Send, {Tab}
			version := SelectLib.getText()
			
			; Avoid duplicate entries (for multiple versions
			if(qanId != prevId)
				outAry.push(qanId)
			
			; Loop quit condition - same QAN again (table ends on last filled row), also same version
			if( (qanId = prevId) && (version = prevVersion) )
				Break
			prevId      := qanId
			prevVersion := version
			
			; Get back to the first column and go down a row.
			Send, +{Tab}
			Send, {Down}
		}
		
		return outAry
	}
	; #END#
}
