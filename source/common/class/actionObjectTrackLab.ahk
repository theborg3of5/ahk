#Include ..\base\actionObjectBase.ahk

/* Class for performing actions on TrackLab (Git) objects.
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
;		ao := new ActionObjectTrackLab("commit a526d5")
;		MsgBox, ao.getLink() ; Link (in TrackLab)
;		ao.open()            ; Open (in TrackLab)
;		
;		ao := new ActionObjectTrackLab("a526d2") ; ID without an INI, user will be prompted for the INI
;		ao.open() ; Open
	
*/

class ActionObjectTrackLab extends ActionObjectBase {
	;region ------------------------------ PUBLIC ------------------------------
	ActionObjectType := ActionObject.Type_TrackLab

	;region Object actions
	static SubType_ViewCommit        := "VIEW_COMMIT"
	static SubType_DLGBranch         := "DLG_BRANCH"
	static SubType_FileHistory_S1    := "FILE_HISTORY_S1"
	static SubType_FileHistory_FINAL := "FILE_HISTORY_FINAL"
	static SubType_FileBlame_S1      := "FILE_BLAME_S1"
	static SubType_FileBlame_FINAL   := "FILE_BLAME_FINAL"
	;endregion Object actions
	
	id     := "" ; ID of the object
	subType := "" ; Thing to launch, from SubType_*
	
	;---------
	; DESCRIPTION:    Create a new reference to a TrackLab object.
	; PARAMETERS:
	;  id      (I,REQ) - ID of the object
	;  subType (I,OPT) - SubType of the object, from ActionObjectTrackLab.SubType_*. Prompted for if
	;                    not given.
	;---------
	__New(id, subType := "") {
		if(!this.selectMissingInfo(id, subType))
			return ""
		
		this.id      := id
		this.subType := subType
	}
	
	;---------
	; DESCRIPTION:    Determine whether the given string MUST be this type of ActionObject.
	; PARAMETERS:
	;  value   (I,REQ) - The value to evaluate
	;  subType (O,OPT) - If the value is a TrackLab record, the subType.
	;  id      (O,OPT) - If the value is a TrackLab record, the ID.
	; RETURNS:        true/false - whether the given value must be a TrackLab object.
	; NOTES:          Must be effectively static - this is called before we decide what kind of object to return.
	;---------
	isThisType(value, ByRef subType := "", ByRef id := "") {
		if(!Config.contextIsWork)
			return false

		if(value.startsWithAnyOf(["git ", "commit "], matchedPrefix)) {
			subType := this.SubType_ViewCommit
			id := value.removeFromStart(matchedPrefix)
			return true
		}
		
		return false
	}
	
	;---------
	; DESCRIPTION:    Get a link to the object.
	; RETURNS:        Link to TrackLab
	;---------
	getLink() {
		; Specific branches, pulled out here for readability
		stage1Branch := Config.private["GIT_BRANCH_CURRENT_S1"]
		finalBranch  := Config.private["GIT_BRANCH_CURRENT_FINAL"]

		Switch this.subType {
			Case this.SubType_ViewCommit:
				return Config.private["TRACKLAB_GIT_COMMIT"].replaceTags({ COMMIT: this.id })
			Case this.SubType_DLGBranch:
				return Config.private["TRACKLAB_GIT_FILE_HISTORY"].replaceTags({ BRANCH: "dlg/" this.id, FILEPATH: "" })
			Case this.SubType_FileHistory_S1:
				return Config.private["TRACKLAB_GIT_FILE_HISTORY"].replaceTags({ BRANCH: stage1Branch, FILEPATH: this.id })
			Case this.SubType_FileHistory_FINAL:
			 	return Config.private["TRACKLAB_GIT_FILE_HISTORY"].replaceTags({ BRANCH: finalBranch, FILEPATH: this.id })
			Case this.SubType_FileBlame_S1:
				return Config.private["TRACKLAB_GIT_FILE_BLAME"].replaceTags({ BRANCH: stage1Branch, FILEPATH: this.id })
			Case this.SubType_FileBlame_FINAL:
				return Config.private["TRACKLAB_GIT_FILE_BLAME"].replaceTags({ BRANCH: finalBranch, FILEPATH: this.id })
		}

		return ""
	}
	;endregion ------------------------------ PUBLIC ------------------------------
}
