/* Class to represent a record in Epic, which can parse a string in a few different formats.
	
	Supported string formats:
		TITLE [R INI ID]
		#ID - TITLE
		INI ID
		INI ID: TITLE
		INI ID - TITLE
		R INI ID
		R INI ID: TITLE
		R INI ID - TITLE
	
	Example Usage
		; Parse a string into a record
		record := new EpicRecord("R UCL 123456")
		MsgBox, % record.ini
		MsgBox, % record.recordString ; R UCL 123456
		
		record := new EpicRecord()
		record.initFromEMC2Title() ; Use EMC2 window title to get needed info
		MsgBox, % record.recordString ; R DLG 123456
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
	
	;---------
	; DESCRIPTION:    Create a new EpicRecord object, optionally parsing it from a string.
	; PARAMETERS:
	;  recordString (I,OPT) - String representing the record. See class header for supported
	;                         formats. If not given, record will need to be initialized with
	;                         one of the .initFrom*() functions.
	;---------
	__New(recordString := "") {
		if(recordString != "")
			this.initFromRecordString(recordString)
	}
	
	;---------
	; DESCRIPTION:    Initialize the record based on a string.
	; PARAMETERS:
	;  recordString (I,REQ) - String representing the record. See class header for supported
	;                         formats.
	;---------
	initFromRecordString(recordString) {
		if(recordString = "")
			return
		
		this.processRecordString(recordString)
	}
	
	;---------
	; DESCRIPTION:    Initialize the record based on the current EMC2 window title.
	; NOTES:          This will only get the INI and ID, never the title.
	;---------
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
	;---------
	; DESCRIPTION:    Parse the given string to extract and store the record's identifying information.
	; PARAMETERS:
	;  recordString (I,REQ) - String representing the record. See class header for supported
	;                         formats.
	; SIDE EFFECTS:   Sets .ini, .id, and .title.
	;---------
	processRecordString(recordString) {
		recordString := cleanupText(recordString) ; Clean any funky characters off of string edges
		if(recordString = "")
			return
		
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
		
		; DEBUG.popup("recordString",recordString, "this",this)
	}
	
	;---------
	; DESCRIPTION:    Prompt the user for any missing-but-required information using a Selector popup.
	; RETURNS:        True if all required information was obtained, False if not.
	; SIDE EFFECTS:   Sets .ini and .id.
	;---------
	selectMissingInfo() {
		if(this.ini != "" && this.id != "") ; Nothing required is missing.
			return true
		
		s := new Selector("epicRecord.tls")
		data := s.selectGui("", "", {"INI":this.ini, "ID":this.id})
		if(!data)
			return false
		if(data["INI"] = "" || data["ID"] = "") ; Didn't get everything we needed.
			return false
		
		this.ini := data["INI"]
		this.id  := data["ID"]
		return true
	}
	
}
