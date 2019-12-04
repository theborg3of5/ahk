; Change code formatting hotkey to something more universal in various windows.
#If Config.isWindowActive("EMC2") || Config.isWindowActive("EMC2 DLG/XDS Issue Popup") || Config.isWindowActive("EMC2 QAN Notes") || Config.isWindowActive("EMC2 DRN Quick Review") || Config.isWindowActive("EMC2 XDS Magnify")
	^+c::Send, ^e
#If

; Main EMC2 window
#If Config.isWindowActive("EMC2")
	^h::Send, ^7     ; Make ^h for server object, similar to ^g for client object.
	^+8::Send, !o    ; Contact comment, EpicStudio-style.
	$F5::+F5         ; Make F5 work everywhere by mapping it to shift + F5.
	^+t::return      ; Block ^+t login from Hyperspace - it does very strange zoom-in things and other nonsense.
	
	; Link and record number things based on the current record.
	!c:: EMC2.copyCurrentRecord()          ; Get INI/ID
	!w:: EMC2.openCurrentRecordWeb()       ; Open web version of the current object.
	!+w::EMC2.openCurrentRecordWebBasic()  ; Open "basic" web version (always EMC2 summary, even for Sherlock/Nova records) of the current object.
	^+o::EMC2.openCurrentDLGInEpicStudio() ; Take DLG # and pop up the DLG in EpicStudio sidebar.
	
	; SmartText hotstrings. Added to favorites to deal with duplicate/similar names.
	:X:qa.dbc::EMC2.insertSmartText("DBC QA INSTRUCTIONS")
	:X:qa.sdbc::EMC2.insertSmartText("DBC SIMPLE AND STRAIGHTFORWARD QA INSTRUCTIONS")
	:X:qa.new::EMC2.insertSmartText("QA INSTRUCTIONS - NEW CHANGES")
	
	:X:openall::EMC2.openRelatedQANsFromTable() ; Open all related QANs from an object in EMC2.
#If

; Design open
#If Config.isWindowActive("EMC2 XDS")
	; Disable Ctrl+Up/Down hotkeys, never hit these intentionally.
	^Down::return
	^Up::  return
#If

; Lock/unlock hotkeys by INI
#If Config.isWindowActive("EMC2 QAN") || Config.isWindowActive("EMC2 XDS")
	^l::Send, !l
#If Config.isWindowActive("EMC2 DLG")
	^l::Send, !+{F5}
#If


class EMC2 {
	; #PUBLIC#
	
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
		SendRaw, %smartTextName%
		Send, {Enter}
		Sleep, 500
		Send, {Enter}
		
		WinWaitClose, SmartText Lookup
		Sleep, 500 ; EMC2 takes a while to get back to ready.
		Send, {F2} ; Focus the first "field" in the SmartText.
	}
	
	;---------
	; DESCRIPTION:    Copy the INI + ID of the currently open record to the clipboard.
	;---------
	copyCurrentRecord() {
		record := new EpicRecord().initFromEMC2Title()
		if(record.id)
			ClipboardLib.setAndToast(record.ini " " record.id, "EMC2 record INI/ID")
	}
	
	;---------
	; DESCRIPTION:    Open the current record in web mode.
	;---------
	openCurrentRecordWeb() {
		record := new EpicRecord().initFromEMC2Title()
		new ActionObjectEMC2(record.id, record.ini).openWeb()
	}
	
	;---------
	; DESCRIPTION:    Open the current record in "basic" web mode (emc2summary, even for
	;                 Nova/Sherlock objects).
	;---------
	openCurrentRecordWebBasic() {
		record := new EpicRecord().initFromEMC2Title()
		new ActionObjectEMC2(record.id, record.ini).openWebBasic()
	}
	
	;---------
	; DESCRIPTION:    Open/focus the current DLG in EpicStudio.
	;---------
	openCurrentDLGInEpicStudio() {
		record := new EpicRecord().initFromEMC2Title()
		if(record.ini != "DLG" || record.id = "")
			return
		
		new Toast("Opening DLG in EpicStudio: " record.id).showMedium()
		
		new ActionObjectEpicStudio(record.id, ActionObjectEpicStudio.DescriptorType_DLG).openEdit()
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
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Get an array of QAN IDs from the related QANs table on an EMC2 object.
	; RETURNS:        Array of QAN IDs.
	; SIDE EFFECTS:   
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
