class Snapper {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Add a record to Snapper in the given environment.
	; PARAMETERS:
	;  environment (I,OPT) - COMMID of the environment to get a URL for. If not given, we'll try to default from whatever's
	;                        currently selected in Snapper.
	;  ini         (I,OPT) - INI of the record(s) to launch. If this or idList is blank, both will be set to "X", which will show
	;                        an error popup, but still connect Snapper to the chosen right environment.
	;  idList      (I,OPT) - Comma-separated list of record IDs (or colon-separated ranges of IDs) to launch. If blank, both ini
	;                        and idList will be treated as "X" as described above. Must be internal IDs, unless the string starts
	;                        with "#" (in which case it can be a name or external ID).
	;---------
	addRecords(environment := "", ini := "", idList := "") {
		if(idList.startsWith("#")) {
			this.addRecordWithSearch(environment, ini, idList.removeFromStart("#"))
			return
		}
		
		Run(this.buildURL(environment, ini, idList))
		
		; Handle error popup and mitigate by putting ID list on clipboard.
		errorTitleString := "ahk_exe SnapperHandler.exe" ; The error popup that appears when Snapper has popups open or whatnot so it failed to add the new records.
		WindowLib.waitAnyOfWindowsActive([Config.windowInfo["Snapper"].titleString, errorTitleString]) ; Wait on either Snapper or the error popup to become active
		if(WinActive(errorTitleString)) {
			Send, {Space} ; Close the error window
			ClipboardLib.setAndToastError(idList, "ID list", "Could not add records to Snapper", "Snapper claims to have popups open")
		}
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ INTERNAL ------------------------------
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
	;                        described above. Must be internal IDs.
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
	
	;---------
	; DESCRIPTION:    Add a record to Snapper by searching for it (external ID, name).
	; PARAMETERS:
	;  environment (I,OPT) - COMMID of the environment to get a URL for. If not given, we'll try to
	;                        default from whatever's currently selected in Snapper.
	;  ini         (I,REQ) - INI of the record(s) to launch.
	;  searchQuery (I,REQ) - The external ID of the record.
	;---------
	addRecordWithSearch(environment, ini, searchQuery) {
		; Connect to environment (also launches Snapper if it's not already open)
		Run(Snapper.buildURL(environment))
		
		; Close the "ini/id invalid" popup that comes from us using "X" for both.
		WinWaitActive, ahk_exe Snapper.exe ahk_class #32770
		WinClose, A
		WinWaitActive, % Config.windowInfo["Snapper"].titleString
		
		; Launch the add record popup
		Send, !n
		addWindowTitleString := Config.windowInfo["Snapper Add Records"].titleString
		WinWaitActive, % addWindowTitleString
		
		; Plug in the INI
		ControlSetText, ThunderRT6TextBox1, % ini, A
		Send, {Enter} ; Submit to enable Record (ID) field
		
		; Plug in the ID
		WindowLib.waitControlActive("ThunderRT6TextBox2")
		ControlSetText, ThunderRT6TextBox2, % searchQuery, A
		Send, {Enter} ; Submit/search
		
		; If we get a search popup, pick the first result (should be the exact match based on sort order).
		WindowLib.waitAnyOfWindowsActive([addWindowTitleString, "Record Select"])
		if(WinActive("Record Select"))
			Send, !a ; Accept the search popup
		
		; Accept the add record popup
		WindowLib.waitControlActive("ThunderRT6TextBox3")
		Send, !a ; Accept button
	}
	
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
		
		itemsAry := itemsList.split(",").removeEmpties()
		For i,item in itemsAry {
			if(i > 1)
				excludeItemsString .= ","
			excludeItemsString .= "-" item
		}
		
		Send, % excludeItemsString
		Send, {Enter}
	}
	
	;---------
	; DESCRIPTION:    Diff the selected multi-response item values using KDiff, stripping off line numbers and whitespace.
	;---------
	diffMultiResponseValues() {
		; Get input
		inputText := StringLib.dropLeadingTrailing(SelectLib.getText(), ["`r", "`n"]) ; Drop outer newlines
		if(inputText = "") {
			Toast.ShowError("No help text selected")
			return
		}
		
		; If the string starts with a DAT, strip it off (since we'll split the blocks on the next one we find)
		this.removeDatFromMultiResponseValues(inputText)
		; If the first line is a line 0, drop it entirely
		if(inputText.startsWith("0 "))
			inputText := inputText.afterString("`n")
		
		; Split into 2 blocks to diff
		leftLines  := []
		rightLines := []
		outLines := leftLines
		prevLineNum := 0
		For _,line in inputText.split("`n", "`r ") {
			; When we hit a DAT, drop it and swap to right block
			if(this.removeDatFromMultiResponseValues(line)) {
				outLines := rightLines
				prevLineNum := 0
				
				; Ignore the line if it's the (top) line 0 (otherwise let it through normally)
				if(line.startsWith("0 "))
					Continue
			}

			; Related-multi handling: sublevel line 0s (i.e. 3,0)
			if (line.matchesRegEx("\d,0")) {
				prevLineNum := 0 ; Reset the line counter
				Continue
			}
			
			; Line number handling
			lineLabel := line.beforeString(" ")
			lineNum := lineLabel.afterString(",") ; Handle comma for related-multi lines
			expectedNum := prevLineNum + 1
			if(lineNum > expectedNum) { ; Add lines to fill in gap
				Loop, % lineNum - expectedNum
					outLines.push("")
			}
			prevLineNum := lineNum
			; Remove line label (might include two numbers with a comma for related-multi)
			line := line.removeFromStart(lineLabel).removeFromStart(" ") ; Remove space separately in case it doesn't exist (happens with blank lines)
			
			; Replace Ascii-based newlines
			line := line.replace("<13><10>", "`n")
			
			outLines.push(line)
		}
		
		; Put the blocks in files and diff it
		pathLeft  := A_Temp "\ahkDiffLeft.txt"
		pathRight := A_Temp "\ahkDiffRight.txt"
		FileLib.replaceFileWithString(pathLeft,  leftLines.join("`n"))
		FileLib.replaceFileWithString(pathRight, rightLines.join("`n"))
		Config.runProgram("KDiff", pathLeft " " pathRight)
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
	;endregion ------------------------------ INTERNAL ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	static ClassNN_RecordList := "ListView20WndClass1" ; The control which holds the list of records.
	static ClassNN_ItemFilter := "ThunderRT6TextBox2"  ; The "Filter Items" field.
	
	;---------
	; DESCRIPTION:    Check whether the given multi-response item value starts with a DAT, and if it does trim it off.
	; PARAMETERS:
	;  text (IO,REQ) - The text to check and trim the DAT off of.
	; RETURNS:        true/false - did the text start with a DAT?
	;---------
	removeDatFromMultiResponseValues(ByRef text) {
		firstWord := text.beforeString(" ")
		if(firstWord.isDigits() && firstWord.length() = 5) {
			text := text.removeFromStart(firstWord " ")
			return true
		}
		
		return false
	}
	
	;---------
	; DESCRIPTION:    Extract info from the main Snapper window and the Add Records popup to build a
	;                 URL to launch multiple records. The records are those listed (comma separated
	;                 IDs/ranges [colon-separated] of IDs) in the ID field.
	; RETURNS:        URL that will open the listed records in Snapper.
	;---------
	getURLFromAddRecordPopup() {
		commId := Snapper.getCurrentEnvironment()
		
		titleString := Config.windowInfo["Snapper Add Records"].titleString
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
		if(!Config.windowInfo["Snapper"].exists())
			return ""
		
		environmentText := ControlGetText("ThunderRT6ComboBox2", titleString)
		commId := environmentText.firstBetweenStrings("[", "]")
		
		return commId
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
