class MBuilder {
	; #PUBLIC#

	;---------
	; DESCRIPTION:    Run linting for the DLG found in the active window's title.
	;---------
	lintCurrentDLG() {
		record := EpicLib.getBestEMC2RecordFromText(WinGetActiveTitle())
		if(record.ini != "DLG" || record.id = "") {
			Toast.ShowError("Could not open DLG in MBuilder", "Record ID was blank or was not a DLG ID")
			return
		}
		
		this.lintDLG(record.id)
	}

	;---------
	; DESCRIPTION:    Run linting for the given DLG's routines.
	; PARAMETERS:
	;  dlgId (I,REQ) - DLG ID
	;---------
	lintDLG(dlgId) {
		if(!dlgId) {
			Toast.ShowError("Could not open DLG in MBuilder", "DLG ID was blank")
			return
		}

		Toast.ShowShort("Linting DLG in MBuilder: " dlgId)

		Run(Config.private["MBUILDER_URL_BASE"].replaceTags({"COMMAND":2, "ID":dlgId})) ; 2-Lint a DLG's Routines
	}
	; #END#
}