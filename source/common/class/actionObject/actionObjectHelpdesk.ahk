#Include %A_LineFile%\..\actionObjectBase.ahk

/* Class for ***
	
	***
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
