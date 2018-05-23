/* Class for running or generating a link to an object, based on both functionally-passed and prompted-for information.
	
	This class is a framework that performs a specific set of actions (run/open, return a link to) in certain ways (subActions - edit, view, web mode) for an identified object. The class will attempt to split the main input parameter (input) to gain all information that it requires to fully identify the object and action, but if any of that information is missing, it will prompt the user for it using the Selector class with a list of types/subTypes (from actionObject.tl).
	
	Supported Actions (ACTION_* constants)
		RUN
			Run or open the object.
		LINK
			Generate and return a link to the object.
	
	Supported SubActions (SUBACTION_* constants)
		EDIT
			The action will be done for the object in edit mode. For example, an EMC2 object will be opened in EMC2 (not in view-only mode), or the generated link will open it that way.
		VIEW
			The same as EDIT, except that the object will be opened in read-only mode where applicable.
		WEB
			The web equivalent of the object will be opened. This applies primarily to EMC2 objects, which have corresponding web views.
	
	Supported Types (TYPE_* constants)
		EMC2
			EMC2 objects - DLGs, QANs, etc. These require a subType (which is the INI of the object).
		EPICSTUDIO
			Server routine, to be opened in EpicStudio.
		CODESEARCHROUTINE
			Server routine, to open in CodeSearch.
		HELPDESK
			Helpdesk request (HDR), web only.
		PATH
			A filepath or URL. These require a subType (either FILEPATH or URL), but that subType can usually be determined programmatically.
	
	Supported SubTypes (SUBTYPE_* constants + others in actionObject.tl)
		FILEPATH
			A windows filepath.
		URL
			An internet URL.
		Others from actionObject.tl
			Other SubTypes are defined in actionObject.tl. These are used primarily for EMC2 objects, and are used by buildEMC2Link() at the end of the day.
	
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
global TYPE_Path              := "PATH"

global ACTION_Link := "LINK"
global ACTION_Run  := "RUN"

; Additional subtypes (EMC2 INIs) defined in actionObject.tl.
global SUBTYPE_FilePath := "FILEPATH"
global SUBTYPE_URL      := "URL"

global SUBACTION_Edit := "EDIT"
global SUBACTION_View := "VIEW"
global SUBACTION_Web  := "WEB"


class ActionObject {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	;---------
	; DESCRIPTION:    Identify the intended object based on the given information, prompting the
	;                 user for any missing information needed to identify the object, and perform
	;                 the given action.
	; PARAMETERS:
	;  input     (I,REQ) - The primary identifying information for the object we want to perform the
	;                      action on. Can be a partial identifier (ID, URL, filepath) that will be
	;                      evaluated with a given (or prompted) type/subType, or in some cases a
	;                      full identifier (for example "QAN 123456" - includes both INI [drives
	;                      subType and implies type] and ID).
	;  type      (I,OPT) - The general type that goes with input - from TYPE_* constants. If not
	;                      given, the user will be prompted to choose this.
	;  action    (I,OPT) - The action to perform with the object, from ACTION_* constants.
	;  subType   (I,OPT) - Within the given type, further identifying information, from SUBTYPE_*
	;                      constants (or other subTypes defined in actionObject.tl).
	;  subAction (I,OPT) - Within the given action, further information about what to do, from
	;                      SUBACTION_* constants.
	; RETURNS:        For ACTION_Link, the link. Otherwise, "".
	;---------
	do(input, type := "", action := "", subType := "", subAction := "") {
		; DEBUG.popup("ActionObject.do", "Start", "Input", input, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		; Clean up input.
		input := getFirstLine(input) ; Comes first so that we can clean from end of first line (even if there are multiple).
		input := cleanupText(input)
		
		; Determine what we need to do.
		this.process(input, type, action, subType, subAction)
		
		; Expand shortcuts and gather more info as needed.
		this.selectInfo(input, type, action, subType, subAction)
		
		this.postProcess(input, type, action, subType, subAction)
		
		; Just do it.
		return this.perform(type, action, subType, subAction, input)
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	;---------
	; DESCRIPTION:    Go through all given information and determine as many distinct properties
	;                 about the object and action as we can.
	; PARAMETERS:
	;  input     (IO,REQ) - The primary identifying information for the object we want to perform the
	;                       action on. Can be a partial identifier (ID, URL, filepath) that will be
	;                       evaluated with a given (or prompted) type/subType, or in some cases a
	;                       full identifier (for example "QAN 123456" - includes both INI [drives
	;                       subType and implies type] and ID).
	;                       If it is a full identifier, it will be split into distinct parts
	;                       (type/subType in respective parameters, ID will contain only partial
	;                       identifier).
	;  type      (IO,REQ) - The general type that goes with input - from TYPE_* constants.
	;  action    (IO,REQ) - The action to perform with the object, from ACTION_* constants.
	;  subType   (IO,REQ) - Within the given type, further identifying information, from SUBTYPE_*
	;                       constants (or other subTypes defined in actionObject.tl).
	;  subAction (IO,REQ) - Within the given action, further information about what to do, from
	;                       SUBACTION_* constants.
	;---------
	process(ByRef input, ByRef type, ByRef action, ByRef subType, ByRef subAction) {
		; DEBUG.popup("ActionObject.process", "Start", "Input", input, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		; Do a little preprocessing to pick out needed info. (All args but input are ByRef)
		pathType := getPathType(input)
		isEMC2ObjectType := isEMC2Object(input, ini, id)
		; DEBUG.popup("ActionObject.process", "Type preprocessing done", "Input", input, "Path type", pathType, "Is EMC2", isEMC2ObjectType, "INI", ini, "ID", id)
		
		; First, if there's no type, try to figure out what it is.
		if(type = "") {
			if(pathType)
				type := TYPE_Path
			else if(isEMC2ObjectType)
				type := TYPE_EMC2
		}
		; DEBUG.popup("ActionObject.process", "Type", "Input", input, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		; Next, determine actions.
		if(action = "") {
			if (type = TYPE_Path)
			|| (type = TYPE_EMC2)
			{
				action := ACTION_Run
			}
		}
		; DEBUG.popup("ActionObject.process", "Action", "Input", input, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		; Determine subType as needed.
		if(subType = "") {
			if(type = TYPE_EMC2)
				subType := ini
			else if(type = TYPE_Path)
				subType := pathType
		}
		; DEBUG.popup("ActionObject.process", "Subtype", "Input", input, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		; Determine subAction as needed.
		if(subAction = "") {
			if(type = TYPE_EMC2)
				subAction := SUBACTION_Edit
		}
		; DEBUG.popup("ActionObject.process", "Subaction", "Input", input, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		; Update input as needed.
		if(type = TYPE_EMC2)
			input := id
		; DEBUG.popup("ActionObject.process", "Input", "Input", input, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
	}
	
	;---------
	; DESCRIPTION:    If any key pieces of information about the object are missing, prompt the user
	;                 for those missing pieces using a Selector popup.
	; PARAMETERS:
	;  input     (IO,REQ) - The primary identifying information for the object we want to perform the
	;                       action on. Should only be a partial identifier (ID, URL, filepath) by
	;                       this point.
	;  type      (IO,REQ) - The general type that goes with input - from TYPE_* constants. If not
	;                       given, the user will be prompted to choose this.
	;  action    (IO,REQ) - The action to perform with the object, from ACTION_* constants.
	;  subType   (IO,REQ) - Within the given type, further identifying information, from SUBTYPE_*
	;                       constants (or other subTypes defined in actionObject.tl).
	;  subAction (IO,REQ) - Within the given action, further information about what to do, from
	;                       SUBACTION_* constants.
	;---------
	selectInfo(ByRef input, ByRef type, ByRef action, ByRef subType, ByRef subAction) {
		; DEBUG.popup("ActionObject.selectInfo","Start", "Input",input, "Type",type, "Action",action, "SubType",subType, "SubAction",subAction)
		
		; EMC2 objects require a subType (INI) and subAction (view vs edit)
		if(type = TYPE_EMC2) {
			needsSubType   := true
			needsSubAction := true
		}
		
		if(!type || !action || (!subType && needsSubType) || (!subAction && needsSubAction)) {
			filter := MainConfig.getMachineTableListFilter()
			s := new Selector("actionObject.tl", filter)
			
			data := s.selectGui("", "", {SUBTYPE: subType, ID: input})
			if(!data)
				return
			
			subType := data["SUBTYPE"]
			input   := data["ID"]
			
			; Type can come out, so grab it iff it was set.
			if(data["TYPE"])
				type := data["TYPE"]
		}
		
		; DEBUG.popup("ActionObject.selectInfo","Finish", "Input",input, "Type",type, "Action",action, "SubType",subType, "SubAction",subAction)
	}
	
	;---------
	; DESCRIPTION:    Perform any needed post-processing to make sure we have clean data to use for our action.
	; PARAMETERS:
	;  input     (IO,REQ) - The primary identifying information for the object we want to perform the
	;                       action on. Should only be a partial identifier (ID, URL, filepath) by
	;                       this point.
	;  type      (IO,REQ) - The general type that goes with input - from TYPE_* constants.
	;  action    (IO,REQ) - The action to perform with the object, from ACTION_* constants.
	;  subType   (IO,REQ) - Within the given type, further identifying information, from SUBTYPE_*
	;                       constants (or other subTypes defined in actionObject.tl).
	;  subAction (IO,REQ) - Within the given action, further information about what to do, from
	;                       SUBACTION_* constants.
	;---------
	postProcess(ByRef input, ByRef type, ByRef action, ByRef subType, ByRef subAction) {
		if(type = TYPE_EMC2) ; Turn subType (INI) into true INI
			subType := getTrueINI(subType)
		
		if(type = TYPE_Path && subType = SUBTYPE_FilePath)
			input := cleanupPath(input)
	}
	
	;---------
	; DESCRIPTION:    Actually perform the action, assuming we have enought information.
	; PARAMETERS:
	;  input     (I,REQ) - The primary identifying information for the object we want to perform the
	;                      action on. Should only be a partial identifier (ID, URL, filepath) by
	;                      this point.
	;  type      (I,REQ) - The general type that goes with input - from TYPE_* constants.
	;  action    (I,REQ) - The action to perform with the object, from ACTION_* constants.
	;  subType   (I,REQ) - Within the given type, further identifying information, from SUBTYPE_*
	;                      constants (or other subTypes defined in actionObject.tl).
	;  subAction (I,REQ) - Within the given action, further information about what to do, from
	;                      SUBACTION_* constants.
	; RETURNS:        For ACTION_Link, the link. Otherwise, "".
	;---------
	perform(type, action, subType, subAction, input) {
		; DEBUG.popup("ActionObject.perform", "Start", "Input", input, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		if(!type || !action)
			return
		
		if(action = ACTION_Run) {
			if(type = TYPE_EMC2 || type = TYPE_CodeSearchRoutine || type = TYPE_Helpdesk) {
				link := this.perform(type, ACTION_Link, subType, subAction, input)
				if(link)
					Run(link)
				
			} else if(type = TYPE_Path) {
				if(subType = SUBTYPE_FilePath) {
					IfExist, %input%
						Run(input)
					Else
						DEBUG.popup("File or folder does not exist", input)
				} else if(subType = SUBTYPE_URL) {
					Run(input)
				}
				
			} else if(type = TYPE_EpicStudio) {
				splitServerLocation(input, routine, tag)
				openEpicStudioRoutine(routine, tag)
			}
			
		} else if(action = ACTION_Link) {
			if(type = TYPE_EMC2) {
				return buildEMC2Link(subType, input, subAction)
				
			} else if(type = TYPE_CodeSearchRoutine) {
				return buildServerCodeLink(input)
				
			} else if(type = TYPE_Helpdesk) {
				return buildHelpdeskLink(input)
			}
			
		}
	}
}