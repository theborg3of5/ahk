#Include %A_LineFile%\..\actionObjectBase.ahk

/* Class for ***
	
	***
*/

class ActionObjectCode extends ActionObjectBase {
	; ==============================
	; == Public ====================
	; ==============================
	
	static CODETYPE_Routine := "ROUTINE" ; Server code location, including tag if applicable
	static CODETYPE_DLG     := "DLG"     ; DLG, for opening in EpicStudio
	
	codeType := "" ; Type of code object (from CODETYPE_* constants)
	code     := "" ; Reference to code object
	
	
	__New(code, codeType := "") {
		this.code     := code
		this.codeType := codeType
		
		if(this.codeType = "")
			this.codeType := this.determineCodeType()
		
		this.selectMissingInfo()
	}
	
	getLinkWeb() {
		if(this.codeType = ActionObjectCode.CODETYPE_Routine) {
			splitServerLocation(this.code, routine, tag)
			return buildServerCodeLink(routine, tag)
		}
		
		if(this.codeType = ActionObjectCode.CODETYPE_DLG)
			return "" ; Not supported
		
		return ""
	}
	getLinkEdit() {
		if(this.codeType = ActionObjectCode.CODETYPE_Routine) {
			splitServerLocation(this.code, routine, tag)
			return buildEpicStudioRoutineLink(routine, tag)
		}
		
		if(this.codeType = ActionObjectCode.CODETYPE_DLG)
			return buildEpicStudioDLGLink(this.code)
		
		return ""
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	determineCodeType() {
		; Full server tag^routine
		if(stringContains(this.code, "^"))
			return ActionObjectCode.CODETYPE_Routine
		
		; DLG IDs are (usually) entirely numeric, where routines are not.
		if(isNum(this.code))
			return ActionObjectCode.CODETYPE_DLG
		
		return ""
	}
	
	selectMissingInfo() {
		; Nothing is missing
		if(this.code != "" && this.codeType != "")
			return
		
		s := new Selector("actionObject.tls", MainConfig.machineTLFilter)
		data := s.selectGui("", "", {"SUBTYPE": this.codeType, "VALUE": this.code})
		if(!data)
			return
		
		this.codeType := data["SUBTYPE"]
		this.code     := data["VALUE"]
	}
}
