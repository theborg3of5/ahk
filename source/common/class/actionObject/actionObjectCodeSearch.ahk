#Include %A_LineFile%\..\actionObjectBase.ahk

/* Class for performing actions based on a code location in CodeSearch.
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
		ao := new ActionObjectCodeSearch("tagName^routineName")
		MsgBox, ao.getLinkWeb()  ; Link in CodeSearch
		ao.openWeb()             ; Open in CodeSearch
*/

class ActionObjectCodeSearch extends ActionObjectBase {

; ==============================
; == Public ====================
; ==============================
	location := "" ; Code location to work with
	
	;---------
	; DESCRIPTION:    Create a new reference to a CodeSearch object.
	; PARAMETERS:
	;  location (I,REQ) - Value representing the code location
	;---------
	__New(location) {
		this.location := location
		this.selectMissingInfo()
	}
	
	;---------
	; DESCRIPTION:    Get a link in CodeSearch to the code location.
	; RETURNS:        Link to CodeSearch for the code location.
	; NOTES:          There's no web vs. edit version for this, so here's a generic tag that the
	;                 others redirect to.
	;---------
	getLink() {
		splitServerLocation(this.location, routine, tag)
		routine := encodeForURL(routine)
		tag     := encodeForURL(tag)
		
		return MainConfig.private["CS_SERVER_CODE_BASE"].replaceTags({"ROUTINE":routine, "TAG":tag})
	}
	getLinkWeb() {
		return this.getLink()
	}
	getLinkEdit() {
		return this.getLink()
	}
	
	
; ==============================
; == Private ===================
; ==============================
	;---------
	; DESCRIPTION:    Prompt the user for the code location if it's missing.
	; SIDE EFFECTS:   Sets .location based on user inputs.
	;---------
	selectMissingInfo() {
		; Nothing is missing
		if(this.location != "")
			return
		
		data := new Selector("actionObject.tls").selectGui("", "", {"VALUE": this.location})
		if(!data)
			return
		
		this.location := data["VALUE"]
	}
}
