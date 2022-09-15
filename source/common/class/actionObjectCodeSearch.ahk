#Include ..\base\actionObjectBase.ahk

/* Class for performing actions based on a code location in CodeSearch. =--
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
;		ao := new ActionObjectCodeSearch("tagName^routineName")
;		MsgBox, ao.getLinkWeb()  ; Link in CodeSearch
;		ao.openWeb()             ; Open in CodeSearch
;		
;		new ActionObjectCodeSearch("blah.cls").open() ; Opens a search page for the filename, since we can't know the right directory ID
	
*/ ; --=

class ActionObjectCodeSearch extends ActionObjectBase {
	; #PUBLIC#
	
	ActionObjectType := ActionObject.Type_CodeSearch
	
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
	;  location     (I,REQ) - Value representing the code location
	;  locationType (I,OPT) - Type of CodeSearch location, from LocationType_* constants. If not given, we'll figure it out based
	;                         on the format or by prompting the user.
	;---------
	__New(location, locationType := "") {
		if(locationType = "")
			locationType := this.determineLocationType(location)
		
		if(!this.selectMissingInfo(location, locationType))
			return ""
		
		this.location     := location
		this.locationType := locationType
	}
	
	;---------
	; DESCRIPTION:    Get a link in CodeSearch to the code location.
	; RETURNS:        Link to CodeSearch for the code location.
	;---------
	getLink() {
		Switch this.locationType {
			Case this.LocationType_Server:
				return SearchLib.buildCodeSearchURL("routine", "", "", "", "name=" this.location)
				
			Case this.LocationType_Client:
				return SearchLib.buildCodeSearchURL("client", "", "", "", "", this.location)
		}
		
		return ""
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Try to figure out what kind of location we've been given based on its format.
	; PARAMETERS:
	;  location (I,REQ) - The location to try and figure out the type of.
	; RETURNS:        Location type from LocationType_* constants
	;---------
	determineLocationType(location) {
		; Includes a tag/routine separator
		if(location.contains("^"))
			return ActionObjectCodeSearch.LocationType_Server
		
		; Includes a file extension
		if(location.contains("."))
			return ActionObjectCodeSearch.LocationType_Client
		
		return ""
	}
	; #END#
}
