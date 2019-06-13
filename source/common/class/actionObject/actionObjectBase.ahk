/* Base class for type-specific ActionObject child classes.
	
	This is intended to serve as a skeleton for those specific child classes. Each child class should:
		Override the .getLink*() functions below for the types of links that the child supports (web/edit)
		Override others as needed (for example, .openEdit() could also use an existence check for paths)
		
*/

class ActionObjectBase {
	; ==============================
	; == Public ====================
	; ==============================
	
	
	__New(value := "", subType := "") {
		Toast.showError("ActionObject instance created", "ActionObject is a base class only, use a type-specific child class instead.")
		return ""
	}
	
	
	openWeb() {
		link := this.getLinkWeb()
		if(link)
			Run(link)
	}
	openEdit() {
		link := this.getLinkEdit()
		if(link)
			Run(link)
	}
	
	copyLinkWeb() {
		link := this.getLinkWeb()
		setClipboardAndToastValue(link, "link")
	}
	copyLinkEdit() {
		link := this.getLinkEdit()
		setClipboardAndToastValue(link, "link")
	}
	
	linkSelectedTextWeb(problemMessage := "Failed to link selected text") {
		link := this.getLinkWeb()
		if(!link)
			return
		
		if(!Hyperlinker.linkSelectedText(link, errorMessage))
			setClipboardAndToastError(link, "link", problemMessage, errorMessage)
	}
	linkSelectedTextEdit(problemMessage := "Failed to link selected text") {
		link := this.getLinkEdit()
		if(!link)
			return
		
		if(!Hyperlinker.linkSelectedText(link, errorMessage))
			setClipboardAndToastError(link, "link", problemMessage, errorMessage)
	}
	
	getLinkWeb() {
		Toast.showError("ActionObjectBase.getLinkWeb() called directly", ".getLinkWeb() is not implemented by this child ActionObject* class")
		return ""
	}
	getLinkEdit() {
		Toast.showError("ActionObjectBase.getLinkEdit() called directly", ".getLinkEdit() is not implemented by this child ActionObject* class")
		return ""
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	value   := "" ; GDB TODO document
	subType := ""

}
