#Include %A_LineFile%\..\actionObjectBase.ahk

/* Class for performing actions on EMC2 objects.
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
		ao := new ActionObjectEMC2("DLG 123456")
		MsgBox, ao.getLinkWeb()      ; Link in web (emc2summary or Nova/Sherlock as appropriate)
		MsgBox, ao.getLinkWebBasic() ; Link in "basic" web (always emc2summary)
		MsgBox, ao.getLinkEdit()     ; Link to edit in EMC2
		ao.openWeb()                 ; Open in web (emc2summary or Nova/Sherlock as appropriate)
		ao.openWebBasic()            ; Open in "basic" web (always emc2summary)
		ao.openEdit()                ; Open to edit in EMC2
		
		ao := new ActionObjectEMC2(123456) ; ID without an INI, user will be prompted for the INI
		ao.openEdit() ; Open object in EMC2
*/

class ActionObjectEMC2 extends ActionObjectBase {

; ==============================
; == Public ====================
; ==============================
	id    := "" ; ID of the object
	ini   := "" ; INI for the object, from EMC2 subtypes in actionObject.tl
	title := "" ; Title for the EMC2 object
	
	; The "standard" (to me) EMC2 object string.
	standardEMC2String { ; INI ID - TITLE
		get {
			if(!this.selectMissingInfo())
				return ""
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
		this.id    := id
		this.ini   := ini
		this.title := title
		
		; If we don't know the INI yet, assume the ID is a combined string (i.e. "DLG 123456" or
		; "DLG 123456: HB/PB WE DID SOME STUFF") and try to split it into its component parts.
		if(this.id != "" && this.ini = "") {
			record := new EpicRecord(this.id)
			this.ini   := record.ini
			this.id    := record.id
			this.title := record.title
		}
		
		if(!this.selectMissingInfo())
			return
		
		this.postProcess()
	}
	
	;---------
	; DESCRIPTION:    Do some additional processing on the different bits of info about the object.
	; SIDE EFFECTS:   Can update this.ini and this.title.
	;---------
	postProcess() {
		; INI - make sure the INI is the "real" EMC2 one.
		s := new Selector("actionObject.tls", {"COLUMN":"TYPE", "VALUE":ActionObjectRedirector.Type_EMC2})
		this.ini := s.selectChoice(this.ini, "SUBTYPE")
		
		; Title - clean up, drop anything extra that we don't need.
		removeAry := ["-", "/", "\", ":", ",", "DBC"] ; Don't need "DBC" on the start of every EMC2 title.
		; INI-specific strings to remove
		if(this.ini = "DLG") {
			; All permutations of these can appear
			For _,role in ["A PQA 1 Reviewer", "A PQA 2 Reviewer", "An Expert Reviewer", "A QA 1 Reviewer", "A QA 2 Reviewer"] {
				For _,result in ["is Waiting for Changes", "has signed off"] {
					actionStrings.push("(" role " " result ")")
				}
			}
			actionStrings := ["(Developer has reset your status)"]
			removeAry.appendArray(actionStrings)
		} else if(this.ini = "XDS") {
			removeAry.appendArray(["(A Reviewer Approved)", "(A Reviewer is Waiting for Changes)", "(A Reviewer Declined to Review)"])
		} else if(this.ini = "SLG") {
			removeAry.appendArray(["--Assigned To:"])
		}
		
		this.title := this.title.clean(removeAry)
	}
	
	;---------
	; DESCRIPTION:    Open the EMC2 object in "basic" web - always emc2summary, even for
	;                 Nova/Sherlock INIs.
	;---------
	openWebBasic() {
		link := MainConfig.private["EMC2_LINK_WEB_BASE"].replaceTags({"INI":this.ini, "ID":this.id})
		if(link)
			Run(link)
	}
	
	;---------
	; DESCRIPTION:    Get a link to the EMC2 object.
	; RETURNS:        Link to the object:
	;                    Web: link to either emc2summary or Nova/Sherlock (depending on the INI)
	;                    Edit: link to open it in EMC2.
	;---------
	getLinkWeb() {
		if(this.isSherlockObject())
			link := MainConfig.private["SHERLOCK_BASE"]
		else if(this.isNovaObject())
			link := MainConfig.private["NOVA_RELEASE_NOTE_BASE"]
		else
			link := MainConfig.private["EMC2_LINK_WEB_BASE"]
		
		return link.replaceTags({"INI":this.ini, "ID":this.id})
	}
	getLinkEdit() {
		return MainConfig.private["EMC2_LINK_EDIT_BASE"].replaceTags({"INI":this.ini, "ID":this.id})
	}
	
	
; ==============================
; == Private ===================
; ==============================
	;---------
	; DESCRIPTION:    Check whether this object can be opened in Sherlock or Nova (rather than emc2summary).
	; RETURNS:        True if it can be opened in Sherlock or Nova (respectively), False otherwise.
	;---------
	isSherlockObject() {
		return (this.ini = "SLG")
	}
	isNovaObject() {
		return (this.ini = "DRN")
	}
	
	;---------
	; DESCRIPTION:    Prompt the user for any missing-but-required info that we couldn't figure out
	;                 on our own.
	; SIDE EFFECTS:   Sets .ini and .id based on the user's inputs.
	; RETURNS:        True if all required info was received, False otherwise.
	;---------
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
