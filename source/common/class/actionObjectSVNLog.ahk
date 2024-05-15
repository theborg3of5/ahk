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
	;region ------------------------------ PUBLIC ------------------------------
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
				dlgId := this.filter
				link := "tsvncmd:command:log?path:" this.generateDLGBranchURL(dlgId) "?limit:100000?findstring:DLG=" dlgId "?findtype:1"
		}
		
		return link
	}
	;endregion ==================== PUBLIC ====================

	;region ------------------------------ PRIVATE ------------------------------=
	;---------
	; DESCRIPTION:    Generate the branch URL for the given DLG.
	; PARAMETERS:
	;  dlgId (I,REQ) - DLG ID
	; RETURNS:        Branch URL, to the top level for the DLG (includes all rebranches below that)
	;---------
	generateDLGBranchURL(dlgId) {
		isSU := dlgId.startsWith("I")

		; Version prefix
		if(isSU) {
			if(dlgId.startsWith("I10"))
				versionNum := dlgId.sub(2, 3) ; 3-digit version
			else
				versionNum := dlgId.sub(2, 2) ; 2-digit version
			version := "I" versionNum
			dlgNum := dlgId.removeFromStart(version) ; SUs' intermediate folders don't include the version prefix
		} else {
			version := "0" ; Current version just uses a 0
		}
		
		; The intermediate folders are different sub-pieces of the DLG number (the DLG ID without any SU version prefix).
		dlgNum := dlgId.removeFromStart(version) ; Cheating slightly here by assuming current-version DLGs won't start with a 0
		dlgNumString := dlgNum ; Doing math on this below turns it into a number, so make a copy that retains any leading zeros.
		last4 := (dlgNum // 10000) * 10000 ; DLG number with last 4 digits as zero
		last2 := (dlgNum // 100) * 100     ; DLG number with last 2 digits as zero

		if(isSU)
			urlBase := Config.private["EPIC_SVN_DLG_BRANCH_URL_BASE_SU"]
		else
			urlBase := Config.private["EPIC_SVN_DLG_BRANCH_URL_BASE"]

		return urlBase.replaceTags({VERSION:version, NUM_LAST_4:last4, NUM_LAST_2:last2, NUM:dlgNumString, DLG:dlgId})
	}
	;endregion ==================== PRIVATE ====================
}
