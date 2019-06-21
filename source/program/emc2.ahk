; Check for EMC2 title since it overlaps window classes and such with Hyperspace.
#If MainConfig.isWindowActive("EMC2")
	; Change code formatting hotkey to something more universal.
	^+c::
		Send, ^e
	return
	
	; Make F5 work everywhere by mapping it to shift + F5.
	$F5::+F5
	
	; Make ^h for server object, similar to ^g for client object.
	^h::
		Send, ^7
	return
	
	; Contact comment, EpicStudio-style.
	^+8::
		Send, !o
	return
	
	; Block ^+t login from Hyperspace - it does very strange zoom-in things and other nonsense.
	^+t::return
	
	{ ; SmartText hotstrings. Added to favorites to deal with duplicate/similar names.
		:*:qa.dbc::
			emc2InsertSmartText("DBC QA INSTRUCTIONS")
		return
		:*:qa.new::
			emc2InsertSmartText("QA INSTRUCTIONS - NEW CHANGES")
		return
	}
	
	{ ; Link and record number things.
		; Get INI/ID
		!c::
			emc2OpenRecordId() {
				record := new EpicRecord()
				record.initFromEMC2Title()
				
				if(record.id)
					setClipboardAndToastValue(record.ini " " record.id, "EMC2 record INI/ID")
			}
		
		; Open web version of the current object.
		!w::
			emc2OpenRecordWeb() {
				record := new EpicRecord()
				record.initFromEMC2Title()
				ao := new ActionObjectEMC2(record.id, record.ini)
				ao.openWeb()
			}
		
		; Open "basic" web version (always EMC2 summary, even for Sherlock/Nova records) of the current object.
		!+w::
			emc2OpenRecordWebBasic() {
				record := new EpicRecord()
				record.initFromEMC2Title()
				ao := new ActionObjectEMC2(record.id, record.ini)
				ao.openWebBasic()
			}
		
		; Take DLG # and pop up the DLG in EpicStudio sidebar.
		^+o::
			openEMC2EpicStudioDLG() {
				record := new EpicRecord()
				record.initFromEMC2Title()
				if(record.ini != "DLG" || record.id = "")
					return
				
				Toast.showMedium("Opening DLG in EpicStudio: " record.id)
				
				ao := new ActionObjectEpicStudio(record.id, ActionObjectEpicStudio.DescriptorType_DLG)
				ao.openEdit()
			}
	}
	
	; Open all related QANs from an object in EMC2.
	::openall::
		emc2OpenRelatedQANs() {
			Send, {Tab} ; Reset field since they just typed over it.
			Send, +{Tab}
			
			relatedQANsAry := getRelatedQANsAry()
			; DEBUG.popup("QANs found", relatedQANsAry)
			
			urlsAry := buildQANURLsAry(relatedQANsAry)
			; DEBUG.popup("URLs", urlsAry)
			
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
#If

; Design open
#If MainConfig.isWindowActive("EMC2 XDS")
	; Disable Ctrl+Up/Down hotkeys, never hit these intentionally.
	^Down::
	^Up::
	return
#If

; Log mover window
#IfWinActive, Move Server Objects
	; XSL merge message template.
	:*:xsl.merge::
		Send, Other{Tab 2}
		Send, XSL merge.{Enter}
		Send, {Space 3}State: {Enter}
		Send, {Space 3}Move:  ->{Space}
		Send, {Up}
	return
#IfWinActive

#If MainConfig.isWindowActive("EMC2 DLG/XDS Issue Popup") || MainConfig.isWindowActive("EMC2 QAN Notes") || MainConfig.isWindowActive("EMC2 DRN Quick Review")
	; Change code formatting hotkey to something more universal.
	^+c::
		Send, ^e
	return
#If

emc2InsertSmartText(smartTextName, focusFirstField = true) {
	Send, ^{F10}
	WinWaitActive, SmartText Lookup
	Sleep, 500
	SendRaw, %smartTextName%
	Send, {Enter}
	Sleep, 500
	Send, {Enter}
	
	WinWaitClose, SmartText Lookup
	Sleep, 500 ; EMC2 takes a while to get back to ready.
	if(focusFirstField)
		Send, {F2}
}