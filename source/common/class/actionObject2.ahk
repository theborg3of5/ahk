/* Class for ***
	
	***
*/

; global SUBTYPE_FilePath := "FILEPATH"
; global SUBTYPE_URL      := "URL"
; global SUBTYPE_Routine  := "ROUTINE"
; global SUBTYPE_DLG      := "DLG"
; ; Additional subtypes (EMC2 INIs) can be defined in actionObject.tls.



class ActionObjectRedirector {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	
	
	
	__New(value := "", type := "", subType := "") {
		this.value   := value
		this.type    := type
		this.subType := subType
		
		this.determineType()
		this.selectMissingInfo()
		
		DEBUG.toast("ActionObjectRedirector","All info determined", "this",this)
		return this.getTypeSpecificObject()
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	value   := ""
	type    := ""
	subType := ""
	
	determineType() {
		; Already know the type
		if(this.type != "")
			return
		
		; GDB TODO - tryProcessAsPath
		
		if(this.tryProcessAsRecord()) ; EMC2 objects and helpdesk are in "INI ID *" format
			return
	}
	
	tryProcessAsRecord() {
		; Try splitting apart string into INI/ID/title
		recordAry := extractEMC2ObjectInfoRaw(this.value)
		potentialINI := recordAry["INI"]
		
		s := new Selector("actionObject.tls", MainConfig.machineTLFilter)
		data := s.selectChoice(potentialINI)
		if(!data)
			return false
		
		type    := data["TYPE"]
		subType := data["SUBTYPE"]
		
		; Only EMC2 objects and helpdesk can be split and handled this way.
		if((type != ActionBaseObject.TYPE_EMC2) && (type != ActionBaseObject.TYPE_Helpdesk))
			return false
		
		; We successfully identified the type, store off the pieces we know.
		this.type    := type
		this.subType := subType
		this.value   := recordAry["ID"] ; From first split above
		return true
	}
	
	
	
	
	selectMissingInfo() {
		; Nothing is missing
		if(this.value != "" && this.type != "")
			return
		
		s := new Selector("actionObject.tls", MainConfig.machineTLFilter)
		data := s.selectGui("", "", {"TYPE":this.type, "SUBTYPE":this.subType, "VALUE":this.value})
		if(!data)
			return
		
		this.type    := data["TYPE"]
		this.subType := data["SUBTYPE"]
		this.value   := data["VALUE"]
	}
	
	
	getTypeSpecificObject() {
		if(this.type = "")
			return "" ; No determined type, silent quit, return nothing
		
		if(this.type = ActionBaseObject.TYPE_EMC2)
			return new ActionEMC2Object(this.value, this.subType)
		
		if(this.type = ActionBaseObject.TYPE_Helpdesk)
			return new ActionHelpdeskObject(this.value)
		
		Toast.showError("Unrecognized type", "ActionObjectRedirector doesn't know what to do with this type: " this.type)
		return ""
	}
	
}

class ActionBaseObject {
	; ==============================
	; == Public ====================
	; ==============================
	
	; Type constants
	static TYPE_EMC2              := "EMC2"
	; static TYPE_EpicStudio        := "EPICSTUDIO"
	; static TYPE_CodeSearchRoutine := "CODESEARCHROUTINE"
	static TYPE_Helpdesk          := "HELPDESK"
	; static TYPE_GuruSearch        := "GURU_SEARCH"
	static TYPE_Path              := "PATH"
	
	; GDB TODO document
	static SUBACTION_Edit     := "EDIT"
	static SUBACTION_View     := "VIEW"
	static SUBACTION_Web      := "WEB"
	static SUBACTION_WebBasic := "WEB_BASIC"
	
	
	
