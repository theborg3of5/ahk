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
;		record := new EpicRecord().initFromEMC2Title() ; Use EMC2 window title to get needed info
;		MsgBox, % record.recordString ; R DLG 123456
	
	GDB TODO
		Update auto-complete and syntax highlighting notepad++ definitions
	
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
			
			return this.ini " " this.id " - " this.title
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
		; Email subject handling
		value := value.removeFromStart("Date change notification for ") ; Date change notifications
		value := value.removeFromStart("Application removed from ")
		value := value.removeFromStart("Priority Queue: ")
		value := value.removeFromStart("[Signed] ")
		if(value.startsWith("PRJ Readiness "))
			value := value.replaceOne("PRJ Readiness ", "PRJ ")
		if(value.startsWith("EMC2 Lock: ")) {
			value := value.removeFromStart("EMC2 Lock: ").removeFromEnd(" is locked")
			title   := value.beforeString(" [")
			id      := value.afterString("] ")
			iniName := value.firstBetweenStrings(" [", "] ")
			
			; Convert the name of the record type into an INI.
			Switch iniName {
				Case "Development Log": ini := "DLG"
				Case "Design":          ini := "XDS"
				Case "Main":            ini := "QAN" ; Yes, this is weird. Not sure why it uses "Main", but it's distinct from the others so it works.
				Case "Project":         ini := "PRJ"
				Case "Issue":           ini := "ZDQ"
			}
			
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
		this.ini := ActionObjectEMC2.convertToUsefulINI(this.ini)
		
		; Title - clean up, drop anything extra that we don't need.
		removeAry := ["-", "/", "\", ":", ",", "DBC"] ; Don't need "DBC" on the start of every EMC2 title.
		; INI-specific strings to remove
		Switch this.ini {
			Case "DLG":
				removeAry.push("(Developer has reset your status)")
				; All permutations of these can appear
				For _,role in ["A PQA 1 Reviewer", "A PQA 2 Reviewer", "An Expert Reviewer", "A QA 1 Reviewer", "A QA 2 Reviewer"] {
					For _,result in ["is Waiting for Changes", "has signed off"] {
						removeAry.push("(" role " " result ")")
					}
				}
				For _,status in ["PQA 1", "QA 1", "PQA 2", "QA 2", "Final Stage Comp"] {
					removeAry.push("Status Changed to " status)
				}
			Case "XDS":
				removeAry.appendArray(["(A Reviewer Approved)", "(A Reviewer is Waiting for Changes)", "(A Reviewer Declined to Review)"])
			Case "SLG":
				removeAry.appendArray(["--Assigned To:"])
		}
		
		this.id := StringUpper(this.id) ; Make sure ID is capitalized as some spots fail on lowercase starting letters (i.e. i1234567)
		
		this.title := this.title.clean(removeAry)
	}
	; #END#
}
