; Check for EMC2 title since it overlaps window classes and such with Hyperspace.
#If exeActive("EpicD82.exe") && isWindowInState("active", " - EMC2", , 2)
	; Make F5 work everywhere by mapping it to shift + F5.
	$F5::+F5
	
	; TLG Hotkey.
	^t::
		Send, %epicID%
	return
	
	; Make ^h for server object, similar to ^g for client object.
	^h::
		Send, ^7
	return
	
	; Contact comment, EpicStudio-style.
	^+8::
		Send, !o
	return
	
	; Change code formatting hotkey to something more universal.
	^+c::
		Send, ^e
	return
	
	{ ; SmartText hotstrings. Added to favorites to deal with duplicate/similar names.
		; QA Instructions: DBC QA INSTRUCTIONS
		:*:qa.dbc::
			insertSmartText("DBC QA INSTRUCTIONS")
		return
		:*:qa.new::
			insertSmartText("QA INSTRUCTIONS - NEW CHANGES")
		return
	}
	
	{ ; Link and record number things.
		; Get DLG number from title.
		!c::
			copyEMC2RecordId() {
				getEMC2Info( , id)
				if(id)
					clipboard := id
			}
		
		; Open web version of the current object in EMC2.
		!w::
			openEMC2RecordWeb() {
				getEMC2Info(ini, id)
				ActionObject.do(id, TYPE_EMC2, ACTION_Run, ini, SUBACTION_Web)
			}
		
		; Take DLG # and pop up the DLG in EpicStudio sidebar.
		^+o::
			openEMC2EpicStudioDLG() {
				getEMC2Info(ini, id)
				if(ini = "DLG" && id)
					openEpicStudioDLG(id)
			}
	}
	
	; Open all related QANs from an object in EMC2.
	::openall::
		openRelatedQANs() {
			Send, {Up}  ; Get back to first row in case they hit enter to submit this.
			Send, {Tab} ; Reset field if they didn't hit enter.
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
					Run, % url
		}
#If

; Design open
#If exeActive("EpicD82.exe") && WinActive("XDS ")
	^k::
		clickUsingMode(515, 226, "Client")
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

insertSmartText(smartTextName, focusFirstField = true) {
	Send, ^{F10}
	WinWait, SmartText Selection
	SendRaw, %smartTextName%
	Send, {Enter 2}
	
	WinWaitClose, SmartText Selection
	Sleep, 500 ; EMC2 takes a while to get back to ready.
	if(focusFirstField)
		Send, {F2}
}
