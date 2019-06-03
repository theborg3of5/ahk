/* Class for running or generating a link to an object, based on both functionally-passed and prompted-for information.
	
	This class is a framework that performs a specific set of actions (run/open, return a link to) in certain ways (subActions - edit, view, web mode) for an identified object. The class will attempt to split the main value parameter (value) to gain all information that it requires to fully identify the object and action, but if any of that information is missing, it will prompt the user for it using the Selector class with a list of types/subTypes (from actionObject.tls).
	
	Supported Actions (ACTION_* constants)
		RUN
			Run or open the object.
		LINK
			Generate and return a link to the object.
	
	Supported SubActions (SUBACTION_* constants)
		EDIT
			The action will be done for the object in edit mode. For example, an EMC2 object will be opened in EMC2 (not in view-only mode), or the generated link will open it that way.
		VIEW
			The same as EDIT, except that the object will be opened/linked in read-only mode where applicable.
		WEB
			The web equivalent of the object will be opened/linked. This applies primarily to EMC2 objects, which have corresponding web views.
		WEB_BASIC
			The "basic" web equivalent (instead of anything special like Nova or Sherlock) will be opened/linked. This applies primarily to EMC2 objects, which have corresponding web views.
	
	Supported Types (TYPE_* constants)
		EMC2
			EMC2 objects - DLGs, QANs, etc. These require a subType (which is the INI of the object).
		EPICSTUDIO
			Open something in EpicStudio - a server routine (and optionally tag) or a DLG.
		CODESEARCHROUTINE
			Server routine, to open in CodeSearch.
		HELPDESK
			Helpdesk request (HDR), web only.
		PATH
			A filepath or URL. These require a subType (either FILEPATH or URL), but that subType can usually be determined programmatically.
	
	Supported SubTypes (SUBTYPE_* constants + others in actionObject.tls)
		FILEPATH
			A windows filepath.
		URL
			An internet URL.
		Others from actionObject.tls
			Other SubTypes are defined in actionObject.tls. These are used primarily for EMC2 objects, and are used by buildEMC2Link() at the end of the day.
	
	Example Usage
		; link is EMC2 link to QAN qanId
		link := ActionObject.do(qanId, TYPE_EMC2, ACTION_Link, "QAN", SUBACTION_Web)
		
		; Run (open) the object identified in inputText in edit mode, prompting the user for what type/subtype of object (from TYPE_* and SUBTYPE_*, respectively).
		ActionObject.do(inputText, , ACTION_Run, , SUBACTION_Edit)
*/

global TYPE_Unknown           := ""
global TYPE_EMC2              := "EMC2"
global TYPE_EpicStudio        := "EPICSTUDIO"
global TYPE_CodeSearchRoutine := "CODESEARCHROUTINE"
global TYPE_Helpdesk          := "HELPDESK"
global TYPE_GuruSearch        := "GURU_SEARCH"
global TYPE_Path              := "PATH"

global ACTION_Link := "LINK"
global ACTION_Run  := "RUN"

global SUBTYPE_FilePath := "FILEPATH"
global SUBTYPE_URL      := "URL"
global SUBTYPE_Routine  := "ROUTINE"
global SUBTYPE_DLG      := "DLG"
; Additional subtypes (EMC2 INIs) can be defined in actionObject.tls.

global SUBACTION_Edit     := "EDIT"
global SUBACTION_View     := "VIEW"
global SUBACTION_Web      := "WEB"
global SUBACTION_WebBasic := "WEB_BASIC"