	__New(value := "", subType := "") {
		Toast.showError("ActionObject instance created", "ActionObject is a base class only, use a type-specific child class instead.")
		return ""
	}
	
	
	open(runType := "") {
		link := this.getLink(runType)
		if(link)
			Run(link)	
	}
	
	
	copyLink(linkType := "") {
		link := this.getLink(linkType)
		setClipboardAndToastValue(link, "link")
	}
	
	
	linkSelectedText(linkType := "") {
		link := this.getLink(linkType)
		if(!link)
			return
		
		if(!Hyperlinker.linkSelectedText(link, errorMessage))
			setClipboardAndToastError(link, "link", "Failed to link selected text", errorMessage)
	}
	
	
	getLink(linkType := "") {
		Toast.showError(".getLink() called directly", ".getLink() is not implemented by the parent ActionBaseObject class")
		return ""
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	value   := "" ; GDB TODO document
	subType := ""

}



class ActionEMC2Object extends ActionBaseObject {
	; ==============================
	; == Public ====================
	; ==============================
	
	; Named property equivalents for the base generic variables, so base functions still work.
	ini[] {
		get {
			return this.subType
		}
		set {
			this.subType := value
		}
	}
	id[] {
		get {
			return this.value
		}
		set {
			this.value := value
		}
	}
	
	
	__New(value, subType := "", title := "") {
		this.id    := value
		this.ini   := subType
		this.title := title
		
		; If we were given a combined string (i.e. "DLG 123456" or "DLG 123456: HB/PB SOMETHING HAPPENING") split it into its component parts.
		if(this.ini = "") {
			recordAry := extractEMC2ObjectInfoRaw(this.id)
			this.ini   := recordAry["INI"]
			this.id    := recordAry["ID"]
			this.title := recordAry["TITLE"]
		}
		
		; If INI is set, make sure it's the "true" INI (ZQN -> QAN, Design -> XDS, etc.)
		if(this.ini != "")
			this.ini := getTrueEMC2INI(this.ini)
		
		this.selectMissingInfo()
	}
	
	; GDB TODO split this into smaller functions - pick link type, get link based on type (maybe separate switch function to get link base)
	getLink(linkType := "") {
		if(!this.ini || !this.id)
			return ""
		
		; Default to web link
		if(linkType = "")
			linkType := ActionBaseObject.SUBACTION_Web
		
		; View basically goes one way or the other depending on INI:
		;  * If it can be viewed in EMC2, use EDIT with a special view-only parameter.
		;  * Otherwise, create a web link instead.
		if(linkType = ActionBaseObject.SUBACTION_View) {
			if(this.canViewINIInEMC2()) {
				linkType   := ActionBaseObject.SUBACTION_Edit
				paramString := "&runparams=1"
			} else {
				linkType   := ActionBaseObject.SUBACTION_Web
			}
		}
		
		; Pick one of the types of links - edit in EMC2 or view in web (summary or Sherlock/Nova).
		if(linkType = ActionBaseObject.SUBACTION_Edit) {
			link := MainConfig.private["EMC2_LINK_EDIT_BASE"]
		} else if(linkType = ActionBaseObject.SUBACTION_Web) {
			if(this.isSherlockINI())
				link := MainConfig.private["SHERLOCK_BASE"]
			else if(this.isNovaINI())
				link := MainConfig.private["NOVA_RELEASE_NOTE_BASE"]
			else
				link := MainConfig.private["EMC2_LINK_WEB_BASE"]
		} else if(linkType = ActionBaseObject.SUBACTION_WebBasic) {
			link := MainConfig.private["EMC2_LINK_WEB_BASE"]
		}
		
		link .= paramString
		link := replaceTags(link, {"INI":this.ini, "ID":this.id})
		
		return link
	}
	canViewINIInEMC2() {
		if(this.ini = "DLG")
			return true
		if(this.ini = "QAN")
			return true
		if(this.ini = "XDS")
			return true
		
		return false
	}
	isSherlockINI() {
		return (this.ini = "SLG")
	}
	isNovaINI() {
		return (this.ini = "DRN")
	}
	
