/* Base class for type-specific ActionObject child classes. =--
	
	This is intended to serve as a skeleton for those specific child classes, and should not be instantiated directly.
	
	Each child class should:
		Have its own constructor (__New)
		Override the .getLink*() functions below for the types of links that the child supports (general/web/edit)
		Override others as needed (for example, .open() could also use an existence check for local paths)
		Override ActionObjectType with the value from ActionObject.Type_* that it implements
		
	Child classes may also use these functions:
		selectMissingInfo - Check whether there's any required info (value and subType) missing, and if so, prompt the user with a filtered Selector popup to get that info.
	
*/ ; --=

class ActionObjectBase {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    What type of ActionObject the child class implements.
	; NOTES:          Should be overridden by child class.
	;---------
	ActionObjectType := ""
	
	
	;---------
	; NOTES:          Should not be called directly - all child classes should override this.
	;---------
	__New(value) {
		Toast.ShowError("ActionObjectBase instance created", "ActionObjectBase is a base class only, use a type-specific child class instead.")
		return ""
	}
	
	;---------
	; DESCRIPTION:    Get the link for the object.
	; RETURNS:        Link to the object.
	; NOTES:          Should typically be overridden by child class, unless that child class doesn't want a link (or only
	;                 wants web/edit-specific links).
	;---------
	getLink() {
		return ""
	}
	;---------
	; DESCRIPTION:    Get a web link for the object. This just calls .getLink() unless it's
	;                 overridden by the child class.
	;---------
	getLinkWeb() {
		return this.getLink()
	}
	;---------
	; DESCRIPTION:    Get an edit link for the object. This just calls .getLink() unless it's
	;                 overridden by the child class.
	;---------
	getLinkEdit() {
		return this.getLink()
	}
	
	;---------
	; DESCRIPTION:    Open the object.
	; PARAMETERS:
	;  link (I,OPT) - If a link is given, we'll run it directly. Otherwise the link will come from this.getLink().
	; NOTES:          Children that override this probably don't want to include the link parameter - it's only there so
	;                 the web- and edit-specific functions will call thru any overriden logic.
	;---------
	open(link := "") {
		if(!link)
			link := this.getLink()
		
		if(link)
			RunLib.runAsUser(link)
	}
	;---------
	; DESCRIPTION:    Open the object, specifically in web mode.
	;---------
	openWeb() {
		this.open(this.getLinkWeb())
	}
	;---------
	; DESCRIPTION:    Open the object, specifically in edit mode.
	;---------
	openEdit() {
		this.open(this.getLinkEdit())
	}
	
	;---------
	; DESCRIPTION:    Put a link to the object on the clipboard.
	; PARAMETERS:
	;  link (I,OPT) - If a link is given, we'll run it directly. Otherwise the link will come from this.getLink().
	; NOTES:          Children that override this probably don't want to include the link parameter - it's only there so
	;                 the web- and edit-specific functions will call thru any overriden logic.
	;---------
	copyLink(link := "") {
		if(!link)
			link := this.getLink()
		
		ClipboardLib.setAndToast(link, "link")
	}
	;---------
	; DESCRIPTION:    Put a link to the object on the clipboard, specifically in web mode.
	;---------
	copyLinkWeb() {
		this.copyLink(this.getLinkWeb())
	}
	;---------
	; DESCRIPTION:    Put a link to the object on the clipboard, specifically in edit mode.
	;---------
	copyLinkEdit() {
		this.copyLink(this.getLinkEdit())
	}
	
	;---------
	; DESCRIPTION:    Get the link for the object, and hyperlink the selected text with it.
	; PARAMETERS:
	;  problemMessage (I,OPT) - Problem message to include in the clipboard failure toast if we
	;                           weren't able to link the selected text.
	;  link           (I,OPT) - If a link is given, we'll run it directly. Otherwise the link will come from this.getLink().
	; NOTES:          Children that override this probably don't want to include the link parameter - it's only there so
	;                 the web- and edit-specific functions will call thru any overriden logic.
	;---------
	linkSelectedText(problemMessage := "Failed to link selected text", link := "") {
		if(!link)
			link := this.getLink()
		if(!link)
			return
		
		if(!Hyperlinker.linkSelectedText(link, errorMessage))
			ClipboardLib.setAndToastError(link, "link", problemMessage, errorMessage)
	}
	;---------
	; DESCRIPTION:    Get the link for the object, and hyperlink the selected text with it,
	;                 specifically in web mode.
	;---------
	linkSelectedTextWeb(problemMessage := "Failed to link selected text") {
		this.linkSelectedText(problemMessage, this.getLinkWeb())
	}
	;---------
	; DESCRIPTION:    Get the link for the object, and hyperlink the selected text with it,
	;                 specifically in edit mode.
	;---------
	linkSelectedTextEdit(problemMessage := "Failed to link selected text") {
		this.linkSelectedText(problemMessage, this.getLinkEdit())
	}
	
	;---------
	; DESCRIPTION:    Check whether the given value or subType is missing, and if it is, prompt the
	;                 user with a Selector instance (filtered to the child's type) to get the info.
	; PARAMETERS:
	;  value      (IO,REQ) - The core value, will be updated if the user changes it in the Selector popup.
	;  subType    (IO,REQ) - The subType, will be populated with a new value if the user selects one.
	;  popupTitle  (I,OPT) - If you want to show a different title than the one in the ActionObject
	;                        TLS, pass it here.
	; RETURNS:        true if we have both pieces of info, false if something is missing.
	; NOTES:          Should only be called by child instances.
	;---------
	selectMissingInfo(ByRef value, ByRef subType, popupTitle := "") {
		; ActionObjectType must be set by child to use this function.
		if(this.ActionObjectType = "") {
			Toast.ShowError("No ActionObjectType found", "ActionObject* child did not override ActionObjectType property")
			return false
		}
		
		; Nothing is missing, so nothing to do.
		if(value != "" && subType != "")
			return true
		
		; Use a type-filtered Selector to get any missing info.
		s := this.getTypeSelector(this.ActionObjectType)
		s.setDefaultOverrides({"VALUE":value})
		if(popupTitle != "")
			s.setTitle(popupTitle)
		data := s.selectGui()
		
		; Fail if we didn't get everything we needed.
		if(!data)
			return false
		if(data["SUBTYPE"] = "" || data["VALUE"] = "")
			return false
		
		; Save off updated values and return success
		subType := data["SUBTYPE"]
		value   := data["VALUE"]
		return true
	}
	
	
	; #PRIVATE#
	
	static typeSelectors := {} ; {ActionObject.Type_*: Selector}
	
	
	;---------
	; DESCRIPTION:    Get a Selector instance for the ActionObject TLS and filter its
	;                 choices to only those matching the given type.
	; PARAMETERS:
	;  type (I,REQ) - The type to filter to, from ActionObject.Type_*
	; RETURNS:        An ActionObject Selector instance, filtered to the given type.
	; SIDE EFFECTS:   Caches Selector instances in .typeSelectors.
	;---------
	getTypeSelector(type) {
		if(type = "")
			return ""
		
		; If an instance already exists, just use that.
		if(this.typeSelectors[type])
			return this.typeSelectors[type]
			
		; Otherwise, create a new one.
		s := new Selector("actionObject.tls")
		s.dataTableList.filterOutIfColumnNoMatch("TYPE", type)
		
		this.typeSelectors[type] := s ; Cache the value off for later use.
		return s
	}
	; #END#
}
