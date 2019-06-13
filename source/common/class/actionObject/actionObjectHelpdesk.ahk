#Include %A_LineFile%\..\actionObjectBase.ahk

/* Class for ***
	
	***
*/

class ActionObjectHelpdesk extends ActionObjectBase {
	; ==============================
	; == Public ====================
	; ==============================
	
	; Named property equivalents for the base generic variables, so base functions still work.
	id[] {
		get {
			return this.value
		}
		set {
			this.value := value
		}
	}
	
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
