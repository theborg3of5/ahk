/* Class to represent a record in Epic, which can parse a string in a few different formats. --=
	
	Supported string formats:
		TITLE [R INI ID]
		#ID - TITLE
		INI ID
		INI ID: TITLE
		INI ID - TITLE
		R INI ID
		R INI ID: TITLE
		R INI ID - TITLE
		R INI ID TITLE
		ID
	
	Example Usage
;		; Parse a string into a record
;		record := new EpicRecord("R UCL 123456")
;		MsgBox, % record.ini
;		MsgBox, % record.recordString ; R UCL 123456
;		
;		record := new EpicRecord().initFromEMC2Title() ; Use EMC2 window title to get needed info
;		MsgBox, % record.recordString ; R DLG 123456
	
*/ ; =--

class EpicRecord {
	; #PUBLIC#
	
	; @GROUP@
	ini   := "" ; The INI for this record.
	id    := "" ; The ID for this record.
	title := "" ; The title for this record.
	; @GROUP-END@
	
	;---------
	; DESCRIPTION:    Constructed string representing the record:
	;                   If we have a title: TITLE [R INI ID]
	;                   If we don't have a title: R INI ID
	;---------
	recordString {
		get {
			if(this.ini = "" || this.id = "") ; Missing some info, just return blank
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
	; RETURNS:        this
	;---------
	initFromRecordString(recordString) {
		if(recordString = "")
			return
		
		this.processRecordString(recordString)
		
		return this
	}
	
	;---------
	; DESCRIPTION:    Initialize the record based on the current EMC2 window title.
	; NOTES:          This will only get the INI and ID, never the title.
	; RETURNS:        this
	;---------
	initFromEMC2Title() {
		title := WinGetTitle(Config.windowInfo["EMC2"].titleString)
		title := title.removeFromEnd(" - EMC2")
		
		; If no info available, bail.
		if(title = "EMC2")
			return
		
		this.initFromRecordString(title)
		
		return this
	}
	
	
	; #PRIVATE#
	
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
			
		; 4) {R }INI ID{ }{: or -}{ }{Title}
		} else {
			recordString := recordString.removeFromStart("R ") ; Trim off "R " at start if it's there.
			this.ini := recordString.beforeString(" ")
			recordString := recordString.afterString(" ") ; Trim off INI, we're done with it
			if(recordString.containsAnyOf([":", "-", " "], matchedDelim)) {
				; ID is everything up to the first delimiter
				this.id := recordString.beforeString(matchedDelim)
				; Title is everything after
				this.title := recordString.afterString(matchedDelim)
			} else {
				; ID is the rest of the string
				this.id := recordString.afterString(" ")
			}
		}
		
		; Make sure there's no extra # on the front of the ID
		this.id := this.id.removeFromStart("#")
		
		; Make sure everything is free of extra whitespace
		this.ini   := this.ini.withoutWhitespace()
		this.id    := this.id.withoutWhitespace()
		this.title := this.title.withoutWhitespace()
		
		; Debug.popup("recordString",recordString, "this",this)
	}
	; #END#
}
