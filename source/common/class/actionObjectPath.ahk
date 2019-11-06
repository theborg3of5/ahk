#Include ..\base\actionObjectBase.ahk

/* Class for performing actions on a path. =--
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
		ao := new ActionObjectPath("F:\personal\eyobuddy") ; Local path or URL, user will be prompted for which it is
		MsgBox, ao.getLinkWeb()  ; Returns path (equivalent to .getLinkEdit())
		ao.openWeb()             ; Open path (equivalent to .openEdit())
		
		ao := new ActionObjectPath("google.com", ActionObjectPath.PathType_URL) ; Specify path type if known to avoid prompting
		ao.openEdit() ; Run URL
	
*/ ; --=

class ActionObjectPath extends ActionObjectBase {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	static PathType_FilePath := "FILEPATH" ; Local file path
	static PathType_URL      := "URL"
	
	path     := "" ; The path itself.
	pathType := "" ; Type of path, from PathType_* constants.
	
	;---------
	; DESCRIPTION:    Create a new reference to a path.
	; PARAMETERS:
	;  path     (I,REQ) - The actual path
	;  pathType (I,OPT) - Type of path, from PathType_* constants. If not given, we'll figure it out
	;                     based on the path format or by prompting the user.
	;---------
	__New(path, pathType := "") {
		this.path     := path
		this.pathType := pathType
		
		; Make sure there's no quotes or other oddities surrounding the path
		this.path := this.path.clean([""""]) ; Single double-quote character
		
		if(this.pathType = "")
			this.pathType := this.determinePathType(this.path)
		
		if(!this.selectMissingInfo())
			return
	}
	
	;---------
	; DESCRIPTION:    Determine the type of the given path.
	; PARAMETERS:
	;  path (I,REQ) - The path itself.
	; RETURNS:        The type of path, from PathType_* constants.
	;---------
	determinePathType(path) {
		; Full URLs
		if(path.startsWithAnyOf(["http://", "https://"]))
			return ActionObjectPath.PathType_URL
		
		; Filepaths
		if(path.startsWithAnyOf(["file:///", "\\"])) ; URL-formatted file path, Windows network path
			return ActionObjectPath.PathType_FilePath
		if(path.sub(2, 2) = ":\")  ; Windows filepath (starts with drive letter + :\)
			return ActionObjectPath.PathType_FilePath
		
		; Partial URLs (www.google.com, similar)
		if(path.startsWithAnyOf(["www.", "vpn.", "m."]))
			return ActionObjectPath.PathType_URL
		
		; Unknown
		return ""
	}
	
	;---------
	; DESCRIPTION:    Open the path, doing a safety check for existence if it's a local file path.
	; NOTES:          There's no web vs. edit version for this, so here's a generic tag that the
	;                 others redirect to.
	;---------
	open() {
		if(!this.path)
			return
		if(this.pathType = ActionObjectPath.PathType_FilePath && !FileExist(this.path)) { ; Don't try to open a non-existent local path
			Debug.popup("Local file or folder does not exist", this.path)
			return
		}
		
		Run(this.path)
	}
	openWeb() {
		this.open()
	}
	openEdit() {
		this.open()
	}
	
	;---------
	; DESCRIPTION:    Get a link to the path (that is, the path itself).
	; RETURNS:        The path
	; NOTES:          Web and edit functions do the same thing here - there is no difference between
	;                 the two.
	;---------
	getLink() {
		return this.path
	}
	getLinkWeb() {
		return this.getLink()
	}
	getLinkEdit() {
		return this.getLink()
	}
	
	
; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Prompt the user for the path type or path if either are missing.
	; SIDE EFFECTS:   Sets .pathType/.path based on user inputs.
	;---------
	selectMissingInfo() {
		; Nothing is missing
		if(this.path != "" && this.pathType != "")
			return true
		
		s := new Selector("actionObject.tls").SetDefaultOverrides({"VALUE":this.path})
		s.dataTL.filterByColumn("TYPE", ActionObject.Type_Path)
		data := s.selectGui()
		if(!data)
			return false
		if(data["SUBTYPE"] = "" || data["VALUE"] = "") ; Didn't get everything we needed.
			return false
		
		this.pathType := data["SUBTYPE"]
		this.path     := data["VALUE"]
		return true
	}
}
