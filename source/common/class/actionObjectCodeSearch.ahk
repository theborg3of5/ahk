#Include ..\base\actionObjectBase.ahk

/* Class for performing actions based on a code location in CodeSearch.
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
;		ao := new ActionObjectCodeSearch("tagName^routineName")
;		MsgBox, ao.getLinkWeb()  ; Link in CodeSearch
;		ao.openWeb()             ; Open in CodeSearch
;		
;		new ActionObjectCodeSearch("blah.cls").open() ; Opens a search page for the filename, since we can't know the right directory ID
	
*/

class ActionObjectCodeSearch extends ActionObjectBase {
	;region ------------------------------ PUBLIC ------------------------------
	ActionObjectType := ActionObject.Type_CodeSearch
	
	;region Location types
	static LocationType_Server := "SERVER" ; Server code location, including tag if applicable
	static LocationType_Client := "CLIENT" ; Client filename
	;endregion Location types
	
	location     := "" ; Code location to work with
	locationType := "" ; Which type of code, server or client (from LocationType_* constants)
	
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
	; DESCRIPTION:    Determine whether the given string must be a CodeSearch code location.
	; PARAMETERS:
	;  value        (I,REQ) - The value to evaluate
	;  locationType (O,OPT) - If the value is a code location, the location type
	; RETURNS:        true/false - whether the given value must be a CodeSearch code location.
	;---------
	isThisType(value, ByRef locationType := "") {
		if(!Config.contextIsWork)
			return false
		
		; Other characters COULD match this, but this is the only one that's definitive.
		if(value.contains("::")) {
			locationType := this.LocationType_Client
			; Not trying to split it up here, we'll do that when we actually create this object instead.
			return true
		}
		
		return false
	}
	
	;---------
	; DESCRIPTION:    Get a link in CodeSearch to the code location.
	; RETURNS:        Link to CodeSearch for the code location.
	;---------
	getLink() {
		Switch this.locationType {
			Case this.LocationType_Server:
				return SearchLib.buildCodeSearchURL("routine", "", "", "", "name=" this.location.replace("%", "%25")) ; Make sure to encode any % in the routine name
				
			Case this.LocationType_Client:
				; Specific function handling - make the function (with opening paren) the search term.
				searchTerm := ""
				if(this.location.contains("::")) {
					this.location := this.location.afterString("::")
					searchTerm := this.location.beforeString("::").removeFromEnd(")") ; Drop closing paren if it exists
				}
				
				return SearchLib.buildCodeSearchURL("client", searchTerm, "", "", "", this.location)
		}
		
		return ""
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
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
		if(location.containsAnyOf([".", "::"]))
			return ActionObjectCodeSearch.LocationType_Client
		
		return ""
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
