class EMC2 {
	;region ------------------------------ INTERNAL ------------------------------
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
	;endregion ------------------------------ INTERNAL ------------------------------
}
