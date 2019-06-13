#Include %A_LineFile%\..\actionObjectBase.ahk

/* Class for performing actions on a helpdesk request.
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
		ao := new ActionObjectHelpdesk(123456) ; HDR ID
		MsgBox, ao.getLinkWeb()  ; Link to helpdesk request (equivalent to .getLinkEdit())
		ao.openWeb()             ; Open web portal to request (equivalent to .openEdit())
*/

class ActionObjectHelpdesk extends ActionObjectBase {
	; ==============================
	; == Public ====================
	; ==============================
	
	id := "" ; ID of the helpdesk request
	
	
	__New(id) {
		this.id := id
	}
	
	getLinkWeb() {
		return replaceTags(MainConfig.private["EMC2_LINK_EDIT_BASE"], {"INI":this.ini, "ID":this.id})
	}
	getLinkEdit() {
		return this.getLinkWeb()
	}
}
