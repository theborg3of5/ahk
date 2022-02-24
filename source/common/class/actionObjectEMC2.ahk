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
	; DESCRIPTION:    Create a new reference to an EMC2 object.
	; PARAMETERS:
	;  id    (I,REQ) - ID of the object, or combined "INI ID"
	;  ini   (I,OPT) - INI of the object, will be prompted for if not specified and we can't figure
	;                  it out from ID.
	;  title (I,OPT) - Title of the object
	;---------
	__New(id, ini := "", title := "") {
		; If we don't know the INI yet, assume the ID is a combined string (i.e. "DLG 123456" or
		; "DLG 123456: WE DID SOME STUFF") and try to split it into its component parts.
		if(id != "" && ini = "") {
			matches := EpicLib.extractEMC2RecordsFromTitle(id, possibles)
			if(matches.length() + possibles.length() = 0)
				return false
			
			; Pick the first match if there is one ; GDB TODO probably pull this out since it's duplicated from isThisType().
			if(matches.length() >= 1) {
				ini   := matches[1].ini
				id    := matches[1].id
				title := matches[1].title
			
			; If there are possible matches, fail but still pass back the ID of the first one so it shows up in
			; the Selector popup downstream.
			} else if(possibles.length() >= 1) {
				id    := possibles[1].id
				title := possibles[1].title
			}
		}
		
		if(!this.selectMissingInfo(id, ini, "Select INI and ID"))
			return ""
		
		this.id    := StringUpper(id) ; Make sure ID is capitalized as EMC2 URLs fail on lowercase starting letters (i.e. i1234567)
		this.ini   := ini
		this.title := title
	}
	
	;---------
	; DESCRIPTION:    Determine whether the given string MUST be this type of ActionObject.
	; PARAMETERS:
	;  value (I,REQ) - The value to evaluate
	;  ini   (O,OPT) - If the value is an EMC2 record, the INI.
	;  id    (O,OPT) - If the value is an EMC2 record, the ID.
	; RETURNS:        true/false - whether the given value must be an EMC2 object.
	; NOTES:          Must be effectively static - this is called before we decide what kind of object to return.
	;---------
	isThisType(value, ByRef ini := "", ByRef id := "") {
		if(!Config.contextIsWork)
			return false
		
		matches := EpicLib.extractEMC2RecordsFromTitle(value, possibles)
		if(matches.length() + possibles.length() = 0)
			return false
		
		; Pick the first match if there is one
		if(matches.length() >= 1) {
			ini := matches[1].ini
			id  := matches[1].id
			return true
		}
		
		; If there are possible matches, succeed but pass no INI so we get a corresponding popup downstream.
		if(possibles.length() >= 1) {
			id := possibles[1].id
			return true
		}
		
		return false
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
