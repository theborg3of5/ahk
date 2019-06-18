#Include %A_LineFile%\..\actionObjectBase.ahk
#Include %A_LineFile%\..\actionObjectCode.ahk
#Include %A_LineFile%\..\actionObjectEMC2.ahk
#Include %A_LineFile%\..\actionObjectHelpdesk.ahk
#Include %A_LineFile%\..\actionObjectPath.ahk

/* Class that figures out what kind of ActionObject* class is needed based on the input (and prompting the user) and returns it.
	
	Example Usage
		; Determine type based on input
		ao := new ActionObjectRedirector("DLG 123456") ; This will be an EMC2-type object, so ao is an ActionObjectEMC2 instance
		ao.openWeb() ; Open the web version of the object
		
		; Will prompt user for both type and value with Selector popup because neither given
		ao := new ActionObjectRedirector()
		ao.linkSelectedTextWeb() ; Links the selected text with a link built from the specific ActionObject* class in question
*/

class ActionObjectRedirector {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	;---------
	; DESCRIPTION:    Determine the type of ActionObject class to use based on the type/value
	;                 and return a new instance of that class.
	; PARAMETERS:
	;  value (I,OPT) - Input value to evaluate.
	; RETURNS:        An instance of ActionObject* (Code, EMC2, etc.) for the chosen type.
	; NOTES:          This does NOT return an ActionObjectRedirector instance.
	;---------
	__New(value := "") {
		this.value := value
		this.value := getFirstLine(this.value) ; Comes first so that we can clean from end of first line (even if there are multiple).
		this.value := cleanupText(this.value) ; Remove leading/trailing spaces and odd characters from value
		
		this.determineType()
		this.selectMissingInfo()
		
		; DEBUG.toast("ActionObjectRedirector","All info determined", "this",this)
		return this.getTypeSpecificObject()
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	value   := "" ; Value (the unique bit of info to act upon, like a path or identifier)
	type    := "" ; Determined type of ActionObject, from .TYPE_* constants
	subType := "" ; Determined sub-type, an additional categorization within a particular ActionObject* class.
	
	; Type constants
	static TYPE_EMC2     := "EMC2"
	static TYPE_Code     := "CODE" ; EpicStudio for edit, CodeSearch for web
	static TYPE_Helpdesk := "HELPDESK"
	static TYPE_Path     := "PATH"
	
	;---------
	; DESCRIPTION:    Try to determine the type of ActionObject that we'll need based on the input value.
	; SIDE EFFECTS:   tryProcessAs* functions may set .value, .type, and .subType.
	;---------
	determineType() {
		if(this.tryProcessAsRecord()) ; EMC2 objects and helpdesk are in "INI ID *" format
			return
		if(this.tryProcessAsPath()) ; File paths and URLs
			return
	}
	
	;---------
	; DESCRIPTION:    Try to determine whether the value is a path.
	; RETURNS:        True if the value was determined to be a path, False otherwise.
	; SIDE EFFECTS:   Sets .type and .subType if the value was a path.
	;---------
	tryProcessAsPath() {
		pathType := ActionObjectPath.determinePathType(this.value)
		if(pathType = "")
			return false
		
		this.type    := this.TYPE_Path
		this.subType := pathType
		return true
	}
	
	;---------
	; DESCRIPTION:    Try to determine whether the value is a "record" object (EMC2 or helpdesk,
	;                 "INI ID" format).
	; RETURNS:        True if the value was determined to be a "record" object, False otherwise.
	; SIDE EFFECTS:   Sets .type, .subType, and .value if the value was a path.
	;---------
	tryProcessAsRecord() {
		; Try splitting apart string into INI/ID/title
		recordAry := extractEMC2ObjectInfoRaw(this.value) ; GDB TODO can we combine this with the logic from the actual class somehow, like we did with determinePathType()?
		potentialINI := recordAry["INI"]
		
		; Silent selection from actionObject TLS to see if we match a "record" ("INI ID *" format) type.
		s := new Selector("actionObject.tls", MainConfig.machineSelectorFilter)
		data := s.selectChoice(potentialINI)
		if(!data)
			return false
		
		type    := data["TYPE"]
		subType := data["SUBTYPE"]
		
		; Only EMC2 objects and helpdesk can be split and handled this way.
		if((type != this.TYPE_EMC2) && (type != this.TYPE_Helpdesk))
			return false
		
		; We successfully identified the type, store off the pieces we know.
		this.type    := type
		this.subType := subType
		this.value   := recordAry["ID"] ; From first split above
		return true
	}
	
	;---------
	; DESCRIPTION:    Prompt the user for a value and/or type if those values are missing.
	; SIDE EFFECTS:   Sets .type, .subType, and .value based on the user's input.
	;---------
	selectMissingInfo() {
		; Nothing is missing
		if(this.value != "" && this.type != "")
			return
		
		s := new Selector("actionObject.tls", MainConfig.machineSelectorFilter)
		data := s.selectGui("", "", {"TYPE":this.type, "SUBTYPE":this.subType, "VALUE":this.value})
		if(!data)
			return
		
		this.type    := data["TYPE"]
		this.subType := data["SUBTYPE"]
		this.value   := data["VALUE"]
	}
	
	;---------
	; DESCRIPTION:    Create a new ActionObject* instance matching the chosen type.
	; RETURNS:        New instance of an ActionObject* class
	;---------
	getTypeSpecificObject() {
		if(this.type = "")
			return "" ; No determined type, silent quit, return nothing
		
		if(this.type = this.TYPE_Code)
			return new ActionObjectCode(this.value, this.subType)
		
		if(this.type = this.TYPE_EMC2)
			return new ActionObjectEMC2(this.value, this.subType)
		
		if(this.type = this.TYPE_Helpdesk)
			return new ActionObjectHelpdesk(this.value)
		
		if(this.type = this.TYPE_Path)
			return new ActionObjectPath(this.value, this.subType)
		
		Toast.showError("Unrecognized type", "ActionObjectRedirector doesn't know what to do with this type: " this.type)
		return ""
	}
}
