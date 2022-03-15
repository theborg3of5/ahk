#Include ..\base\actionObjectBase.ahk

/* Class for performing actions on a path. =--
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
;		ao := new ActionObjectPath("F:\personal\eyobuddy") ; Local path or URL, user will be prompted for which it is
;		MsgBox, ao.getLink() ; Returns path
;		ao.open()            ; Opens path (equivalent to .openEdit() or .openWeb())
;		
;		ao := new ActionObjectPath("google.com", ActionObjectPath.PathType_URL) ; Specify path type if known to avoid prompting
;		ao.openEdit() ; Run URL
	
*/ ; --=

class ActionObjectPath extends ActionObjectBase {
	; #PUBLIC#
	
	ActionObjectType := ActionObject.Type_Path
	
	; @GROUP@ Path types
	static PathType_FilePath := "FILEPATH" ; Local file path
	static PathType_URL      := "URL"      ; URL
	; @GROUP-END@
	
	; @GROUP@
	path     := "" ; The path itself.
	pathType := "" ; The type of path, from PathType_*.
	; @GROUP-END@
	
	;---------
	; DESCRIPTION:    Create a new reference to a path.
	; PARAMETERS:
	;  path     (I,REQ) - The actual path
	;  pathType (I,OPT) - Type of path, from PathType_* constants. If not given, we'll figure it out
	;                     based on the path format or by prompting the user.
	;---------
	__New(path, pathType := "") {
		
		; Make sure there's no quotes or other oddities surrounding the path
		path := path.clean([""""]) ; Single double-quote character
		
		if(pathType = "")
			pathType := this.determinePathType(path)
		
		if(!this.selectMissingInfo(path, pathType))
			return
		
		this.path     := path
		this.pathType := pathType
		this.postProcess()
	}
	
	;---------
	; DESCRIPTION:    Determine whether the given string must be this type of ActionObject.
	; PARAMETERS:
	;  value    (I,REQ) - The value to evaluate
	;  pathType (O,OPT) - If the value is a path, the path type
	; RETURNS:        true/false - whether the given value must be a path.
	;---------
	isThisType(value, ByRef pathType := "") {
		matchedPathType := this.determinePathType(value)
		if(matchedPathType = "")
			return false
		
		pathType := matchedPathType
		return true
	}
	
	;---------
	; DESCRIPTION:    Get a link to the path (that is, the path itself).
	; RETURNS:        The path
	;---------
	getLink() {
		if(this.pathType = ActionObjectPath.PathType_FilePath) {
			if(!FileExist(this.path)) { ; Don't try to open a non-existent local path
				Toast.ShowError("Local file or folder does not exist", this.path)
				return ""
			}
		}
		
		return this.path
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Determine the type of the given path.
	; PARAMETERS:
	;  path (I,REQ) - The path itself.
	; RETURNS:        The type of path, from PathType_* constants.
	;---------
	determinePathType(path) {
		if(StringLib.isURL(path))
			return ActionObjectPath.PathType_URL
		
		if(FileLib.isFilePath(path))
			return ActionObjectPath.PathType_FilePath
		
		return ""
	}
	
	;---------
	; DESCRIPTION:    Do some additional processing on the different bits of info about the object.
	; SIDE EFFECTS:   Can update this.path.
	;---------
	postProcess() {
		Switch this.pathType {
			case ActionObjectPath.PathType_URL:
				; For URLs, make sure that they have a protocol at the start so Windows knows how to run it as a URL
				; (not a local path).
				if(!this.path.contains("//")) ; No protocol
					this.path := "https://" this.path ; Add a protocol on so Windows knows to run it as a URL.
			
			case ActionObjectPath.PathType_FilePath:
				this.path := FileLib.cleanupPath(this.path)
		}
	}
	; #END#
}
