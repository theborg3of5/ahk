/* Generic, flexible custom class for running or linking to an object, based on both functionally-passed and prompted-for text.
	
	The programmatic entry point is ActionObject.do().
*/

global TYPE_Unknown           := ""
global TYPE_EMC2              := "EMC2"
global TYPE_EpicStudio        := "EPICSTUDIO"
global TYPE_CodeSearchRoutine := "CODESEARCHROUTINE"
global TYPE_Helpdesk          := "HELPDESK"
global TYPE_Path              := "PATH"

global ACTION_Link := "LINK"
global ACTION_Run  := "RUN"

global SUBTYPE_FilePath := "FILEPATH"
global SUBTYPE_URL      := "URL"

global SUBACTION_Edit := "EDIT"
global SUBACTION_View := "VIEW"
global SUBACTION_Web  := "WEB"


; Class that centralizes the ability to link to/do a variety of things based on some given text.
class ActionObject {
	; input is either full string, or if action/subaction known, just the main piece (sans actions)
	/* DESCRIPTION:   Main programmatic access point. Calls into helper functions that process given input, prompt for more as needed, then perform the action.
		PARAMETERS:
			input     - The identifier for the thing that we're opening or linking to - can be an ID, URL, filepath, etc.
			type      - From TYPE_* constants above: general type of input.
			action    - From ACTION_* constants above: what you want to actually do with input.
			subType   - From SUBTYPE_* constants above: within a given type, further divisions.
			subAction - From SUBACTION_* constants above: within a given action, further divisions.
		Example: view-only link to DLG 123456:
			ActionObject.do(123456, TYPE_EMC2, ACTION_Link, "DLG", SUBACTION_View)
	*/
	do(input, type = "", action = "", subType = "", subAction = "") {
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
	
	; Based on the parameters given, determines as many missing pieces as we can.
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
	
	; Prompt the user for any missing info via a Selector popup.
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
			
			data := s.selectGui("", "", "", {SUBTYPE: subType, ID: input})
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
	
	; Do any post-processing now that we (hopefully) have all the info we need.
	postProcess(ByRef input, ByRef type, ByRef action, ByRef subType, ByRef subAction) {
		if(type = TYPE_EMC2) ; Turn subType (INI) into true INI
			subType := getTrueINI(subType)
		
		if(type = TYPE_Path && subType = SUBTYPE_FilePath)
			input := cleanupPath(input)
	}
	
	; Do the action.
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
						this.errPop("File or folder does not exist", input)
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
	
	errPop(params*) {
		if(isFunc("DEBUG.popup")) {
			DEBUG.popup(params*)
		} else {
			errMsg := ""
			For i,p in params {
				if(mod(i, 2) = 0)
					Continue
				errMsg .= p "`n`t" params[i + 1] "`n"
			}
			MsgBox, % errMsg
		}
	}
}