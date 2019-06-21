/* Class to represent a record in Epic.
	
	Example Usage
		***
	
*/

class EpicRecord {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	; Properties of the record.
	ini   := ""
	id    := ""
	title := ""
	
	; Constructed string representing the record.
	recordString {
		get {
			if(!this.selectMissingInfo())
				return ""
			if(this.title != "")
				return this.title " [R " this.ini " " this.id "]" ; "TITLE [R INI ID]"
			else
				return "R " this.ini " " this.id                  ; "R INI ID"
		}
	}
	
	
	__New(recordString := "") {
		if(recordString != "")
			this.initFromRecordString(recordString)
	}
	
	initFromRecordString(recordString) {
		if(recordString = "")
			return
		
		this.processRecordString(recordString)
	}
	
	initFromEMC2Title() {
		title := WinGetTitle(MainConfig.windowInfo["EMC2"].titleString)
		title := removeStringFromEnd(title, " - EMC2")
		
		; If no info available, bail.
		if(title = "EMC2")
			return
		
		this.initFromRecordString(title)
	}
	
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	
	processRecordString(recordString) {
		recordString := cleanupText(recordString) ; Clean any funky characters off of string edges
		if(recordString = "")
			return
		
		this.extractBitsFromString(recordString)
		; DEBUG.popup("recordString",recordString, "this",this)
	}
	
	extractBitsFromString(recordString) {
		; 1) Title [R INI ID]
		if(stringContains(recordString, "[R ") && stringContains(recordString, "]")) {
			; Title is everything up to the opening square bracket
			this.title := getStringBeforeStr(recordString, "[R ")
			
			; In the square brackets should be "R INI ID"
			iniId := getFirstStringBetweenStr(recordString, "[R ", "]")
			this.ini := getStringBeforeStr(iniId, " ")
			this.id  := getStringAfterStr(iniId, " ")
			
		; 2) #ID - Title
		} else if(stringStartsWith(recordString, "#")) {
			this.id := getFirstStringBetweenStr(recordString, "#", " - ")
			this.title := getStringAfterStr(recordString, " - ")
			
		; 3) {R } + INI ID + {space} + {: or -} + {title}
		} else {
			recordString := removeStringFromStart(recordString, "R ") ; Trim off "R " at start if it's there.
			this.ini := getStringBeforeStr(recordString, " ")
			if(stringMatchesAnyOf(recordString, [":", "-"], , matchedDelim)) {
				; ID is everything up to the first delimiter
				this.id := getFirstStringBetweenStr(recordString, " ", matchedDelim)
				; Title is everything after
				this.title := getStringAfterStr(recordString, matchedDelim)
			} else {
				; ID is the rest of the string
				this.id := getStringAfterStr(recordString, " ")
			}
		}
		
		; Make sure everything is free of extra whitespace
		this.ini   := dropWhitespace(this.ini)
		this.id    := dropWhitespace(this.id)
		this.title := dropWhitespace(this.title)
	}
	
	selectMissingInfo() {
		if(this.ini != "" && this.id != "") ; Nothing required is missing.
			return true
		
		s := new Selector("actionObject.tls", {"COLUMN":"TYPE", "VALUE":ActionObjectRedirector.Type_EMC2})
		data := s.selectGui("", "Enter INI and ID", {"SUBTYPE":this.ini, "VALUE":this.id})
		if(!data)
			return false
		if(data["SUBTYPE"] = "" || data["VALUE"] = "") ; Didn't get everything we needed.
			return false
		
		this.ini := data["SUBTYPE"]
		this.id  := data["VALUE"]
		return true
	}
	
}
