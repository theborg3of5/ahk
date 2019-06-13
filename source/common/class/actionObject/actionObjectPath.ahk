#Include %A_LineFile%\..\actionObjectBase.ahk

/* Class for ***
	
	***
*/

class ActionObjectPath extends ActionObjectBase {
	; ==============================
	; == Public ====================
	; ==============================
	
	static PATHTYPE_FilePath := "FILEPATH"
	static PATHTYPE_URL      := "URL"
	
	path     := "" ; The path itself.
	pathType := "" ; Type of path, from PATHTYPE_* constants.
	
	
	__New(path, pathType := "") {
		this.path     := path
		this.pathType := pathType
		
		; Make sure there's no quotes or other oddities surrounding the path
		this.path := cleanupText(this.path, [DOUBLE_QUOTE])
		
		; Determine path type
		if(this.pathType = "")
			this.pathType := this.determinePathType(this.path)
	}
	
	determinePathType(path) {
		; Full URLs
		if(stringMatchesAnyOf(path, ["http://", "https://", "ftp://"], CONTAINS_START))
			return ActionObjectPath.PATHTYPE_URL
		
		; Filepaths
		if(stringMatchesAnyOf(path, ["file:///", "\\"], CONTAINS_START)) ; URL-formatted file path, Windows network path
			return ActionObjectPath.PATHTYPE_FilePath
		if(subStr(path, 2, 2) = ":\")  ; Windows filepath (starts with drive letter + :\)
			return ActionObjectPath.PATHTYPE_FilePath
		
		; Partial URLs (www.google.com, similar)
		if(stringMatchesAnyOf(path, ["www.", "vpn.", "m."], CONTAINS_START))
			return ActionObjectPath.PATHTYPE_URL
		
		; Unknown
		return ""
	}
	
	openWeb() {
		this.openEdit() ; Opening web and edit are the same
	}
	openEdit() {
		if(!this.path)
			return
		if(this.pathType = ActionObjectPath.PATHTYPE_FilePath && !FileExist(this.path)) { ; Don't try to open a non-existent local path
			DEBUG.popup("Local file or folder does not exist", this.path)
			return
		}
		
		Run(this.path)
	}
	
	getLinkWeb() {
		return this.path
	}
}
