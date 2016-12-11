/* Generic, flexible custom class for running or linking to an object, based on both functionally-passed and prompted-for text.
	
	The programmatic entry point is ActionObject.do().
	
	Certain characters have special meaning when parsing the lines of a file. They include:
		= - Title
			This character starts a line that will be the title shown on the popup UI as a whole.
		
		# - Label
			This character starts a line that will be shown as a section label in the UI (to group individual choices).
		
		| - Abbreviation delimiter
			You can give an individual choice multiple abbreviations that will work for the user, separated by this character. Only the first one will be displayed, however.
		
		* - Hidden
			Putting this character at the start of a line will hide that choice from the UI, but still allow it to be selected via its abbreviation.
		
		( - Model
			You can have more than the simple layout of NAME-ABBREV-ACTION by using a model row that begins with this character. This line is tab-separated in the same way as the choices, with each entry being the name for the corresponding column of each choice.
		
		) - Model Index
			This row corresponds to the model row, giving each of the named columns an index, which is the order in which the additional arbitrary fields in the UI (turned on using +ShowArbitraryInputs, see settings below) will be shown. An index of 0 tells the UI not to show the field corresponding to that column at all.
		
		| - New column (in label row)
			If this character is put at the beginning of a label row (with a space on either side, such as "# | Title"), that label will force a new column in the UI.
		
		+ - Settings
			Lines which start with this character denote a setting that changes how the UI acts in some manner. They are always in the form "+Option=x", and include:
				ShowArbitraryInputs
					If set to 1, the UI will show an additional input box on the UI for each piece defined by the model row (excluding NAME, ABBREV, and ACTION). Note that these will be shown in the order they are listed by the model row, unless a model index row is present, at which point it respects that.
				
				RowsPerColumn
					Set this to any number X to have the UI start a new column when it hits that many rows in the current column. Note that the current section label will carry over with a (2) if it's the first time it's been broken across columns, (3) if it's the second time, etc.
				
				ColumnWidth
					Set this to any number X to have the UI be X pixels wide (per column if multiple columns are shown).
				
				TrayIcon
					Set this to a path or icon filename to use that icon in the tray.
				
				DefaultAction
					The default action that should be taken when this INI is used. Can be overridden by passing one into .select() directly.
	
	When the user selects their choice, the action passed in at the beginning will be evaluated as a function which receives a loaded SelectorRow object to perform the action on. See SelectorRow class for data structure.
	
	Once the UI is shown, the user can enter either the index or abbreviation for the choice that they would like to select. The user can give information to the popup in a variety of ways:
		Simplest case (+ShowArbitraryInputs != 1, no model or model index rows):
			The user will only have a single input box, where they can add their choice and additional input using the arbitrary character (see below)
			Resulting SelectorRow object will have the name, abbreviation, and action. Arbitrary input is added to the end of the action.
		
		Model row, but +ShowArbitraryInputs != 1
			The user still has a single input box.
			Resulting SelectorRow will have the various pieces in named subscripts of its data array, where the names are those from the model row. Note that name and abbreviation are still separate from the data array, and arbitrary additions are added to action, whether it is set or not.
		
		Model row, with +ShowArbitraryInputs=1 (model index row optional)
			The user will see multiple input boxes, in the order listed in the input file, or in the order of the model index row if defined. The user can override the values defined by the selected choice for each of the columns shown before the requested action is performed.
			Resulting SelectorRow will have the various pieces in named subscripts of its data array, where the names are those from the model row. Note that name and abbreviation are still separate from the data array, and arbitrary additions are ignored entirely (as the user can use the additional inputs instead).
		
	The input that the user puts in the first (sometimes only) input box can also include some special characters:
		
		. - Arbitrary
			Ingored if +ShowArbitraryInputs=1. Allows the user to add additional information to the end of the action eventually performed on the given choice.
		
		+ - Special actions
			These are special changes that can be made to the choice/UI at runtime, when the user is interacting with the UI. They include:
				e - edit
					Putting +e in the input will open the input file. If this is something like a txt or ini file, then it should open in a text editor.
				
				d - debug
					This will send the SelectorRow object to the function as usual, but with the isDebug flag set to true. Note that it's up to the called function to check this flag and send back debug info (stored in SelectorRow.debugResult) rather than actually performing the action, so if you add your own, be sure to include this check or else this option won't work. See selectorActions.ahk for more details.
					Selector will show that result (if given) using DEBUG.popup() (requires debug.ahk).
	
*/

