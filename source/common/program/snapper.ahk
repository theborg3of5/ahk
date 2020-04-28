﻿class Snapper {
	; #PUBLIC#
	
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
		
		outURL := Config.private["SNAPPER_URL_BASE"]
		idAry := DataLib.expandList(idList)
		if(idAry.count() > 10)
			if(!GuiLib.showConfirmationPopup("You're trying to open more than 10 records in Snapper - are you sure you want to continue?", "Opening many records in Snapper"))
				return ""
		
		For i,id in idAry {
			if(!id)
				Continue
			
			outURL .= ini "." id "." environment "/"
		}
		
		return outURL
	}
	
	
	; #INTERNAL#
	
	;---------
	; DESCRIPTION:    Send the text needed to ignore items that I've deemed unimportant (according
	;                 to snapperIgnoreItems.tls) to Snapper and apply.
	;---------
	sendItemsToIgnore() {
		; First, try to get the INI of the record ourselves.
		ControlFocus, % Snapper.ClassNN_RecordList, A ; Focus the record list so we can copy from it to get the INI.
		recordText := SelectLib.getText()
		ini := recordText.sub(1, 3)
		ControlFocus, % Snapper.ClassNN_ItemFilter, A ; Put focus back on the item filter field
		
		itemsList := new Selector("snapperIgnoreItems.tls").select(ini, "STATUS_ITEMS")
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
	
	
	; #PRIVATE#
	
	static ClassNN_RecordList := "ListView20WndClass1" ; The control which holds the list of records.
	static ClassNN_ItemFilter := "ThunderRT6TextBox2"  ; The "Filter Items" field.
	
	;---------
	; DESCRIPTION:    Extract info from the main Snapper window and the Add Records popup to build a
	;                 URL to launch multiple records. The records are those listed (comma separated
	;                 IDs/ranges [colon-separated] of IDs) in the ID field.
	; RETURNS:        URL that will open the listed records in Snapper.
	;---------
	getURLFromAddRecordPopup() {
		commId := Snapper.getCurrentEnvironment()
		
		titleString := "Add a Record " Config.windowInfo["Snapper"].titleString ; Add record popup
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
		titleString := "Snapper " Config.windowInfo["Snapper"].titleString
		if(!WinExist(titleString))
			return ""
		
		environmentText := ControlGetText("ThunderRT6ComboBox2", titleString)
		commId := environmentText.firstBetweenStrings("[", "]")
		
		return commId
	}
	; #END#
}