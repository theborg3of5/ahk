#Include ..\base\actionObjectBase.ahk

/* Class for performing actions on various web records (helpdesk tickets, NullEx posts, etc.)
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
;		ao := new ActionObjectWebRecord("HDR 123456")
;		MsgBox, ao.getLinkWeb()  ; Link to helpdesk request (equivalent to .getLinkEdit())
;		ao.openWeb()             ; Open web portal to request (equivalent to .openEdit())
	
*/

class ActionObjectWebRecord extends ActionObjectBase {
	;region ------------------------------ PUBLIC ------------------------------
	ActionObjectType := ActionObject.Type_WebRecord

	;region Record types
	static RecordType_Helpdesk := "HELPDESK" ; Helpdesk ticket
	static RecordType_NullEx   := "NULLEX"   ; NullEx post
	;endregion Record types
	
	id         := "" ; Record ID
	recordType := "" ; Record type
	
	;---------
	; DESCRIPTION:    Create a new reference to a web record.
	; PARAMETERS:
	;  id         (I,REQ) - ID of the record.
	;  recordType (I,OPT) - The type of record, from ActionObjectWebRecord.RecordType_*. If not given, we'll try to 
	;---------
	__New(id, recordType := "") {
		if(!this.selectMissingInfo(id, recordType))
			return ""
		
		this.id         := id
		this.recordType := recordType
	}
	
	;---------
	; DESCRIPTION:    Determine whether the given string must be this type of ActionObject.
	; PARAMETERS:
	;  value      (I,REQ) - The value to evaluate
	;  recordType (O,OPT) - If the value is a web record, the type of web record (from ActionObjectWebRecord.RecordType_*)
	;  id         (O,OPT) - If the value is a web record, the ID
	; RETURNS:        true/false - whether the given value must be a web record.
	;---------
	isThisType(value, ByRef recordType := "", ByRef id := "") {
		if(!Config.contextIsWork)
			return false
		
		if(value.startsWithAnyOf(["HDR ", "helpdesk "], matchedType)) {
			recordType := this.RecordType_Helpdesk
			id := value.removeFromStart(matchedType)
			return true
		}
		
		if(value.startsWithAnyOf(["NullEx "], matchedType)) {
			recordType := this.RecordType_NullEx
			id := value.removeFromStart(matchedType)
			return true
		}
		
		return false
	}
	
	;---------
	; DESCRIPTION:    Get a link to the record.
	; RETURNS:        Link to the record.
	;---------
	getLink() {
		Switch this.recordType {
			Case ActionObjectWebRecord.RecordType_Helpdesk:
				return Config.private["HELPDESK_BASE"].replaceTag("ID", this.id)
				
			Case ActionObjectWebRecord.RecordType_NullEx:
				return Config.private["NULLEX_BASE"].replaceTag("ID", this.id)
		}
		
		return ""
	}
	;endregion ------------------------------ PUBLIC ------------------------------
}
