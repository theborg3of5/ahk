#Include %A_LineFile%\..\actionObjectBase.ahk

/* Class for ***
	
	***
*/

class ActionObjectCode extends ActionObjectBase {
	; ==============================
	; == Public ====================
	; ==============================
	
	static CODETYPE_Routine := "ROUTINE"
	static CODETYPE_DLG     := "DLG"
	
	; Named property equivalents for the base generic variables, so base functions still work.
	codeType[] {
		get {
			return this.subType
		}
		set {
			this.subType := value
		}
	}
	
	__New(value, codeType := "") {
		this.value    := value
		this.codeType := codeType
		
		if(this.codeType = "")
			this.codeType := this.determineCodeType()
		
		this.selectMissingInfo()
	}
	
	getLinkWeb() {
		if(this.codeType = ActionObjectCode.CODETYPE_Routine) {
			splitServerLocation(this.value, routine, tag)
			return buildServerCodeLink(routine, tag)
		}
		
		if(this.codeType = ActionObjectCode.CODETYPE_DLG)
			return "" ; Not supported
		
		return ""
	}
	getLinkEdit() {
		if(this.codeType = ActionObjectCode.CODETYPE_Routine) {
			splitServerLocation(this.value, routine, tag)
			return buildEpicStudioRoutineLink(routine, tag)
		}
		
		if(this.codeType = ActionObjectCode.CODETYPE_DLG)
			return buildEpicStudioDLGLink(this.value)
		
		return ""
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	determineCodeType() {
		; Full server tag^routine
		if(stringContains(this.value, "^"))
			return ActionObjectCode.CODETYPE_Routine
		
		; DLG IDs are (usually) entirely numeric, where routines are not.
		if(isNum(this.value))
			return ActionObjectCode.CODETYPE_DLG
		
		return ""
	}
	
	selectMissingInfo() {
		; Nothing is missing
		if(this.value != "" && this.codeType != "")
			return
		
		s := new Selector("actionObject.tls", MainConfig.machineTLFilter)
		data := s.selectGui("", "", {"SUBTYPE": this.codeType, "VALUE": this.value})
		if(!data)
			return
		
		this.codeType := data["SUBTYPE"]
		this.value    := data["VALUE"]
	}
}
