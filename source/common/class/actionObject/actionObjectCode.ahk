#Include %A_LineFile%\..\actionObjectBase.ahk

/* Class for performing actions based on a specific server code location or DLG.
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
		ao := new ActionObjectCode("tagName^routineName")
		MsgBox, ao.getLinkWeb()  ; Link in CodeSearch
		MsgBox, ao.getLinkEdit() ; Link in EpicStudio
		ao.openWeb()             ; Open in CodeSearch
		ao.openEdit()            ; Open in EpicStudio
		
		ao := new ActionObjectCode(123456) ; DLG ID
		ao.openEdit() ; Open DLG in EpicStudio
*/

class ActionObjectCode extends ActionObjectBase {
	; ==============================
	; == Public ====================
	; ==============================
	
	static CODETYPE_Routine := "ROUTINE" ; Server code location, including tag if applicable
	static CODETYPE_DLG     := "DLG"     ; DLG, for opening in EpicStudio
	
	codeType := "" ; Type of code object (from CODETYPE_* constants)
	code     := "" ; Reference to code object
	
	;---------
	; DESCRIPTION:    Create a new reference to a server code object.
	; PARAMETERS:
	;  code     (I,REQ) - Value representing the code
	;  codeType (I,OPT) - Type of code, from CODETYPE_* constants. If not given, we'll figure it out
	;                     based on the code format or by prompting the user.
	;---------
	__New(code, codeType := "") {
		this.code     := code
		this.codeType := codeType
		
		if(this.codeType = "")
			this.codeType := this.determineCodeType()
		
		this.selectMissingInfo()
	}
	
	;---------
	; DESCRIPTION:    Get a link to the web (CodeSearch) or edit (EpicStudio) version of the code
	;                 location or DLG.
	; RETURNS:        Link to CodeSearch for the code location.
	; NOTES:          DLGs are only supported by .getLinkEdit()
	;---------
	getLinkWeb() {
		if(this.codeType = ActionObjectCode.CODETYPE_Routine) {
			splitServerLocation(this.code, routine, tag)
			url := MainConfig.private["CS_SERVER_CODE_BASE"]
			url := replaceTag(url, "ROUTINE", routine)
			url := replaceTag(url, "TAG",     tag)
			return url
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
	
	;---------
	; DESCRIPTION:    Try to figure out what kind of code object we've been given based on its format.
	; RETURNS:        Code type from CODETYPE_* constants
	;---------
	determineCodeType() {
		; Full server tag^routine
		if(stringContains(this.code, "^"))
			return ActionObjectCode.CODETYPE_Routine
		
		; DLG IDs are (usually) entirely numeric, where routines are not.
		if(isNum(this.code))
			return ActionObjectCode.CODETYPE_DLG
		
		return ""
	}
	
	;---------
	; DESCRIPTION:    Prompt the user for the code type or code if either are missing.
	; SIDE EFFECTS:   Sets .codeType/.code based on user inputs.
	;---------
	selectMissingInfo() {
		; Nothing is missing
		if(this.code != "" && this.codeType != "")
			return
		
		s := new Selector("actionObject.tls", MainConfig.machineSelectorFilter)
		data := s.selectGui("", "", {"SUBTYPE": this.codeType, "VALUE": this.code})
		if(!data)
			return
		
		this.codeType := data["SUBTYPE"]
		this.code     := data["VALUE"]
	}
}
