; Main Snapper window
#If MainConfig.isWindowActive("Snapper")
	; Send string of items to ignore, based on the given INI.
	::.hide::
	::.ignore::
		Snapper.sendItemsToIgnore()
	return
#If

; Add record window
#If WinActive("Add a Record " MainConfig.windowInfo["Snapper"].titleString)
	^Enter::Snapper.addMultipleRecordsFromAddPopup()
#If

class Snapper {

; ==============================
; == Public ====================
; ==============================
	;---------
	; DESCRIPTION:    Send the text needed to ignore items that I've deemed unimportant (according
	;                 to snapperIgnoreItems.tls) to Snapper and apply.
	;---------
	sendItemsToIgnore() {
		s := new Selector("snapperIgnoreItems.tls")
		itemsList := s.selectGui("STATUS_ITEMS")
		if(!itemsList)
			return
		
		itemsAry := itemsList.split(",")
		For i,item in itemsAry {
			if(i > 1)
				excludeItemsString .= ","
			excludeItemsString .= "-" item
		}
		
		Send, % excludeItemsString
		Send, {Enter}
	}
	
	;---------
	; DESCRIPTION:    In the add records popup, a user can enter comma-separated IDs and this will
	;                 read them out, close the window and launch them all.
	;---------
	addMultipleRecordsFromAddPopup() {
		url := Snapper.getURLFromAddRecordPopup()
		if(url) {
			Send, !c ; Close add record popup (can't use WinClose as that triggers validation on ID field)
			WinWaitActive, Snapper
			Run(url)
		} else {
			Send, {Enter}
		}
	}

	;---------
	; DESCRIPTION:    Build a URL that will open something in Snapper.
	; PARAMETERS:
	;  environment (I,OPT) - COMMID of the environment to get a URL for. If not given, we'll try to
	;                        default from whatever's currently selected in Snapper.
	;  ini         (I,OPT) - INI of the record(s) to launch. If this or idList is blank, both will
	;                        be set to "X", which will show an error popup, but still connect
	;                        Snapper to the chosen right environment.
	;  idList      (I,OPT) - Comma-separated list of record IDs (or colon-separated ranges of IDs)
	;                        to launch. If blank, both ini and idList will be treated as "X" as
	;                        described above.
	; RETURNS:        URL to launch Snapper.
	;---------
	buildURL(environment := "", ini := "", idList := "") { ; idList is a comma-separated list of IDs
		if(!environment)
			environment := Snapper.getCurrentEnvironment() ; Try to default from what Snapper has open right now if no environment given.
		if(!environment)
			return ""
		
		if(!ini || !idList) { ; These aren't be parameter defaults in case of blank parameters (not simply not passed at all)
			ini    := "X"
			idList := "X"
		}
		
		outURL := MainConfig.private["SNAPPER_URL_BASE"]
		idAry := expandList(idList)
		if(idAry.count() > 10)
			if(!showConfirmationPopup("You're trying to open more than 10 records in Snapper - are you sure you want to continue?", "Opening many records in Snapper"))
				return ""
		
		For i,id in idAry {
			if(!id)
				Continue
			
			outURL .= ini "." id "." environment "/"
		}
		
		return outURL
	}
	
	
; ==============================
; == Private ===================
; ==============================
	;---------
	; DESCRIPTION:    Extract info from the main Snapper window and the Add Records popup to build a
	;                 URL to launch multiple records. The records are those listed (comma separated
	;                 IDs/ranges [colon-separated] of IDs) in the ID field.
	; RETURNS:        URL that will open the listed records in Snapper.
	;---------
	getURLFromAddRecordPopup() {
		commId := Snapper.getCurrentEnvironment()
		
		titleString := "Add a Record " MainConfig.windowInfo["Snapper"].titleString ; Add record popup
		ini    := ControlGetText("ThunderRT6TextBox1", titleString)
		idList := ControlGetText("ThunderRT6TextBox2", titleString)
		
		if(!commId || !ini || !idList)
			return ""
		
		return Snapper.buildURL(commId, ini, idList)
	}
	
	;---------
	; DESCRIPTION:    Retrieve the current environment selected in Snapper, based on its Environment
	;                 drop-down.
	; RETURNS:        COMMID of the current environment open in Snapper.
	;---------
	getCurrentEnvironment() {
		; Main Snapper window titleString
		titleString := "Snapper " MainConfig.windowInfo["Snapper"].titleString
		if(!WinExist(titleString))
			return ""
		
		environmentText := ControlGetText("ThunderRT6ComboBox2", titleString)
		commId := environmentText.firstBetweenStrings("[", "]")
		
		return commId
	}
}
