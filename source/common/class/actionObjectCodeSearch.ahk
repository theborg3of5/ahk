#Include ..\base\actionObjectBase.ahk

/* Class for performing actions based on a code location in CodeSearch. --=
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
;		ao := new ActionObjectCodeSearch("tagName^routineName")
;		MsgBox, ao.getLinkWeb()  ; Link in CodeSearch
;		ao.openWeb()             ; Open in CodeSearch
;		
;		new ActionObjecCodeSearch("blah.cls").open() ; Opens a search page for the filename, since we can't know the right directory ID
	
*/ ; =--

class ActionObjectCodeSearch extends ActionObjectBase {
	; #PUBLIC#
	
	; @GROUP@ Location types
	static LocationType_Server := "SERVER" ; Server code location, including tag if applicable
	static LocationType_Client := "CLIENT" ; Client filename
	; @GROUP-END@
	
	; @GROUP@
	location     := "" ; Code location to work with
	locationType := "" ; Which type of code, server or client (from LocationType_* constants)
	; @GROUP-END@
	
	;---------
	; DESCRIPTION:    Create a new reference to a CodeSearch object.
	; PARAMETERS:
	;  location (I,REQ) - Value representing the code location
	;---------
	__New(location, locationType := "") {
		this.location     := location
		this.locationType := locationType
		
		if(this.locationType = "")
			this.locationType := this.determineLocationType()
		
		if(!this.selectMissingInfo())
			return ""
	}
	
	;---------
	; DESCRIPTION:    Get a link in CodeSearch to the code location.
	; RETURNS:        Link to CodeSearch for the code location.
	;---------
	getLink() {
		Switch this.locationType {
			Case this.LocationType_Server:
				EpicLib.splitServerLocation(this.location, routine, tag)
				routine := StringLib.encodeForURL(routine)
				tag     := StringLib.encodeForURL(tag)
				
				return Config.private["CS_SERVER_CODE_BASE"].replaceTags({"ROUTINE":routine, "TAG":tag})
				
			Case this.LocationType_Client:
				return Config.private["CS_CLIENT_CODE_BASE"].replaceTag("FILENAME", this.location)
		}
		
		return ""
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Try to figure out what kind of location we've been given based on its format.
	; RETURNS:        Location type from LocationType_* constants
	;---------
	determineLocationType() {
		; Includes a tag/routine separator
		if(this.location.contains("^"))
			return ActionObjectCodeSearch.LocationType_Server
		
		; Includes a file extension
		if(this.location.contains("."))
			return ActionObjectCodeSearch.LocationType_Client
		
		return ""
	}
	
	;---------
	; DESCRIPTION:    Prompt the user for the code location if it's missing.
	; SIDE EFFECTS:   Sets .location based on user inputs.
	;---------
	selectMissingInfo() {
		; Nothing is missing
		if(this.location != "" && this.locationType != "")
			return true
		
		s := new Selector("actionObject.tls").setDefaultOverrides({"VALUE":this.location})
		s.dataTableList.filterByColumn("TYPE", ActionObject.Type_CodeSearch)
		data := s.selectGui()
		if(!data)
			return false
		if(data["SUBTYPE"] = "" || data["VALUE"] = "") ; Didn't get everything we needed.
			return false
		
		this.locationType := data["SUBTYPE"]
		this.location     := data["VALUE"]
		return true
	}
	; #END#
}
