#Include %A_LineFile%\..\actionObjectBase.ahk

/* Class for performing actions on a path.
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
		ao := new ActionObjectPath("F:\personal\eyobuddy") ; Local path or URL, user will be prompted for which it is
		MsgBox, ao.getLinkWeb()  ; Returns path (equivalent to .getLinkEdit())
		ao.openWeb()             ; Open path (equivalent to .openEdit())
		
		ao := new ActionObjectPath("google.com", ActionObjectPath.PathType_URL) ; Specify path type if known to avoid prompting
		ao.openEdit() ; Run URL
*/

class ActionObjectPath extends ActionObjectBase {

; ==============================
; == Public ====================
; ==============================
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
		this.path := cleanupText(this.path, [DOUBLE_QUOTE])
		
		; Determine path type
		if(this.pathType = "")
			this.pathType := this.determinePathType(this.path)
	}
	
	;---------
	; DESCRIPTION:    Determine the type of the given path.
	; PARAMETERS:
	;  path (I,REQ) - The path itself.
	; RETURNS:        The type of path, from PathType_* constants.
	;---------
	determinePathType(path) {
		; Full URLs
		if(stringMatchesAnyOf(path, ["http://", "https://", "ftp://"], CONTAINS_START))
			return ActionObjectPath.PathType_URL
		
		; Filepaths
		if(stringMatchesAnyOf(path, ["file:///", "\\"], CONTAINS_START)) ; URL-formatted file path, Windows network path
			return ActionObjectPath.PathType_FilePath
		if(subStr(path, 2, 2) = ":\")  ; Windows filepath (starts with drive letter + :\)
			return ActionObjectPath.PathType_FilePath
		
		; Partial URLs (www.google.com, similar)
		if(stringMatchesAnyOf(path, ["www.", "vpn.", "m."], CONTAINS_START))
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
			DEBUG.popup("Local file or folder does not exist", this.path)
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
}
