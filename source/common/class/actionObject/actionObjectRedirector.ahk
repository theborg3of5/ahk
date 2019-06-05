#Include %A_LineFile%\..\actionObjectBase.ahk
#Include %A_LineFile%\..\actionObjectCode.ahk
#Include %A_LineFile%\..\actionObjectEMC2.ahk
#Include %A_LineFile%\..\actionObjectHelpdesk.ahk
#Include %A_LineFile%\..\actionObjectPath.ahk

/* Class for ***
	
	***
*/

class ActionObjectRedirector {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	__New(value := "", type := "", subType := "") {
		this.value   := value
		this.type    := type
		this.subType := subType
		
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
	
	value   := ""
	type    := ""
	subType := ""
	
	determineType() {
		; Already know the type
		if(this.type != "")
			return
		
		if(this.tryProcessAsRecord()) ; EMC2 objects and helpdesk are in "INI ID *" format
			return
		
		if(this.tryProcessAsPath()) ; File paths and URLs
			return
	}
	
	tryProcessAsPath() {
		pathType := ActionObjectPath.determinePathType(this.value)
		if(pathType = "")
			return false
		
		this.type    := ActionObjectBase.TYPE_Path
		this.subType := pathType
		return true
	}
	
	tryProcessAsRecord() {
		; Try splitting apart string into INI/ID/title
		recordAry := extractEMC2ObjectInfoRaw(this.value) ; GDB TODO can we combine this with the logic from the actual class somehow, like we did with determinePathType()?
		potentialINI := recordAry["INI"]
		
		; Silent selection from actionObject TLS to see if we match a "record" ("INI ID *" format) type.
		s := new Selector("actionObject2.tls", MainConfig.machineTLFilter)
		data := s.selectChoice(potentialINI)
		if(!data)
			return false
		
		type    := data["TYPE"]
		subType := data["SUBTYPE"]
		
		; Only EMC2 objects and helpdesk can be split and handled this way.
		if((type != ActionObjectBase.TYPE_EMC2) && (type != ActionObjectBase.TYPE_Helpdesk))
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
		
		s := new Selector("actionObject2.tls", MainConfig.machineTLFilter)
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
		
		if(this.type = ActionObjectBase.TYPE_Code)
			return new ActionObjectCode(this.value, this.subType)
		
		if(this.type = ActionObjectBase.TYPE_EMC2)
			return new ActionObjectEMC2(this.value, this.subType)
		
		if(this.type = ActionObjectBase.TYPE_Helpdesk)
			return new ActionObjectHelpdesk(this.value)
		
		if(this.type = ActionObjectBase.TYPE_Path)
			return new ActionObjectPath(this.value, this.subType)
		
		Toast.showError("Unrecognized type", "ActionObjectRedirector doesn't know what to do with this type: " this.type)
		return ""
	}
}
