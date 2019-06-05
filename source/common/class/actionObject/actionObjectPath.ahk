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
	
	; Named property equivalents for the base generic variables, so base functions still work.
	path[] {
		get {
			return this.value
		}
		set {
			this.value := value
		}
	}
	pathType[] {
		get {
			return this.subType
		}
		set {
			this.subType := value
		}
	}
	
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
		if(subStr(text, 2, 2) = ":\")  ; Windows filepath (starts with drive letter + :\)
			return ActionObjectPath.PATHTYPE_FilePath
		
		; Partial URLs (www.google.com, similar)
		if(stringMatchesAnyOf(path, ["www.", "vpn.", "m."], CONTAINS_START))
			return ActionObjectPath.PATHTYPE_URL
		
		; Unknown
		return ""
	}
	
	open() {
		if(!this.path)
			return
		if(subType = ActionObjectPath.PATHTYPE_FilePath && !FileExist(this.path)) { ; Don't try to open a non-existent local path
			DEBUG.popup("Local file or folder does not exist", this.path)
			return
		}
		
		Run(this.path)
	}
	
	getLink() {
		return this.path
	}
}
