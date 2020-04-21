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
	
	ActionObjectType := ActionObject.Type_Helpdesk
	
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
		; Drop the leading INI if it's given.
		id := id.clean().removeFromStart("HDR ")
		
		this.id := id
	}
	
	;---------
	; DESCRIPTION:    Determine whether the given string must be this type of ActionObject.
	; PARAMETERS:
	;  value (I,REQ) - The value to evaluate
	;  id    (O,OPT) - If the value is a helpdesk ticket, the ID
	; RETURNS:        true/false - whether the given value must be a helpdesk ticket.
	;---------
	isThisType(value, ByRef id := "") {
		if(!value.startsWith("HDR "))
			return false
		
		id := value.removeFromStart("HDR ")
		return true
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
