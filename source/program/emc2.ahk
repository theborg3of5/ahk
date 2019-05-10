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
			insertSmartText("DBC QA INSTRUCTIONS")
		return
		:*:qa.new::
			insertSmartText("QA INSTRUCTIONS - NEW CHANGES")
		return
	}
	
	{ ; Link and record number things.
		; Get INI/ID
		!c::
			copyEMC2RecordId() {
				getObjectInfoFromEMC2(ini, id)
				if(id)
					setClipboardAndToastValue(ini " " id, "EMC2 record INI/ID")
			}
		
		; Open web version of the current object in EMC2.
		!w::
			openEMC2RecordWeb() {
				getObjectInfoFromEMC2(ini, id)
				ActionObject.do(id, TYPE_EMC2, ACTION_Run, ini, SUBACTION_Web)
			}
		
		; Take DLG # and pop up the DLG in EpicStudio sidebar.
		^+o::
			openEMC2EpicStudioDLG() {
				getObjectInfoFromEMC2(ini, id)
				if(ini != "DLG" || id = "")
					return
				
				url := buildEpicStudioDLGLink(id)
				if(url = "")
					return
				
				Toast.showMedium("Opening DLG in EpicStudio: " id)
				Run(url)
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

#If MainConfig.isWindowActive("EMC2 DLG/XDS Issue Popup") || MainConfig.isWindowActive("EMC2 QAN Notes")
	; Change code formatting hotkey to something more universal.
	^+c::
		Send, ^e
	return
#If

insertSmartText(smartTextName, focusFirstField = true) {
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