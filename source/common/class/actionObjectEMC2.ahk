#Include ..\base\actionObjectBase.ahk

/* Class for performing actions on EMC2 objects. =--
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
;		ao := new ActionObjectEMC2("DLG 123456")
;		MsgBox, ao.getLinkWeb()      ; Link in web (emc2summary or Sherlock as appropriate)
;		MsgBox, ao.getLinkEdit()     ; Link to edit in EMC2
;		ao.openWeb()                 ; Open in web (emc2summary or Sherlock as appropriate)
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
			match := EpicLib.getBestEMC2RecordFromText(id)
			if(match) {
				ini   := match.ini
				id    := match.id
				title := match.title
			}
		}
		
		if(!this.selectMissingInfo(id, ini, "Select INI and ID"))
			return ""
		
		this.id    := StringUpper(id) ; Make sure ID is capitalized as EMC2 URLs fail on lowercase starting letters (i.e. i1234567)
		this.ini   := EpicLib.convertToUsefulEMC2INI(ini) ; Make sure we've got the proper INI (in case the caller passed in something that needs to be converted)
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
		
		match := EpicLib.getBestEMC2RecordFromText(value)
		if(match && match.ini != "") {
			ini := match.ini
			id  := match.id
			return true
		}
		
		return false
	}
	
	;---------
	; DESCRIPTION:    Get a web link to the object.
	; RETURNS:        Link to either emc2summary or Sherlock (depending on the INI)
	;---------
	getLinkWeb() {
		ini := this.ini
		
		if(this.isEditOnlyObject() || this.isViewOnlyObject(ini)) ; View-only objects only work as edit-type links, so redirect them there.
			link := this.getLinkEdit()
		else if(this.isInternalOnlyObject(ini))
			link := Config.private["SHERLOCK_INTERNAL_ONLY_BASE"]
		else if(this.isSherlockObject())
			link := Config.private["SHERLOCK_BASE"]
		else
			link := Config.private["EMC2_LINK_WEB_BASE"]
		
		return link.replaceTags({"INI":ini, "ID":this.id})
	}
	;---------
	; DESCRIPTION:    Get an edit link to the object.
	; RETURNS:        Link to the object that opens it in EMC2.
	;---------
	getLinkEdit() {
		ini := this.ini
		
		ini := this.convertDashedINI(ini)
		
		if(this.isViewOnlyObject(ini))
			link := Config.private["EMC2_LINK_EDIT_VIEW_ONLY_BASE"]
		else
			link := Config.private["EMC2_LINK_EDIT_BASE"]
		
		return link.replaceTags({"INI":ini, "ID":this.id})
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
	; DESCRIPTION:    Check whether this object is an "internal-only" one that needs a special kind of web link (rather than emc2summary).
	; PARAMETERS:
	;  ini (IO,OPT) - The current INI. Will be replaced with the "real" INI if this is a special "internal-only" INI value
	;                 (typically INI + "I").
	; RETURNS:        true/false
	;---------
	isInternalOnlyObject(ByRef ini := "") {
		if(ini = "SLGI") {
			ini := "SLG"
			return true
		}
		
		return false
	}
	
	;---------
	; DESCRIPTION:    Check whether this object is an "view-only" one that needs a special kind of edit link.
	; PARAMETERS:
	;  ini (IO,OPT) - The current INI. Will be replaced with the "real" INI if this is a special "view-only" INI value
	;                 (typically INI + "V").
	; RETURNS:        true/false
	;---------
	isViewOnlyObject(ByRef ini := "") {
		; Try to map the INI from a view-only INI to a "real" one
		realINI := this.getRealViewOnlyRealINI(ini)
		if(!realINI) ; It's not a view-only INI.
			return false
		
		ini := realINI
		return true
	}
	
	;---------
	; DESCRIPTION:    If the given INI is a "view-only" INI, return its corresponding "real" INI.
	; PARAMETERS:
	;  viewOnlyINI (I,REQ) - The INI to try and map.
	; RETURNS:        The "real" INI if it's a "view-only" INI (i.e. QANV => QAN), "" if it's not.
	;---------
	getRealViewOnlyRealINI(viewOnlyINI) {
		Switch viewOnlyINI {
			Case "DLGV": return "DLG"
			Case "QANV": return "QAN"
			Case "XDSV": return "XDS"
			Case "ZDQV": return "ZDQ"
		}
		
		return "" ; Not a view-only INI.
	}
	
	;---------
	; DESCRIPTION:    Certain objects don't actually have a web view - we'll redirect these to edit mode instead.
	; RETURNS:        true/false
	;---------
	isEditOnlyObject() {
		return ["ZCK", "ZPF"].contains(this.ini)
	}
	
	;---------
	; DESCRIPTION:    If the given INI is a "dashed" INI (contains a hyphen), then return the "real" INI it goes to (for
	;                 use in edit mode - EMC2 doesn't support dashed INIs).
	; PARAMETERS:
	;  ini (I,REQ) - The INI to check
	; RETURNS:        The new INI
	; NOTES:          This should more-or-less match EpicLib.flattenDashedINIs().
	;---------
	convertDashedINI(ini) {
		Switch ini {
			Case "PRJ-R": return "PRJ"
			Case "DLG-I": return "DLG"
		}
		
		return ini ; Default case, let the INI thru as normal
	}
	; #END#
}
