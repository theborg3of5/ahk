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
	
	getLink() {
		return replaceTag(MainConfig.private["HELPDESK_BASE"], "ID", this.id)
	}
}
