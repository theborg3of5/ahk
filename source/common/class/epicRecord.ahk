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
		ID
	
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
	
	;---------
	; DESCRIPTION:    Constructed string representing the record:
	;                   If we have a title: TITLE [R INI ID]
	;                   If we don't have a title: R INI ID
	;---------
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
		title := title.removeFromEnd(" - EMC2")
		
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
		recordString := recordString.firstLine().clean() ; Make sure it's only 1 line, clean any funky characters off of string edges
		if(recordString = "")
			return
		
		; 1) Title [R INI ID]
		if(recordString.contains("[R ") && recordString.contains("]")) {
			; Title is everything up to the opening square bracket
			this.title := recordString.beforeString("[R ")
			
			; In the square brackets should be "R INI ID"
			iniId := recordString.firstBetweenStrings("[R ", "]")
			this.ini := iniId.beforeString(" ")
			this.id  := iniId.afterString(" ")
			
		; 2) #ID - Title
		} else if(recordString.startsWith("#")) {
			this.id := recordString.firstBetweenStrings("#", " - ")
			this.title := recordString.afterString(" - ")
			
		; 3) ID (no spaces)
		} else if(!recordString.contains(" ")) {
			this.id := recordString
			
		; 4) {R } + INI ID + {space} + {: or -} + {title}
		} else {
			recordString := recordString.removeFromStart("R ") ; Trim off "R " at start if it's there.
			this.ini := recordString.beforeString(" ")
			if(recordString.containsAnyOf([":", "-"], matchedDelim)) {
				; ID is everything up to the first delimiter
				this.id := recordString.firstBetweenStrings(" ", matchedDelim)
				; Title is everything after
				this.title := recordString.afterString(matchedDelim)
			} else {
				; ID is the rest of the string
				this.id := recordString.afterString(" ")
			}
		}
		
		; Make sure everything is free of extra whitespace
		this.ini   := this.ini.withoutWhitespace()
		this.id    := this.id.withoutWhitespace()
		this.title := this.title.withoutWhitespace()
		
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
		
		data := new Selector("epicRecord.tls").selectGui("", "", {"INI":this.ini, "ID":this.id})
		if(!data)
			return false
		if(data["INI"] = "" || data["ID"] = "") ; Didn't get everything we needed.
			return false
		
		this.ini := data["INI"]
		this.id  := data["ID"]
		return true
	}
	
}