	; ==============================
	; == Private ===================
	; ==============================
	
	title := ""
	
	
	selectMissingInfo() {
		; Nothing is missing
		if(this.id != "" && this.ini != "")
			return
		
		s := new Selector("actionObject.tls", MainConfig.machineTLFilter)
		data := s.selectGui("", "", {"SUBTYPE": this.ini, "VALUE": this.id})
		if(!data)
			return
		
		this.ini := data["SUBTYPE"]
		this.id  := data["VALUE"]
	}
}


class ActionHelpdeskObject extends ActionBaseObject {
	; ==============================
	; == Public ====================
	; ==============================
	
	; Named property equivalents for the base generic variables, so base functions still work.
	id[] {
		get {
			return this.value
		}
		set {
			this.value := value
		}
	}
	
	__New(value) {
		this.id := value
	}
	
	getLink() {
		return replaceTag(MainConfig.private["HELPDESK_BASE"], "ID", this.id)
	}
}



	
	; ;---------
	; ; DESCRIPTION:    Identify the intended object based on the given information, prompting the
	; ;                 user for any missing information needed to identify the object, and perform
	; ;                 the given action.
	; ; PARAMETERS:
	; ;  value     (I,REQ) - The primary identifying information for the object we want to perform the
	; ;                      action on. Can be a partial identifier (ID, URL, filepath) that will be
	; ;                      evaluated with a given (or prompted) type/subType, or in some cases a
	; ;                      full identifier (for example "QAN 123456" - includes both INI [drives
	; ;                      subType and implies type] and ID).
	; ;  type      (I,OPT) - The general type that goes with value - from TYPE_* constants. If not
	; ;                      given, the user will be prompted to choose this.
	; ;  action    (I,OPT) - The action to perform with the object, from ACTION_* constants.
	; ;  subType   (I,OPT) - Within the given type, further identifying information, from SUBTYPE_*
	; ;                      constants (or other subTypes defined in actionObject.tls).
	; ;  subAction (I,OPT) - Within the given action, further information about what to do, from
	; ;                      SUBACTION_* constants.
	; ; RETURNS:        For ACTION_Link, the link. Otherwise, "".
	; ;---------
	; do(value, type := "", action := "", subType := "", subAction := "") {
		; ; DEBUG.toast("ActionObject.do", "Start", "value", value, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		; ; Clean up value.
		; value := getFirstLine(value) ; Comes first so that we can clean from end of first line (even if there are multiple).
		; value := cleanupText(value)
		
		; ; Determine what we need to do.
		; this.process(value, type, action, subType, subAction)
		
		; ; Expand shortcuts and gather more info as needed.
		; this.selectInfo(value, type, action, subType, subAction)
		
		; this.postProcess(value, type, action, subType, subAction)
		
		; ; Just do it.
		; return this.perform(value, type, action, subType, subAction)
	; }
	
	
	; ; ==============================
	; ; == Private ===================
	; ; ==============================
	
	; ;---------
	; ; DESCRIPTION:    Go through all given information and determine as many distinct properties
	; ;                 about the object and action as we can.
	; ; PARAMETERS:
	; ;  value     (IO,REQ) - The primary identifying information for the object we want to perform the
	; ;                       action on. Can be a partial identifier (ID, URL, filepath) that will be
	; ;                       evaluated with a given (or prompted) type/subType, or in some cases a
	; ;                       full identifier (for example "QAN 123456" - includes both INI [drives
	; ;                       subType and implies type] and ID).
	; ;                       If it is a full identifier, it will be split into distinct parts
	; ;                       (type/subType in respective parameters, ID will contain only partial
	; ;                       identifier).
	; ;  type      (IO,REQ) - The general type that goes with value - from TYPE_* constants.
	; ;  action    (IO,REQ) - The action to perform with the object, from ACTION_* constants.
	; ;  subType   (IO,REQ) - Within the given type, further identifying information, from SUBTYPE_*
	; ;                       constants (or other subTypes defined in actionObject.tls).
	; ;  subAction (IO,REQ) - Within the given action, further information about what to do, from
	; ;                       SUBACTION_* constants.
	; ;---------
	; process(ByRef value, ByRef type, ByRef action, ByRef subType, ByRef subAction) {
		; ; DEBUG.toast("ActionObject.process", "Start", "value", value, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		; ; Do a little preprocessing to pick out needed info.
		; pathType := getPathType(value)
		; ; DEBUG.popup("ActionObject.process","Type preprocessing done", "value",value, "Path type",pathType)
		
		; ; If it's a path, mark it as such.
		; if(pathType) {
			; type    := TYPE_Path
			; subType := pathType
			
		; ; Try and see if it's something we can split into INI/ID (subType/new value)
		; } else {
			; infoAry := extractEMC2ObjectInfoRaw(value)
			; if(infoAry["TITLE"]) ; If there's a title (something beyond just an INI and an ID), this probably isn't an EMC2 object.
				; return
			
			; s := new Selector("actionObject.tls", MainConfig.machineTLFilter)
			; data := s.selectChoice(infoAry["INI"])
			; if(data) {
				; type    := data["TYPE"]
				; subType := data["SUBTYPE"]
				; value   := infoAry["VALUE"]
			; }
		; }
		
		; ; DEBUG.toast("ActionObject.process","Finished", "value",value, "Type",type, "Action",action, "SubType",subType, "SubAction",subAction)
	; }
	
	; ;---------
	; ; DESCRIPTION:    If any key pieces of information about the object are missing, prompt the user
	; ;                 for those missing pieces using a Selector popup.
	; ; PARAMETERS:
	; ;  value     (IO,REQ) - The primary identifying information for the object we want to perform the
	; ;                       action on. Should only be a partial identifier (ID, URL, filepath) by
	; ;                       this point.
	; ;  type      (IO,REQ) - The general type that goes with value - from TYPE_* constants. If not
	; ;                       given, the user will be prompted to choose this.
	; ;  action    (IO,REQ) - The action to perform with the object, from ACTION_* constants.
	; ;  subType   (IO,REQ) - Within the given type, further identifying information, from SUBTYPE_*
	; ;                       constants (or other subTypes defined in actionObject.tls).
	; ;  subAction (IO,REQ) - Within the given action, further information about what to do, from
	; ;                       SUBACTION_* constants.
	; ;---------
	; selectInfo(ByRef value, ByRef type, ByRef action, ByRef subType, ByRef subAction) {
		; ; DEBUG.popup("ActionObject.selectInfo","Start", "value",value, "Type",type, "Action",action, "SubType",subType, "SubAction",subAction)
		
		; ; EMC2 objects require a subType (INI) and subAction (view vs edit)
		; if(type = TYPE_EMC2) {
			; needsSubType   := true
			; needsSubAction := true
		; }
		
		; if(!type || !action || (!subType && needsSubType) || (!subAction && needsSubAction)) {
			; s := new Selector("actionObject.tls", MainConfig.machineTLFilter)
			
			; data := s.selectGui("", "", {SUBTYPE: subType, ID: value})
			; if(!data)
				; return
			
			; subType := data["SUBTYPE"]
			; value   := data["VALUE"]
			
			; ; Type can come out, so grab it iff it was set.
			; if(data["TYPE"])
				; type := data["TYPE"]
		; }
		
		; ; DEBUG.popup("ActionObject.selectInfo","Finish", "value",value, "Type",type, "Action",action, "SubType",subType, "SubAction",subAction)
	; }
	
	; ;---------
	; ; DESCRIPTION:    Perform any needed post-processing to make sure we have clean data to use for our action.
	; ; PARAMETERS:
	; ;  value     (IO,REQ) - The primary identifying information for the object we want to perform the
	; ;                       action on. Should only be a partial identifier (ID, URL, filepath) by
	; ;                       this point.
	; ;  type      (IO,REQ) - The general type that goes with value - from TYPE_* constants.
	; ;  action    (IO,REQ) - The action to perform with the object, from ACTION_* constants.
	; ;  subType   (IO,REQ) - Within the given type, further identifying information, from SUBTYPE_*
	; ;                       constants (or other subTypes defined in actionObject.tls).
	; ;  subAction (IO,REQ) - Within the given action, further information about what to do, from
	; ;                       SUBACTION_* constants.
	; ;---------
	; postProcess(ByRef value, ByRef type, ByRef action, ByRef subType, ByRef subAction) {
		; ; DEBUG.popup("ActionObject.postProcess","Start", "value",value, "type",type, "action",action, "subType",subType, "subAction",subAction)
		
		; if(type = TYPE_EMC2) ; Turn subType (INI) into true INI
			; subType := getTrueEMC2INI(subType)
		
		; if(type = TYPE_Path && subType = SUBTYPE_FilePath)
			; value := cleanupPath(value)
		
		; ; DEBUG.popup("ActionObject.postProcess","Finish", "value",value, "type",type, "action",action, "subType",subType, "subAction",subAction)
	; }
	
	; ;---------
	; ; DESCRIPTION:    Actually perform the action, assuming we have enought information.
	; ; PARAMETERS:
	; ;  value     (I,REQ) - The primary identifying information for the object we want to perform the
	; ;                      action on. Should only be a partial identifier (ID, URL, filepath) by
	; ;                      this point.
	; ;  type      (I,REQ) - The general type that goes with value - from TYPE_* constants.
	; ;  action    (I,REQ) - The action to perform with the object, from ACTION_* constants.
	; ;  subType   (I,REQ) - Within the given type, further identifying information, from SUBTYPE_*
	; ;                      constants (or other subTypes defined in actionObject.tls).
	; ;  subAction (I,REQ) - Within the given action, further information about what to do, from
	; ;                      SUBACTION_* constants.
	; ; RETURNS:        For ACTION_Link, the link. Otherwise, "".
	; ;---------
	; perform(value, type, action, subType, subAction) {
		; ; DEBUG.popup("ActionObject.perform", "Start", "value", value, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		; if(!type || !action)
			; return
		
		; if(action = ACTION_Run) {
			; if(type = TYPE_EMC2 || type = TYPE_EpicStudio || type = TYPE_CodeSearchRoutine || type = TYPE_Helpdesk || type = TYPE_GuruSearch) {
				; link := this.perform(value, type, ACTION_Link, subType, subAction)
				; if(link)
					; Run(link)
				
			; } else if(type = TYPE_Path) {
				; if(subType = SUBTYPE_FilePath) {
					; IfExist, %value%
						; Run(value)
					; Else
						; DEBUG.popup("File or folder does not exist", value)
				; } else if(subType = SUBTYPE_URL) {
					; Run(value)
				; }
			; }
			
		; } else if(action = ACTION_Link) {
			; if(type = TYPE_EMC2) {
				; return buildEMC2Link(subType, value, subAction)
				
			; } else if(type = TYPE_EpicStudio) {
				; if(subType = SUBTYPE_Routine) {
					; splitServerLocation(value, routine, tag)
					; return buildEpicStudioRoutineLink(routine, tag)
				; } else if(subType = SUBTYPE_DLG) {
					; return buildEpicStudioDLGLink(value)
				; }
				
			; } else if(type = TYPE_CodeSearchRoutine) {
				; return buildServerCodeLink(value)
				
			; } else if(type = TYPE_Helpdesk) {
				; return buildHelpdeskLink(value)
				
			; } else if(type = TYPE_GuruSearch) {
				; return buildGuruURL(value)
			; }
			
		; }
	; }
; }