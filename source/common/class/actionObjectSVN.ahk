#Include ..\base\actionObjectBase.ahk

/* Class for performing actions based on an SVN revision. =--
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
;		ao := new ActionObjectSVN(1234567) ; Will prompt the user for the repository URL (or replaceable tag)
;		ao.open() ; Open in TortoiseSVN
	
*/ ; --=

class ActionObjectSVN extends ActionObjectBase {
	; #PUBLIC#
	
	ActionObjectType := ActionObject.Type_SVN
	
	; @GROUP@ 
	revision := "" ; SVN revision to work with.
	repoURL  := "" ; The URL for the repository that the revision is from.
	; @GROUP-END@
	
	
	;---------
	; DESCRIPTION:    Create a new reference to a CodeSearch object.
	; PARAMETERS:
	;  revision (I,REQ) - SVN revision to work with.
	;  repoURL  (I,OPT) - URL for the SVN repository.
	;---------
	__New(revision, repoURL := "") {
		if(!this.selectMissingInfo(revision, repoURL))
			return ""
		
		this.revision := revision
		this.repoURL  := repoURL
	}
	
	;---------
	; DESCRIPTION:    Open the given revision in the TortoiseSVN log window.
	;---------
	open() {
		runString := "TortoiseProc.exe /command:log /path:""<REPO_URL>"" /closeonend:0 /startrev:<REVISION> /endrev:<REVISION>"
		runString := runString.replaceTag("REVISION", this.revision)
		runString := runString.replaceTag("REPO_URL", this.repoURL)
		
		Run(runString)
	}
	; #END#
}
