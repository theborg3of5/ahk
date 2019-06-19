/* Base class for type-specific ActionObject child classes.
	
	This is intended to serve as a skeleton for those specific child classes, and should not be instantiated directly.
	
	Each child class should:
		Have its own constructor (__New)
		Override the .getLink*() functions below for the types of links that the child supports (general/web/edit)
		Override others as needed (for example, .open() could also use an existence check for local paths)
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
	; DESCRIPTION:    Open the object.
	;---------
	open() {
		this.doOpen(this.getLink())
	}
	openWeb() {
		this.doOpen(this.getLinkWeb())
	}
	openEdit() {
		this.doOpen(this.getLinkEdit())
	}
	
	;---------
	; DESCRIPTION:    Put a link to the the object on the clipboard.
	;---------
	copyLink() {
		this.doCopyLink(this.getLink())
	}
	copyLinkWeb() {
		this.doCopyLink(this.getLinkWeb())
	}
	copyLinkEdit() {
		this.doCopyLink(this.getLinkEdit())
	}
	
	;---------
	; DESCRIPTION:    Get the link for the object, and hyperlink the selected text with it.
	; PARAMETERS:
	;  problemMessage (I,OPT) - Problem message to include in the clipboard failure toast if we
	;                           weren't able to link the selected text.
	;---------
	linkSelectedText(problemMessage := "Failed to link selected text") {
		this.doLinkSelectedText(problemMessage, this.getLink())
	}
	linkSelectedTextWeb(problemMessage := "Failed to link selected text") {
		this.doLinkSelectedText(problemMessage, this.getLinkWeb())
	}
	linkSelectedTextEdit(problemMessage := "Failed to link selected text") {
		this.doLinkSelectedText(problemMessage, this.getLinkEdit())
	}
	
	;---------
	; DESCRIPTION:    Get the link for the object.
	; RETURNS:        Link to the web version of the object.
	; NOTES:          Should be overridden by child class.
	;---------
	getLink() {
		Toast.showError("ActionObjectBase.getLink() called directly", ".getLink() is not implemented by this child ActionObject* class")
		return ""
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
	
	;---------
	; DESCRIPTION:    Open provided link to the object.
	;  link (I,REQ) - Link to open.
	;---------
	doOpen(link) {
		if(link)
			Run(link)
	}
	
	;---------
	; DESCRIPTION:    Put the provided link to the the object on the clipboard.
	;  link (I,REQ) - Link to copy.
	;---------
	doCopyLink(link) {
		setClipboardAndToastValue(link, "link")
	}
	
	;---------
	; DESCRIPTION:    Hyperlink the selected text with the provided link.
	; PARAMETERS:
	;  problemMessage (I,OPT) - Problem message to include in the clipboard failure toast if we
	;                           weren't able to link the selected text.
	;  link           (I,REQ) - Link to apply to selected text.
	;---------
	doLinkSelectedText(problemMessage, link) {
		if(!link)
			return
		
		if(!Hyperlinker.linkSelectedText(link, errorMessage))
			setClipboardAndToastError(link, "link", problemMessage, errorMessage)
	}
	
	;---------
	; DESCRIPTION:    Get the link for the object.
	; PARAMETERS:
	;  caller (I,OPT) - Name of the calling function, to include in error toast.
	; RETURNS:        Link to the object.
	;---------
	doGetLink(callerName) {
		displayName := "." callerName "()"
		Toast.showError("ActionObjectBase" displayName " called directly", displayName " is not implemented by this child ActionObject* class")
		return ""
	}
}
