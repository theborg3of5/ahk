/* Base class for type-specific ActionObject child classes.
	
	This is intended to serve as a skeleton for those specific child classes, and should not be instantiated directly.
	
	Each child class should:
		Have its own constructor (__New)
		Override the .getLink*() functions below for the types of links that the child supports (web/edit)
		Override others as needed (for example, .openEdit() could also use an existence check for paths)
*/

class ActionObjectBase {
	; ==============================
	; == Public ====================
	; ==============================
	
	;---------
	; PARAMETERS:
	;  value (I,REQ) - Value for the new class.
	; NOTES:          Should be overridden by child class.
	;---------
	__New(value) {
		Toast.showError("ActionObject instance created", "ActionObject is a base class only, use a type-specific child class instead.")
		return ""
	}
	
	;---------
	; DESCRIPTION:    Open the web or edit version of the object.
	;---------
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
	
	;---------
	; DESCRIPTION:    Put a link to the web or edit version of the object on the clipboard.
	;---------
	copyLinkWeb() {
		link := this.getLinkWeb()
		setClipboardAndToastValue(link, "link")
	}
	copyLinkEdit() {
		link := this.getLinkEdit()
		setClipboardAndToastValue(link, "link")
	}
	
	;---------
	; DESCRIPTION:    Get the link for the web or edit version of the object, and hyperlink the
	;                 selected text with it.
	; PARAMETERS:
	;  problemMessage (I,OPT) - Problem message to include in the clipboard failure toast if we
	;                           weren't able to link the selected text.
	;---------
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
	
	;---------
	; DESCRIPTION:    Get the web link for the object.
	; RETURNS:        Link to the web version of the object.
	; NOTES:          Should be overridden by child class.
	;---------
	getLinkWeb() {
		Toast.showError("ActionObjectBase.getLinkWeb() called directly", ".getLinkWeb() is not implemented by this child ActionObject* class")
		return ""
	}
	;---------
	; DESCRIPTION:    Get the edit link for the object.
	; RETURNS:        Link to the edit version of the object.
	; NOTES:          Should be overridden by child class.
	;---------
	getLinkEdit() {
		Toast.showError("ActionObjectBase.getLinkEdit() called directly", ".getLinkEdit() is not implemented by this child ActionObject* class")
		return ""
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	value   := "" ; Value (the unique bit of info to act upon, like a path or identifier)
	subType := "" ; Determined sub-type, an additional categorization within a particular ActionObject* class.
	
}
