#Include ..\base\actionObjectBase.ahk

/* Class for performing actions based on an SVN revision. =--
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
;		ao := new ActionObjectSVN(1234567)
;		ao.open() ; Open in TortoiseSVN
	
*/ ; --=

class ActionObjectSVN extends ActionObjectBase {
	; #PUBLIC#
	
	ActionObjectType := ActionObject.Type_SVN
	
	; @GROUP@ 
	revision := "" ; SVN revision to work with.
	; @GROUP-END@
	
	
	;---------
	; DESCRIPTION:    Create a new reference to a CodeSearch object.
	; PARAMETERS:
	;  revision (I,REQ) - SVN revision to work with.
	;---------
	__New(revision) {
		this.revision := revision
	}
	
	;---------
	; DESCRIPTION:    Determine whether the given string must be an SVN revision.
	; PARAMETERS:
	;  value       (I,REQ) - The value to evaluate
	;  revisionNum (O,OPT) - If the value is a revision, the revision number
	; RETURNS:        true/false - whether the given value must be an SVN revision.
	;---------
	isThisType(value, ByRef revisionNum := "") {
		if(!Config.contextIsWork)
			return false
		
		if(!value.startsWithAnyOf(["svn ", "commit ", "revision "], matchedKeyword))
			return false
		
		revisionNum := value.removeFromStart(matchedKeyword)
		return true
	}
	
	;---------
	; DESCRIPTION:    Get a link to the revision.
	; RETURNS:        Link to the SVN revision in the TortoiseSVN log window.
	;---------
	getLink() {
		link := "tsvncmd:command:log?path:<EPIC_SVN_URL>?startrev:<REVISION>?endrev:<REVISION>"
		link := Config.replacePrivateTags(link) ; Handles EPIC_SVN_URL
		link := link.replaceTag("REVISION", this.revision)
		
		return link
	}
	; #END#
}
