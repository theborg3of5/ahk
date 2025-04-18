#Include actionObjectCodeSearch.ahk
#Include actionObjectEMC2.ahk
#Include actionObjectEpicCode.ahk
#Include actionObjectEpicStudio.ahk
#Include actionObjectSVNLog.ahk
#Include actionObjectTrackLab.ahk
#Include actionObjectPath.ahk
#Include actionObjectWebRecord.ahk

/* Class that takes some text representing an object, and allows the caller to do something with it. This class itself mostly redirects to the child ActionObject* classes, based on the input (and prompting the user).
	
	Example Usage
;		; Determine type based on input
;		ao := new ActionObject("DLG 123456") ; This will be an EMC2-type object, so ao is an ActionObjectEMC2 instance
;		ao.openWeb() ; Open the web version of the object
;		
;		; Will prompt user for both type and value with Selector popup because neither given
;		ao := new ActionObject()
;		ao.linkSelectedTextWeb() ; Links the selected text with a link built from the specific ActionObject* class in question
	
*/

class ActionObject {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Determine the type of ActionObject class to use based on the type/value
	;                 and return a new instance of that class.
	; PARAMETERS:
	;  value (I,OPT) - Input value to evaluate.
	; RETURNS:        An instance of ActionObject* (Code, EMC2, etc.) for the chosen type.
	; NOTES:          This does NOT return an ActionObject instance.
	;---------
	__New(value := "") {
		this.value := value
		this.value := this.value.firstLine().clean() ; Only first line, remove leading/trailing spaces and odd characters from value
		
		this.determineType()
		this.selectMissingInfo()
		
		; Debug.toast("ActionObject","All info determined", "this",this)
		return this.getTypeSpecificObject()
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	; Type constants
	static Type_CodeSearch := "CODESEARCH"
	static Type_EpicCode   := "EPICCODE"
	static Type_EpicStudio := "EPICSTUDIO"
	static Type_EMC2       := "EMC2"
	static Type_SVNLog     := "SVNLOG"
	static Type_TrackLab   := "TRACKLAB"
	static Type_Path       := "PATH"
	static Type_WebRecord  := "WEBRECORD"
	
	value   := "" ; Value (the unique bit of info to act upon, like a path or identifier)
	type    := "" ; Determined type of ActionObject, from .Type_* constants
	subType := "" ; Determined sub-type, an additional categorization within a particular ActionObject* class.
	
	;---------
	; DESCRIPTION:    Try to determine the type of ActionObject that we'll need based on the input value.
	;---------
	determineType() {
		if(ActionObjectWebRecord.isThisType(this.value, subType, id)) {
			this.type    := this.Type_WebRecord
			this.subType := subType
			this.value   := id
			
		} else if(ActionObjectPath.isThisType(this.value, pathType)) {
			this.type    := this.Type_Path
			this.subType := pathType
		
		} else if(ActionObjectTrackLab.isThisType(this.value, subType, id)) {
			this.type    := this.Type_TrackLab
			this.subType := subType
			this.value   := id
			
		} else if(ActionObjectSVNLog.isThisType(this.value, filterType, filter)) {
			this.type    := this.Type_SVNLog
			this.subType := filterType
			this.value   := filter
		
		} else if(ActionObjectEMC2.isThisType(this.value, ini, id)) {
			this.type    := this.Type_EMC2
			this.subType := ini
			this.value   := id
		
		} else if(ActionObjectCodeSearch.isThisType(this.value, locationType)) {
			this.type    := this.Type_CodeSearch
			this.subType := locationType
		}
	}
	
	;---------
	; DESCRIPTION:    Prompt the user for a value and/or type if those values are missing.
	; SIDE EFFECTS:   Sets .type, .subType, and .value based on the user's input.
	;---------
	selectMissingInfo() {
		; Nothing is missing
		if(this.value != "" && this.type != "")
			return
		
		s := new Selector("actionObject.tls").setDefaultOverrides({"VALUE":this.value})
		data := s.prompt()
		if(!data)
			return
		
		this.type    := data["TYPE"]
		this.subType := data["SUBTYPE"]
		this.value   := data["VALUE"]
	}
	
	;---------
	; DESCRIPTION:    Create a new ActionObject* instance matching the chosen type.
	; RETURNS:        New instance of an ActionObject* class
	;---------
	getTypeSpecificObject() {
		Switch this.type {
			Case "":                   return "" ; No determined type, silent quit, return nothing
			Case this.Type_CodeSearch: return new ActionObjectCodeSearch(this.value, this.subType)
			Case this.Type_EpicCode:   return new ActionObjectEpicCode(  this.value, this.subType)
			Case this.Type_EpicStudio: return new ActionObjectEpicStudio(this.value, this.subType)
			Case this.Type_EMC2:       return new ActionObjectEMC2(      this.value, this.subType)
			Case this.Type_TrackLab:   return new ActionObjectTrackLab(  this.value, this.subType)
			Case this.Type_Path:       return new ActionObjectPath(      this.value, this.subType)
			Case this.Type_SVNLog:     return new ActionObjectSVNLog(    this.value, this.subType)
			Case this.Type_WebRecord:  return new ActionObjectWebRecord( this.value, this.subType)
		}
		
		Toast.ShowError("Unrecognized type", "ActionObject doesn't know what to do with this type: " this.type)
		return ""
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