global SUPERTYPE_EPIC := "EPIC"

global TYPE_UNKNOWN        := ""
global TYPE_EMC2           := "EMC2"
global TYPE_SERVER_ROUTINE := "SERVER_ROUTINE"
global TYPE_PATH           := "PATH"

global ACTION_NONE := ""
global ACTION_LINK := "LINK"
global ACTION_RUN  := "RUN"

global SUBTYPE_FILEPATH := "FILEPATH"
global SUBTYPE_URL      := "URL"

global SUBACTION_EDIT := "EDIT"
global SUBACTION_VIEW := "VIEW"
global SUBACTION_WEB  := "WEB"


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
			ActionObject.do(123456, TYPE_EMC2, ACTION_LINK, "DLG", SUBACTION_VIEW)
	*/
	do(input, type = "", action = "", subType = "", subAction = "") { ; type = TYPE_UNKNOWN, action = ACTION_NONE
		; DEBUG.popup("ActionObject.do", "Start", "Input", input, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		; Determine what we need to do.
		this.process(input, type, action, subType, subAction)
		
		; Expand shortcuts and gather more info as needed.
		this.selectInfo(input, type, action, subType, subAction)
		
		; Just do it.
		return this.perform(type, action, subType, subAction, input)
	}
	
	; Based on the parameters given, determines as many missing pieces as we can.
	process(ByRef input, ByRef type, ByRef action, ByRef subType, ByRef subAction) {
		; DEBUG.popup("ActionObject.process", "Start", "Input", input, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		; If we already have all the info we need, leave.
		if((type != "") && (action != "") && ((subType != "") || !needsST) && ((subAction != "") || !needsSA))
			return
		
		; Do a little preprocessing to pick out needed info. (All args but input are ByRef)
		isPathType := isPath(input, pathType)
		isServerRoutineType := isServerRoutine(input, routine, tag)
		isEMC2ObjectType := isEMC2Object(input, ini, id)
		; DEBUG.popup("ActionObject.process", "Type preprocessing done", "Input", input, "Is path", isPathType, "Path type", pathType, "Is server", isServerRoutineType, "Routine", routine, "Tag", tag, "Is EMC2", isEMC2ObjectType, "INI", ini, "ID", id)
		
		; First, if there's no type (or a supertype), figure out what it is.
		if(type = "") {
			if(isPathType)
				type := TYPE_PATH
			else if(isEMC2ObjectType = 2)
				type := TYPE_EMC2
			else if(isServerRoutineType)
				type := TYPE_SERVER_ROUTINE
			else if(isEMC2ObjectType = 1) ; Not specific enough, but false positive OK considering its high usage.
				type := TYPE_EMC2
		; Only test epic things.
		} else if(type = SUPERTYPE_EPIC) {
			if(isServerRoutineType) 
				type := TYPE_SERVER_ROUTINE
			else if(isEMC2ObjectType) ; Not specific enough, but false positive OK considering its high usage.
				type := TYPE_EMC2
		}
		; DEBUG.popup("ActionObject.process", "Type", "Input", input, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		; Next, determine actions.
		if(action = "") {
			if (type = TYPE_PATH)
			|| (type = TYPE_SERVER_ROUTINE)
			|| (type = TYPE_EMC2)
			{
				action := ACTION_RUN
			}
		}
		; DEBUG.popup("ActionObject.process", "Action", "Input", input, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		; Determine subType as needed.
		if(subType = "") {
			if(type = TYPE_SERVER_ROUTINE)
				subType := tag
			else if(type = TYPE_EMC2)
				subType := ini
			else if(type = TYPE_PATH)
				subType := pathType
		}
		; DEBUG.popup("ActionObject.process", "Subtype", "Input", input, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		; Determine subAction as needed.
		if(subAction = "") {
			if (type = TYPE_SERVER_ROUTINE)
			|| (type = TYPE_EMC2)
			{
				subAction := SUBACTION_EDIT
			}
		}
		; DEBUG.popup("ActionObject.process", "Subaction", "Input", input, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		; Update input as needed.
		if(type = TYPE_EMC2)
			input := id
		else if(type = TYPE_SERVER_ROUTINE)
			input := routine
		; DEBUG.popup("ActionObject.process", "Input", "Input", input, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
	}
	
	; Prompt the user for any missing info (generally just subType) via a Selector popup.
	selectInfo(ByRef input, ByRef type, ByRef action, ByRef subType, ByRef subAction) {
		; DEBUG.popup("ActionObject.selectInfo", "Start", "Input", input, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		; Determine if we need subType or subAction based on what we know so far.
		if(type = TYPE_EMC2) {
			needsST := true
			needsSA := true
		} else if(type = TYPE_SERVER_ROUTINE) {
			if(action = ACTION_LINK)
				needsSA := true
		}
		
		; While here later on? Doesn't fit in selector's single-minded aspect right now.
		if(!type || !action || (!subType && needsST) || (!subAction && needsSA)) {
			objInfo   := Selector.select("local/actionObject.tl", "RET_DATA", "", "", {TYPE: type, ACTION: action, SUBTYPE: subType, SUBACTION: subAction, ID: input})
			type      := objInfo["TYPE"]
			action    := objInfo["ACTION"]
			subType   := objInfo["SUBTYPE"]
			subAction := objInfo["SUBACTION"]
			input     := objInfo["ID"]
		}
		
		; Additional processing on user-given info as needed.
		if(type = TYPE_EMC2) { ; EMC2 - subType might need conversion (QAN->ZQN, etc)
			if(subType) { ; But if it's blank, don't ask the user again.
				objInfo := Selector.select("local/actionObject.tl", "RET_DATA", subType)
				subType := objInfo["SUBTYPE"]
			}
		}
	}
	
	; Do the action.
	perform(type, action, subType, subAction, input) {
		; DEBUG.popup("ActionObject.perform", "Start", "Input", input, "Type", type, "Action", action, "SubType", subType, "SubAction", subAction)
		
		if(action = ACTION_NONE) {
			return
		} else if(action = ACTION_RUN) {
			if(type = TYPE_SERVER_ROUTINE) {
				openEpicStudioRoutine( , input, subType)
				
			} else if(type = TYPE_EMC2) {
				; If they never gave us a subtype, just fail silently.
				if(!subType)
					return
				
				link := this.perform(TYPE_EMC2, ACTION_LINK, subType, subAction, input)
				; DEBUG.popup("actionObject.perform", "Got link to run", "Link", link)
				
				if((subAction != SUBACTION_WEB) && !WinExist("ahk_class ThunderRT6MDIForm", , "Hyperspace")) ; Launch EMC2 if it's not running.
					RunWait, % BorgConfig.getProgram("EMC2", "PATH")
				
				Run, % link
				
			} else if(type = TYPE_PATH) {
				if(subType = SUBTYPE_FILEPATH) {
					IfExist, %input%
						Run, % input
					Else
						this.errPop("File or folder does not exist", input)
				} else if(subType = SUBTYPE_URL) {
					Run, % input
				}
				
			} else {
				Run, % input
			}
			
		} else if(action = ACTION_LINK) {
			if(type = TYPE_SERVER_ROUTINE) {
				routine := input
				tag := subType
				link := codeSearchURLBase
				link .= routine "#" tag
			} else if(type = TYPE_EMC2) {
				ini := subType
				id := input
				
				; Add the edit/view/web arguments.
				if((subAction = SUBACTION_EDIT) || !subAction) ; Edit is the default.
					link := emc2LinkBase ini "/" id "?action=EDIT"
				else if(subAction = SUBACTION_VIEW && ( (ini = "DLG") || (ini = "ZQN") || (ini = "XDS") )) ; EMC2 supports view-only mode for these INIs.
					link := emc2LinkBase ini "/" id "?action=EDIT&runparams=1"
				else if(subAction = SUBACTION_WEB || subAction = SUBACTION_VIEW)
					link := emc2LinkBaseWeb ini "/" id
			}
			
			return link
		} else if(type || action || subType || subAction || input) {
			this.errPop("Missing", "Type", "Type", type, "Action", action, "Subtype", subType, "Subaction", subAction, "Input", input)
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