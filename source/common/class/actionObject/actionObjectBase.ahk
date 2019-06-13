/* Base class for type-specific ActionObject child classes.
	
	This is intended to serve as a skeleton for those specific child classes. Each child class should:
		Override the .getLink() function below, and others as needed (for example, .open() could also use an existence check for paths)
		*Make use of the ActionObjectBase.SUBACTION_* constants as needed
*/

class ActionObjectBase {
	; ==============================
	; == Public ====================
	; ==============================
	
	; GDB TODO replace with more specific open/copy/linkSelectedText/getLink functions instead?
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
	
	linkSelectedText(linkType := "", clipLabel := "link", problemMessage := "Failed to link selected text") {
		link := this.getLink(linkType)
		if(!link)
			return
		
		if(!Hyperlinker.linkSelectedText(link, errorMessage))
			setClipboardAndToastError(link, clipLabel, problemMessage, errorMessage)
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
