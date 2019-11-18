#Include ..\base\actionObjectBase.ahk

/* Class for performing actions on a path. --=
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
		ao := new ActionObjectPath("F:\personal\eyobuddy") ; Local path or URL, user will be prompted for which it is
		MsgBox, ao.getLinkWeb()  ; Returns path (equivalent to .getLinkEdit())
		ao.openWeb()             ; Open path (equivalent to .openEdit())
		
		ao := new ActionObjectPath("google.com", ActionObjectPath.PathType_URL) ; Specify path type if known to avoid prompting
		ao.openEdit() ; Run URL
	
*/ ; =--

class ActionObjectPath extends ActionObjectBase {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Local file path
	;---------
	static PathType_FilePath := "FILEPATH"
	;---------
	; DESCRIPTION:    URL
	;---------
	static PathType_URL      := "URL"
	
	;---------
	; DESCRIPTION:    The path itself.
	;---------
	path     := ""
	;---------
	; DESCRIPTION:    The type of path, from PathType_*.
	;---------
	pathType := ""
	
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
		
		this.postProcess()
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
	; DESCRIPTION:    Get a link to the path (that is, the path itself).
	; RETURNS:        The path
	;---------
	getLink() {
		if(this.pathType = ActionObjectPath.PathType_FilePath) {
			if(!FileExist(this.path)) { ; Don't try to open a non-existent local path
				new ErrorToast("Local file or folder does not exist", this.path).showMedium()
				return ""
			}
		}
		
		return this.path
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Do some additional processing on the different bits of info about the object.
	; SIDE EFFECTS:   Can update this.path.
	;---------
	postProcess() {
		; For URLs, make sure that they have a protocol at the start so Windows knows how to run it
		; as a URL (not a local path).
		if(this.pathType = ActionObjectPath.PathType_URL) {
			if(!this.path.contains("//")) ; No protocol
				this.path := "https://" this.path ; Add a protocol on so Windows knows to run it as a URL.
		}
	}
	
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
	; #END#
}
