#Include ..\base\actionObjectBase.ahk

/* Class for performing actions on a helpdesk request. --=
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
;		ao := new ActionObjectHelpdesk(123456) ; HDR ID
;		MsgBox, ao.getLinkWeb()  ; Link to helpdesk request (equivalent to .getLinkEdit())
;		ao.openWeb()             ; Open web portal to request (equivalent to .openEdit())
	
*/ ; =--

class ActionObjectHelpdesk extends ActionObjectBase {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Helpdesk request ID.
	;---------
	id := ""
	
	;---------
	; DESCRIPTION:    Create a new reference to a helpdesk request.
	; PARAMETERS:
	;  id (I,REQ) - ID of the request.
	;---------
	__New(id) {
		this.id := id
	}
	
	;---------
	; DESCRIPTION:    Get a link to the helpdesk request.
	; RETURNS:        Link to the helpdesk request.
	;---------
	getLink() {
		return Config.private["HELPDESK_BASE"].replaceTag("ID", this.id)
	}
	; #END#
}
