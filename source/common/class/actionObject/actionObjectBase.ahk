/* Class for ***
	
	***
*/

class ActionObjectBase {
	; ==============================
	; == Public ====================
	; ==============================
	
	; Type constants
	static TYPE_EMC2     := "EMC2"
	static TYPE_Code     := "CODE" ; EpicStudio for edit, CodeSearch for web
	static TYPE_Helpdesk := "HELPDESK"
	static TYPE_Path     := "PATH"
	
	; GDB TODO document
	static SUBACTION_Edit     := "EDIT"
	static SUBACTION_Web      := "WEB"
	static SUBACTION_WebBasic := "WEB_BASIC"
	
	
	__New(value := "", subType := "") {
		Toast.showError("ActionObject instance created", "ActionObject is a base class only, use a type-specific child class instead.")
		return ""
	}
	
	open(runType := "") {
		link := this.getLink(runType)
		if(link)
			Run(link)	
	}
	
	copyLink(linkType := "") {
		link := this.getLink(linkType)
		setClipboardAndToastValue(link, "link")
	}
	
	linkSelectedText(linkType := "") {
		link := this.getLink(linkType)
		if(!link)
			return
		
		if(!Hyperlinker.linkSelectedText(link, errorMessage))
			setClipboardAndToastError(link, "link", "Failed to link selected text", errorMessage)
	}
	
	getLink(linkType := "") {
		Toast.showError(".getLink() called directly", ".getLink() is not implemented by the parent ActionObjectBase class")
		return ""
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	value   := "" ; GDB TODO document
	subType := ""

}
