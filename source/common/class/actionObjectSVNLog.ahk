#Include ..\base\actionObjectBase.ahk

/* Class for performing actions based on an SVN log, filtered by something. =--
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
;		ao := new ActionObjectSVNLog(1234567, ActionObjectSVNLog.FilterType_Revision)
;		ao.open() ; Open SVN log filtered to the given revision
;
;		ao := new ActionObjectSVNLog(123456, ActionObjectSVNLog.FilterType_DLG)
;		ao.open() ; Open SVN log filtered to the given DLG's commits
	
*/ ; --=

class ActionObjectSVNLog extends ActionObjectBase {
	; #PUBLIC#
	
	ActionObjectType := ActionObject.Type_SVNLog
	
	; @GROUP@ Filter types
	static FilterType_Revision := "REVISION" ; Specific SVN commit/revision number
	static FilterType_DLG      := "DLG"      ; DLG in message
	; @GROUP-END@
	
	; @GROUP@ 
	filter     := "" ; String to filter the SVN log by.
	filterType := "" ; The method to use to filter the SVN log.
	; @GROUP-END@
	
	
	;---------
	; DESCRIPTION:    Create a new reference to a CodeSearch object.
	; PARAMETERS:
	;  filter     (I,REQ) - Filter value for the SVN log.
	;  filterType (I,OPT) - Filter method for the SVN log.
	;---------
	__New(filter, filterType := "") {
		if(!this.selectMissingInfo(filter, filterType))
			return ""
		
		this.filter     := filter
		this.filterType := filterType
	}
	
	;---------
	; DESCRIPTION:    Determine whether the given string must be an SVN log filter.
	; PARAMETERS:
	;  value      (I,REQ) - The value to evaluate
	;  filterType (O,OPT) - If the value is an SVN log filter, the filter type
	;  filter     (O,OPT) - If the value is an SVN log filter, the filter value
	; RETURNS:        true/false - whether the given value must be an SVN log filter.
	;---------
	isThisType(value, ByRef filterType := "", ByRef filter := "") {
		if(!Config.contextIsWork)
			return false
		
		if(value.startsWithAnyOf(["svn ", "commit ", "revision "], matchedKeyword)) {
			filterType := this.FilterType_Revision
			filter := value.removeFromStart(matchedKeyword)
			return true
		}
		
		if(value.startsWithAnyOf(["dsvn ", "svnd "], matchedKeyword)) {
			filterType := this.FilterType_DLG
			filter := value.removeFromStart(matchedKeyword)
			return true
		}
		
		return false
	}
	
	;---------
	; DESCRIPTION:    Get a link to the revision.
	; RETURNS:        Link to the SVN revision in the TortoiseSVN log window.
	;---------
	getLink() {
		link := ""
		
		Switch this.filterType {
			Case this.FilterType_Revision:
				link := "tsvncmd:command:log?path:<EPIC_SVN_URL>?startrev:<REVISION>?endrev:<REVISION>"
				link := Config.replacePrivateTags(link) ; Handles EPIC_SVN_URL
				link := link.replaceTag("REVISION", this.filter)
				
			Case this.FilterType_DLG:
				link := "tsvncmd:command:log?path:<EPIC_SVN_DLG_URL>?limit:100000?findstring:DLG=<DLG>?findtype:1"
				link := Config.replacePrivateTags(link) ; Handles EPIC_SVN_DLG_URL
				
				dlgId := this.filter
				link := link.replaceTags({"DLG":dlgId, "DLG_FIRST_4":dlgId.sub(1,4), "DLG_FIRST_2":dlgId.sub(1,2) }) ; DLG_FIRST_* are in EPIC_SVN_DLG_URL.
		}
		
		return link
	}
	; #END#
}
