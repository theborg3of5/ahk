/* Class to represent Epic records that specifically belong in EMC2, with extra handling for different input formats. =--
	
	Additional handling:
		Special email title formats (extra stuff on the start like "PRJ Readiness", "EMC2 Lock:")
		Converting INIs to their most useful form (Design => XDS, ZQN => QAN, etc.)
	
	Example Usage
;		record := new EMC2Record("DLG", 123456, "Did some stuff!")
;		
;		record := new EMC2Record().initFromRecordString("PRJ Readiness: DLG 123456")
;		MsgBox, % record.ini ; DLG
;		MsgBox, % record.id  ; 123456
;		
;		record := new EMC2Record().initFromEMC2Title() ; Use EMC2 window title to get needed info
;		MsgBox, % record.recordString ; R DLG 123456
	
*/ ; --=

class EMC2Record extends EpicRecord {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    The "standard" EMC2 object string
	; RETURNS:        <INI> <ID> - <TITLE>
	;---------
	standardEMC2String {
		get {
			if(this.title = "") ; No title, just record
				return this.ini " " this.id
			
			title := this.title.clean(["DBC", "-", "/", "\", ":"]) ; Don't need "DBC" and a separator on the start of every EMC2 title.
			return this.ini " " this.id " - " title
		}
	}
	
	;---------
	; DESCRIPTION:    Initialize the record based on a string.
	; PARAMETERS:
	;  recordString (I,REQ) - String representing the record. See class header for supported
	;                         formats.
	; RETURNS:        this
	;---------
	initFromRecordString(recordString) {
		recordString := this.preProcess(recordString)
		base.initFromRecordString(recordString)
		this.postProcess()
		
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
		
		this.processRecordString(title)
		
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
	; DESCRIPTION:    Clean up the string if it has extra stuff or odd formats, so EpicRecord can handle it properly.
	; PARAMETERS:
	;  value (I,REQ) - The value to clean
	; NOTES:          This logic is not taken into account by ActionObject when it's trying to determine the type.
	;---------
	preProcess(value) {
		value := value.remove("Date change notification for")
		value := value.remove("Application removed from")
		value := value.remove("Priority Queue:")
		value := value.remove("[Signed]")
		value := value.remove("(Developer has reset your status)")
		value := value.remove("A PQA 1 Reviewer is Waiting for Changes")
		value := value.remove("A PQA 1 Reviewer has signed off")
		value := value.remove("A PQA 2 Reviewer is Waiting for Changes")
		value := value.remove("A PQA 2 Reviewer has signed off")
		value := value.remove("An Expert Reviewer is Waiting for Changes")
		value := value.remove("An Expert Reviewer has signed off")
		value := value.remove("A QA 1 Reviewer is Waiting for Changes")
		value := value.remove("A QA 1 Reviewer has signed off")
		value := value.remove("A QA 2 Reviewer is Waiting for Changes")
		value := value.remove("A QA 2 Reviewer has signed off")
		value := value.remove("Status Changed to PQA 1")
		value := value.remove("Status Changed to QA 1")
		value := value.remove("Status Changed to PQA 2")
		value := value.remove("Status Changed to QA 2")
		value := value.remove("Status Changed to Final Stage Comp")
		value := value.remove("(A Reviewer Approved)")
		value := value.remove("(A Reviewer is Waiting for Changes)")
		value := value.remove("(A Reviewer Declined to Review)")
		value := value.remove("--Assigned To:")
		
		value := value.replace("PRJ Readiness ", "PRJ ") ; Needs to be slightly more specific - just removing "readiness" across the board is too broad.
		
		; EMC2 lock emails have stuff in a weird order - flip it around.
		if(value.startsWith("EMC2 Lock: ")) {
			value := value.removeFromStart("EMC2 Lock: ").removeFromEnd(" is locked")
			title := value.beforeString(" [")
			id    := value.afterString("] ")
			ini   := value.firstBetweenStrings(" [", "] ").afterString(" ", true) ; INI is between the brackets, but only get the last word (for "development log" case)
			
			value := ini " " id " - " title
		}
		
		return value
	}
	
	;---------
	; DESCRIPTION:    Do some additional processing on the different bits of info about the object.
	; SIDE EFFECTS:   Can update this.ini, this.id, and this.title.
	;---------
	postProcess() {
		; INI - make sure the INI is the "real" EMC2 one.
		this.ini := EpicLib.convertToUsefulEMC2INI(this.ini)
	}
	; #END#
}
