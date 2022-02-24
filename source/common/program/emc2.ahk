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
	; DESCRIPTION:    Get an EpicRecord instance representing the record currently open in EMC2.
	; RETURNS:        EpicRecord instance, or "" if one not found.
	;---------
	getCurrentRecord() {
		title := Config.windowInfo["EMC2"].getCurrTitle()
		title := title.removeFromEnd(" - EMC2")
		
		; If no info available, bail.
		if(title = "EMC2")
			return ""
		
		matches := EpicLib.extractEMC2RecordsFromTitle(title)
		return matches[1] ; Assume there's only 1, exact match.
	}
	
	;---------
	; DESCRIPTION:    Copy the INI + ID of the currently open record to the clipboard.
	;---------
	copyCurrentRecord() {
		record := this.getCurrentRecord()
		if(record.id)
			ClipboardLib.setAndToast(record.id, "EMC2 " record.ini " ID")
	}
	
	;---------
	; DESCRIPTION:    Open the current record in web mode.
	;---------
	openCurrentRecordWeb() {
		; Special case for worklist - use right-click menu as we don't have any info in the title for the selected row
		if(Config.findWindowName("A") = "EMC2 Worklist") {
			Send, {AppsKey} ; Right-click simulation
			Sleep, 100      ; Wait for right-click menu to appear
			Send, v{Enter}  ; "View * as HTML", "View *", or "View * in Browser" are all the first "V" item in the menu
			return
		}
		
		record := this.getCurrentRecord()
		new ActionObjectEMC2(record.id, record.ini).openWeb()
	}
	
	;---------
	; DESCRIPTION:    Open the current record in "basic" web mode (emc2summary, even for
	;                 Nova/Sherlock objects).
	;---------
	openCurrentRecordWebBasic() {
		record := this.getCurrentRecord()
		new ActionObjectEMC2(record.id, record.ini).openWebBasic()
	}
	
	;---------
	; DESCRIPTION:    Open/focus the current DLG in EpicStudio.
	;---------
	openCurrentDLGInEpicStudio() {
		record := this.getCurrentRecord()
		if(record.ini != "DLG" || record.id = "")
			return
		
		t := new Toast("Opening DLG in EpicStudio: " record.id).show()
		
		new ActionObjectEpicStudio(record.id, ActionObjectEpicStudio.DescriptorType_DLG).openEdit()
		
		WinWaitActive, % Config.windowInfo["EpicStudio"].titleString, , 10 ; 10-second timeout
		t.close()
	}
	
	;---------
	; DESCRIPTION:    Open all related QANs from an ARD/ERD in EMC2.
	; NOTES:          Assumes you're starting at the top-left of the table of QANs.
	;---------
	openRelatedQANsFromTable() {
		Send, {Tab} ; Reset field since they just typed over it.
		Send, +{Tab}
		
		relatedQANsAry := EMC2.getRelatedQANsAry()
		; Debug.popup("QANs found", relatedQANsAry)
		
		urlsAry := []
		For _,qan in relatedQANsAry {
			link := new ActionObjectEMC2(qan, "QAN").getLinkWeb()
			if(link)
				urlsAry.push(link)
		}
		; Debug.popup("URLs", urlsAry)
		
		numQANs := relatedQANsAry.length()
		if(numQANs > 10) {
			MsgBox, 4, Many QANs, We found %numQANs% QANs. Are you sure you want to open them all?
			IfMsgBox, No
				return
		}
		
		For i,url in urlsAry
			if(url)
				Run(url)
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
