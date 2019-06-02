/* Class for ***
	
	***
*/

; global SUBTYPE_FilePath := "FILEPATH"
; global SUBTYPE_URL      := "URL"
; global SUBTYPE_Routine  := "ROUTINE"
; global SUBTYPE_DLG      := "DLG"
; ; Additional subtypes (EMC2 INIs) can be defined in actionObject.tls.



class ActionObjectPicker {
	
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
	
	
	
	__New(value := "", objectType := "", subType := "") {
		this.value      := value
		this.objectType := objectType
		this.subType    := subType
		
		this.determineType()
		this.selectMissingInfo()
		
		DEBUG.toast("ActionObject","All info determined", "this",this)
		return this.getTypeSpecificObject()
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	value      := ""
	objectType := ""
	subType    := ""
	
	determineType() {
		; Already know the type
		if(this.objectType != "")
			return
		
		; GDB TODO
	}
	
	
	selectMissingInfo() {
		; Nothing is missing
		if(this.value != "" && this.objectType != "")
			return
		
		; GDB TODO do selector, save off value/objectType/subType only if values from selector are non-blank
	}
	
	
	getTypeSpecificObject() {
		if(this.objectType = "") {
			Toast.showError("Could not determine type", "ActionObject was not given a type and could not determine it based on the provided value")
			return ""
		}
		
		if(this.objectType = TYPE_EMC2)
			return new ActionEMC2Object(this.value, this.subType)
		
		Toast.showError("Unrecognized type", "ActionObject doesn't know what to do with this type: " this.objectType)
		return ""
	}
	
}

class ActionObject2 {
	; ==============================
	; == Public ====================
	; ==============================
	
	; GDB TODO document
	static SUBACTION_Edit     := "EDIT"
	static SUBACTION_View     := "VIEW"
	static SUBACTION_Web      := "WEB"
	static SUBACTION_WebBasic := "WEB_BASIC"
	
	
	
	__New(value := "", subType := "") {
		Toast.showError("ActionObject instance created", "ActionObject is a base class only, use a type-specific child class instead.")
		return ""
	}
	
	
	run(runType := "") {
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
		Toast.showError(".getLink() called directly", ".getLink() is not implemented by the parent ActionObject class")
		return ""
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	value   := "" ; GDB TODO document
	subType := ""

}

class ActionEMC2Object extends ActionObject2 {
	; ==============================
	; == Public ====================
	; ==============================
	
	; These properties are required so that the functions from the parent (which use this.subType
	; and this.value) will still work correctly.
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
	
	
	__New(value, subType) {
		this.id  := value
		this.ini := subType
		
		this.selectMissingInfo()
		
		; Post-processing now that we (hopefully) have all info
		this.ini := getTrueEMC2INI(this.ini)
	}
	
	; GDB TODO split this into smaller functions - pick link type, get link based on type (maybe separate switch function to get link base)
	getLink(linkType := "WEB") { ; linkType = ActionObject2.SUBACTION_Web
		if(!this.ini || !this.id)
			return ""
		
		; View basically goes one way or the other depending on INI:
		;  * If it can be viewed in EMC2, use EDIT with a special view-only parameter.
		;  * Otherwise, create a web link instead.
		if(linkType = ActionObject2.SUBACTION_View) {
			if(this.canViewINIInEMC2()) {
				linkType   := ActionObject2.SUBACTION_Edit
				paramString := "&runparams=1"
			} else {
				linkType   := ActionObject2.SUBACTION_Web
			}
		}
		
		; Pick one of the types of links - edit in EMC2 or view in web (summary or Sherlock/Nova).
		if(linkType = ActionObject2.SUBACTION_Edit) {
			link := MainConfig.private["EMC2_LINK_BASE"]
		} else if(linkType = ActionObject2.SUBACTION_Web) {
			if(this.isSherlockINI())
				link := MainConfig.private["SHERLOCK_BASE"]
			else if(this.isNovaINI())
				link := MainConfig.private["NOVA_RELEASE_NOTE_BASE"]
			else
				link := MainConfig.private["EMC2_LINK_WEB_BASE"]
		} else if(linkType = ActionObject2.SUBACTION_WebBasic) {
			link := MainConfig.private["EMC2_LINK_WEB_BASE"]
		}
		
		link .= paramString
		link := replaceTags(link, {"INI":this.ini, "ID":this.id})
		
		return link
	}
	canViewINIInEMC2() {
		if(this.ini = "DLG")
			return true
		if(this.ini = "QAN" || this.ini = "ZQN") ; GDB TODO remove ZQN case once selection/pre-processing is done
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
	
	
	selectMissingInfo() {
		; Nothing is missing
		if(this.id != "" && this.ini != "")
			return
		
		; GDB TODO Do selector, set ini and maybe value (but only if values from selector aren't blank)
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