class ActionObject {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	;---------
	; DESCRIPTION:    Identify the intended object based on the given information, prompting the
	;                 user for any missing information needed to identify the object, and perform
	;                 the given action.
	; PARAMETERS:
	;  value     (I,REQ) - The primary identifying information for the object we want to perform the
	;                      action on. Can be a partial identifier (ID, URL, filepath) that will be
	;                      evaluated with a given (or prompted) type/subType, or in some cases a
	;                      full identifier (for example "QAN 123456" - includes both INI [drives
	;                      subType and implies type] and ID).
	;  type      (I,OPT) - The general type that goes with value - from TYPE_* constants. If not
	;                      given, the user will be prompted to choose this.
	;  action    (I,OPT) - The action to perform with the object, from ACTION_* constants.
	;  subType   (I,OPT) - Within the given type, further identifying information, from SUBTYPE_*
	;                      constants (or other subTypes defined in actionObject.tls).
	;  subAction (I,OPT) - Within the given action, further information about what to do, from
	;                      SUBACTION_* constants.
	; RETURNS:        For ACTION_Link, the link. Otherwise, "".
	;---------
	do(value, type := "", action := "", subType := "", subAction := "") {
		; DEBUG.popup("ActionObject.do", "Start", "value", value, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		; Clean up value.
		value := getFirstLine(value) ; Comes first so that we can clean from end of first line (even if there are multiple).
		value := cleanupText(value)
		
		; Determine what we need to do.
		this.process(value, type, action, subType, subAction)
		
		; Expand shortcuts and gather more info as needed.
		this.selectInfo(value, type, action, subType, subAction)
		
		this.postProcess(value, type, action, subType, subAction)
		
		; Just do it.
		return this.perform(value, type, action, subType, subAction)
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	;---------
	; DESCRIPTION:    Go through all given information and determine as many distinct properties
	;                 about the object and action as we can.
	; PARAMETERS:
	;  value     (IO,REQ) - The primary identifying information for the object we want to perform the
	;                       action on. Can be a partial identifier (ID, URL, filepath) that will be
	;                       evaluated with a given (or prompted) type/subType, or in some cases a
	;                       full identifier (for example "QAN 123456" - includes both INI [drives
	;                       subType and implies type] and ID).
	;                       If it is a full identifier, it will be split into distinct parts
	;                       (type/subType in respective parameters, ID will contain only partial
	;                       identifier).
	;  type      (IO,REQ) - The general type that goes with value - from TYPE_* constants.
	;  action    (IO,REQ) - The action to perform with the object, from ACTION_* constants.
	;  subType   (IO,REQ) - Within the given type, further identifying information, from SUBTYPE_*
	;                       constants (or other subTypes defined in actionObject.tls).
	;  subAction (IO,REQ) - Within the given action, further information about what to do, from
	;                       SUBACTION_* constants.
	;---------
	process(ByRef value, ByRef type, ByRef action, ByRef subType, ByRef subAction) {
		; DEBUG.popup("ActionObject.process", "Start", "value", value, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		; Do a little preprocessing to pick out needed info.
		pathType := getPathType(value)
		; DEBUG.popup("ActionObject.process","Type preprocessing done", "value",value, "Path type",pathType)
		
		; If it's a path, mark it as such.
		if(pathType) {
			type    := TYPE_Path
			subType := pathType
			
		; Try and see if it's something we can split into INI/ID (subType/new value)
		} else {
			infoAry := extractEMC2ObjectInfoRaw(value)
			if(infoAry["TITLE"]) ; If there's a title (something beyond just an INI and an ID), this probably isn't an EMC2 object.
				return
			
			s := new Selector("actionObject.tls", MainConfig.machineTLFilter)
			data := s.selectChoice(infoAry["INI"])
			if(data) {
				type    := data["TYPE"]
				subType := data["SUBTYPE"]
				
				; ID for record becomes new value (but only if we found a legitimate INI to match it with)
				value := infoAry["ID"]
			}
		}
		
		; DEBUG.popup("ActionObject.process","Finished", "value",value, "Type",type, "Action",action, "SubType",subType, "SubAction",subAction)
	}
	
	;---------
	; DESCRIPTION:    If any key pieces of information about the object are missing, prompt the user
	;                 for those missing pieces using a Selector popup.
	; PARAMETERS:
	;  value     (IO,REQ) - The primary identifying information for the object we want to perform the
	;                       action on. Should only be a partial identifier (ID, URL, filepath) by
	;                       this point.
	;  type      (IO,REQ) - The general type that goes with value - from TYPE_* constants. If not
	;                       given, the user will be prompted to choose this.
	;  action    (IO,REQ) - The action to perform with the object, from ACTION_* constants.
	;  subType   (IO,REQ) - Within the given type, further identifying information, from SUBTYPE_*
	;                       constants (or other subTypes defined in actionObject.tls).
	;  subAction (IO,REQ) - Within the given action, further information about what to do, from
	;                       SUBACTION_* constants.
	;---------
	selectInfo(ByRef value, ByRef type, ByRef action, ByRef subType, ByRef subAction) {
		; DEBUG.popup("ActionObject.selectInfo","Start", "value",value, "Type",type, "Action",action, "SubType",subType, "SubAction",subAction)
		
		; EMC2 objects require a subType (INI) and subAction (view vs edit)
		if(type = TYPE_EMC2) {
			needsSubType   := true
			needsSubAction := true
		}
		
		if(!type || !action || (!subType && needsSubType) || (!subAction && needsSubAction)) {
			s := new Selector("actionObject.tls", MainConfig.machineTLFilter)
			
			data := s.selectGui("", "", {"SUBTYPE": subType, "VALUE": value})
			if(!data)
				return
			
			subType := data["SUBTYPE"]
			value   := data["VALUE"]
			
			; Type can come out, so grab it if it was set.
			if(data["TYPE"])
				type := data["TYPE"]
		}
		
		; DEBUG.popup("ActionObject.selectInfo","Finish", "value",value, "Type",type, "Action",action, "SubType",subType, "SubAction",subAction)
	}
	
	;---------
	; DESCRIPTION:    Perform any needed post-processing to make sure we have clean data to use for our action.
	; PARAMETERS:
	;  value     (IO,REQ) - The primary identifying information for the object we want to perform the
	;                       action on. Should only be a partial identifier (ID, URL, filepath) by
	;                       this point.
	;  type      (IO,REQ) - The general type that goes with value - from TYPE_* constants.
	;  action    (IO,REQ) - The action to perform with the object, from ACTION_* constants.
	;  subType   (IO,REQ) - Within the given type, further identifying information, from SUBTYPE_*
	;                       constants (or other subTypes defined in actionObject.tls).
	;  subAction (IO,REQ) - Within the given action, further information about what to do, from
	;                       SUBACTION_* constants.
	;---------
	postProcess(ByRef value, ByRef type, ByRef action, ByRef subType, ByRef subAction) {
		; DEBUG.popup("ActionObject.postProcess","Start", "value",value, "type",type, "action",action, "subType",subType, "subAction",subAction)
		
		if(type = TYPE_EMC2) ; Turn subType (INI) into true INI
			subType := getTrueEMC2INI(subType)
		
		if(type = TYPE_Path && subType = SUBTYPE_FilePath)
			value := cleanupPath(value)
		
		; DEBUG.popup("ActionObject.postProcess","Finish", "value",value, "type",type, "action",action, "subType",subType, "subAction",subAction)
	}
	
	;---------
	; DESCRIPTION:    Actually perform the action, assuming we have enought information.
	; PARAMETERS:
	;  value     (I,REQ) - The primary identifying information for the object we want to perform the
	;                      action on. Should only be a partial identifier (ID, URL, filepath) by
	;                      this point.
	;  type      (I,REQ) - The general type that goes with value - from TYPE_* constants.
	;  action    (I,REQ) - The action to perform with the object, from ACTION_* constants.
	;  subType   (I,REQ) - Within the given type, further identifying information, from SUBTYPE_*
	;                      constants (or other subTypes defined in actionObject.tls).
	;  subAction (I,REQ) - Within the given action, further information about what to do, from
	;                      SUBACTION_* constants.
	; RETURNS:        For ACTION_Link, the link. Otherwise, "".
	;---------
	perform(value, type, action, subType, subAction) {
		; DEBUG.popup("ActionObject.perform", "Start", "value", value, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		if(!type || !action)
			return
		
		if(action = ACTION_Run) {
			if(type = TYPE_EMC2 || type = TYPE_EpicStudio || type = TYPE_CodeSearchRoutine || type = TYPE_Helpdesk || type = TYPE_GuruSearch) {
				link := this.perform(value, type, ACTION_Link, subType, subAction)
				if(link)
					Run(link)
				
			} else if(type = TYPE_Path) {
				if(subType = SUBTYPE_FilePath) {
					IfExist, %value%
						Run(value)
					Else
						DEBUG.popup("File or folder does not exist", value)
				} else if(subType = SUBTYPE_URL) {
					Run(value)
				}
			}
			
		} else if(action = ACTION_Link) {
			if(type = TYPE_EMC2) {
				return buildEMC2Link(subType, value, subAction)
				
			} else if(type = TYPE_EpicStudio) {
				if(subType = SUBTYPE_Routine) {
					splitServerLocation(value, routine, tag)
					return buildEpicStudioRoutineLink(routine, tag)
				} else if(subType = SUBTYPE_DLG) {
					return buildEpicStudioDLGLink(value)
				}
				
			} else if(type = TYPE_CodeSearchRoutine) {
				return buildServerCodeLink(value)
				
			} else if(type = TYPE_Helpdesk) {
				return buildHelpdeskLink(value)
				
			} else if(type = TYPE_GuruSearch) {
				return buildGuruURL(value)
			}
			
		}
	}
}