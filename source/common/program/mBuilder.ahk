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

		t := new Toast("Opening DLG in MBuilder: " dlgId).show()
		
		Config.runProgram("MBuilder")
		WinWaitActive, % Config.windowInfo["MBuilder"].titleString, , 10 ; 10-second timeout
		
		if(ErrorLevel != 1) {
			; Plug in the DLG ID.
			Send, 2{Enter} ; Check for errors on a DLG's Routines
			Sleep, 500
			Send, % dlgId
			Send, {Enter}
		}
		
		t.close()
	}
	; #END#
}