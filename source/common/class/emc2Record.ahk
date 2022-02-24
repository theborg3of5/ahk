/* Class to represent Epic records that specifically belong in EMC2, with extra handling for different input formats. =--
	
	Additional handling:
		Special email title formats (extra stuff on the start like "PRJ Readiness", "EMC2 Lock:")
		Converting INIs to their most useful form (Design => XDS, ZQN => QAN, etc.)
	
	Example Usage
;		record := new EMC2Record("DLG", 123456, "Did some stuff!")
;		
;		record := new EMC2Record().initFromRecordString("PRJ Readiness: DLG 123456")
;		MsgBox, % record.ini ; DLG
;		MsgBox, % record.id  ; 123456
;		
;		record := new EMC2Record().initFromEMC2Title() ; Use EMC2 window title to get needed info
;		MsgBox, % record.recordString ; R DLG 123456
	
*/ ; --=

class EMC2Record extends EpicRecord {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Initialize the record based on a string.
	; PARAMETERS:
	;  recordString (I,REQ) - String representing the record. See class header for supported
	;                         formats.
	; RETURNS:        this
	;---------
	initFromRecordString(recordString) {
		base.initFromRecordString(recordString)
		this.postProcess()
		
		return this
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Do some additional processing on the different bits of info about the object.
	; SIDE EFFECTS:   Can update this.ini, this.id, and this.title.
	;---------
	postProcess() {
		; INI - make sure the INI is the "real" EMC2 one.
		this.ini := EpicLib.convertToUsefulEMC2INI(this.ini)
	}
	; #END#
}
