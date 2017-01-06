; Check for EMC2 title since it overlaps window classes and such with Hyperspace.
#If exeActive("EpicD82.exe") && isWindowInState("active", " - EMC2", , 2)
	; Make F5 work everywhere by mapping it to shift + F5.
	$F5::+F5
	
	; TLG Hotkey.
	^t::
		Send, %epicID%
	return
	
	; Allow my ^s save reflex to live on. Return to the field we were in when we finish.
	^s::
		ControlSend_Return("", "!s")
	return
	
	; Make ^h for server object, similar to ^g for client object.
	^h::
		Send, ^7
	return
	
	; Contact comment, EpicStudio-style.
	^+8::
		Send, !o
	return
	
	{ ; SmartText hotstrings. Added to favorites to deal with duplicate/similar names.
		; General Description: HB SU approval
		:*:hb.su::
			insertSmartText("HB DEVELOPMENT APPROVAL")
		return
		
		; Visible and Functional Changes: Design Development
		:*:hb.dd::
			insertSmartText("DESIGN DEVELOPMENT")
			
			; Insert design number and pick the "WHOLE design" option
			if(isNum(clipboard)) {
				Send, {F2}
				SendRaw, % clipboard
				Send, {F2}{Enter}
			}
		return
		
		; QA Instructions: HB QA Instructions
		:*:hb.qa::
			insertSmartText("HB QA INSTRUCTIONS")
		return
	}
	
	{ ; Link and record number things.
		; Get DLG number from title.
		^+c::
			getEMC2Info( , id)
			if(id)
				clipboard := id
		return
		
		; Open web version of the current object in EMC2.
		!w::
			getEMC2Info(ini, id)
			link := ActionObject.do(id, TYPE_EMC2, ACTION_LINK, ini, SUBACTION_WEB)
			if(link)
				Run, % link
		return
		
		; Take DLG # and pop up the DLG in EpicStudio sidebar.
		^+o::
			getEMC2Info(ini, id)
			if(ini = "DLG" && id)
				openEpicStudioDLG(id)
		return
	}
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

insertSmartText(smartTextName) {
	Send, ^{F10}
	WinWait, SmartText Selection
	SendRaw, %smartTextName%
	Send, {Enter 2}
}
