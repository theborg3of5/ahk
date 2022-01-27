#Include ..\base\actionObjectBase.ahk

/* Class for performing actions on EMC2 objects. =--
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
;		ao := new ActionObjectEMC2("DLG 123456")
;		MsgBox, ao.getLinkWeb()      ; Link in web (emc2summary or Nova/Sherlock as appropriate)
;		MsgBox, ao.getLinkWebBasic() ; Link in "basic" web (always emc2summary)
;		MsgBox, ao.getLinkEdit()     ; Link to edit in EMC2
;		ao.openWeb()                 ; Open in web (emc2summary or Nova/Sherlock as appropriate)
;		ao.openWebBasic()            ; Open in "basic" web (always emc2summary)
;		ao.openEdit()                ; Open to edit in EMC2
;		
;		ao := new ActionObjectEMC2(123456) ; ID without an INI, user will be prompted for the INI
;		ao.openEdit() ; Open object in EMC2
	
*/ ; --=

class ActionObjectEMC2 extends ActionObjectBase {
	; #PUBLIC#
	
	ActionObjectType := ActionObject.Type_EMC2
	
	; @GROUP@
	id    := "" ; ID of the object
	ini   := "" ; INI for the object, from EMC2 subtypes in actionObject.tl
	title := "" ; Title for the EMC2 object
	; @GROUP-END@
	
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
	; DESCRIPTION:    Create a new reference to an EMC2 object.
	; PARAMETERS:
	;  id    (I,REQ) - ID of the object, or combined "INI ID"
	;  ini   (I,OPT) - INI of the object, will be prompted for if not specified and we can't figure
	;                  it out from ID.
	;  title (I,OPT) - Title of the object
	;---------
	__New(id, ini := "", title := "") {
		; If we don't know the INI yet, assume the ID is a combined string (i.e. "DLG 123456" or
		; "DLG 123456: HB/PB WE DID SOME STUFF") and try to split it into its component parts.
		if(id != "" && ini = "") {
			value := this.preProcess(id) ; Do a little cleanup to make sure EpicRecord can handle the string
			
			record := new EpicRecord(value)
			ini   := record.ini
			id    := record.id
			title := record.title
		}
		
		if(!this.selectMissingInfo(id, ini, "Select INI and ID"))
			return ""
		
		this.id    := id
		this.ini   := ini
		this.title := title
		this.postProcess()
	}
	
	;---------
	; DESCRIPTION:    Determine whether the given string must be this type of ActionObject.
	; PARAMETERS:
	;  value (I,REQ) - The value to evaluate
	;  ini   (O,OPT) - If the value is an EMC2 record, the INI
	;  id    (O,OPT) - If the value is an EMC2 record, the ID
	; RETURNS:        true/false - whether the given value must be an EMC2 object.
	; NOTES:          Must be effectively static - this is called before we decide what kind of object to return.
	;---------
	isThisType(value, ByRef ini := "", ByRef id := "") {
		if(!Config.contextIsWork)
			return false
		
		record := new EpicRecord(value)
		if(record.ini = "" || record.id = "")
			return false
		
		; Silent selection from actionObject TLS to see if we match an EMC2-type INI (filtered list so no match means not EMC2).
		s := ActionObjectBase.getTypeSelector(ActionObject.Type_EMC2)
		matchedINI := s.selectChoice(record.ini, "SUBTYPE")
		if(matchedINI = "")
			return false
		
		; The value does match this type, so return the info we found to save a little work later.
		ini := matchedINI
		id  := record.id
		return true
	}
	
	;---------
	; DESCRIPTION:    Open the EMC2 object in "basic" web - always emc2summary, even for
	;                 Nova/Sherlock INIs.
	;---------
	openWebBasic() {
		link := Config.private["EMC2_LINK_WEB_BASE"].replaceTags({"INI":this.ini, "ID":this.id})
		if(link)
			Run(link)
	}
	
	;---------
	; DESCRIPTION:    Get a web link to the object.
	; RETURNS:        Link to either emc2summary or Nova/Sherlock (depending on the INI)
	;---------
	getLinkWeb() {
		if(this.isSherlockObject())
			link := Config.private["SHERLOCK_BASE"]
		else if(this.isNovaObject())
			link := Config.private["NOVA_RELEASE_NOTE_BASE"]
		else
			link := Config.private["EMC2_LINK_WEB_BASE"]
		
		return link.replaceTags({"INI":this.ini, "ID":this.id})
	}
	;---------
	; DESCRIPTION:    Get an edit link to the object.
	; RETURNS:        Link to the object that opens it in EMC2.
	;---------
	getLinkEdit() {
		return Config.private["EMC2_LINK_EDIT_BASE"].replaceTags({"INI":this.ini, "ID":this.id})
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
		this.ini := this.getTypeSelector(ActionObject.Type_EMC2).selectChoice(this.ini, "SUBTYPE")
		
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
	
	;---------
	; DESCRIPTION:    Check whether this object can be opened in Sherlock (rather than emc2summary).
	; RETURNS:        true/false
	;---------
	isSherlockObject() {
		return (this.ini = "SLG")
	}
	;---------
	; DESCRIPTION:    Check whether this object can be opened in Nova (rather than emc2summary).
	; RETURNS:        true/false
	;---------
	isNovaObject() {
		return (this.ini = "DRN")
	}
	; #END#
}
