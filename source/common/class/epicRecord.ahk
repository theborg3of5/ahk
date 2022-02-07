/* Class to represent a record in Epic, which can parse a string in a few different formats. =--
	
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
;		record := new EpicRecord().initFromRecordString("R UCL 123456")
;		MsgBox, % record.ini          ; UCL
;		MsgBox, % record.id           ; 123456
;		MsgBox, % record.recordString ; R UCL 123456
	
*/ ; --=

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
	__New(ini := "", id := "", title := "") {
		this.ini   := ini
		this.id    := id
		this.title := title
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
		title := Config.windowInfo["EMC2"].getCurrTitle()
		title := title.removeFromEnd(" - EMC2")
		
		; If no info available, bail.
		if(title = "EMC2")
			return
		
		this.initFromRecordString(title)
		
		return this
	}
	
	;---------
	; DESCRIPTION:    Initialize the record based on a TLG string.
	; PARAMETERS:
	;  tlgString (I,REQ) - TLG string from Outlook TLG calendar.
	; NOTES:          We assume there's only 1 record ID per string, so the first one will win.
	; RETURNS:        this
	;---------
	initFromTLGString(tlgString) {
		baseAry := Config.private["OUTLOOK_TLG_BASE"].split(["/", ","])
		tlgAry := tlgString.split(["/", ","])
		
		recIDs := {}
		For _,ini in ["SLG", "DLG", "PRJ", "QAN"] {
			iniIndex := baseAry.contains("<" ini ">")
			id := tlgAry[iniIndex]
			
			if(id != "") {
				this.ini := ini
				this.id  := id
				Break
			}
		}
		
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
		recordString := recordString.firstLine().withoutWhitespace().clean() ; Make sure it's only 1 line, clean any spaces and funky characters off of string edges
		if(recordString = "")
			return
		
		; Replace any sets of multiple spaces with singles
		while(recordString.contains("  "))
			recordString := recordString.replace("  "," ")
		
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
		} else if(!recordString.removeFromEnd(" ").contains(" ")) {
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
