; Generate and add a line for a specific environment to the environments TLS file.

#Include <includeCommon>
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)
FileEncoding, UTF-8 ; Read files in UTF-8 encoding by default to handle special characters.

progToast := new ProgressToast("Adding exported environment TLS lines").blockingOn()

; Read file from database
progToast.nextStep("Reading file from database")
dataLines := FileLib.fileLinesToArray(Config.path["EPIC_NFS_ASK"] "\temp\environmentData.txt").removeEmpties() ; Drop any leading/trailing newlines
if(dataLines.length() = 0) {
	Toast.BlockAndShowError("Can't add new TLS lines", "No data in database file")
	ExitApp
}
addingEntireSUVersion := areAddingEntireSUVersion(dataLines)
if(addingEntireSUVersion)
	progToast.endStep("Done, found all SU environments for new version")

; Load existing environments
progToast.nextStep("Reading in existing environments")
environmentsFilePath := FileLib.findConfigFilePath("epicEnvironments.tls")
environmentLines := FileLib.fileLinesToArray(environmentsFilePath)
if(!handleDuplicateEnvironments(environmentLines, dataLines))
	ExitApp

; Generate new TLS lines to insert
progToast.nextStep("Generating new TLS lines")
newLines := []
For i, dataLine in dataLines
	newLines.push(buildTLSLine(dataLine))

; Add new lines to environments TLS
progToast.nextStep("Adding new TLS lines")
if(addingEntireSUVersion) {
	firstNewEnvLine := insertSULines(environmentLines, newLines) ; SU environments go into (multiple) specific spots
} else {
	firstNewEnvLine := 3 ; By default we add everything at the top, just after various headers
	environmentLines.InsertAt(firstNewEnvLine, newLines*) ; Otherwise just add them all to the top
}

; Save updated TLS lines to file
progToast.nextStep("Writing to TLS file")
FileLib.replaceFileWithString(environmentsFilePath, environmentLines.join("`r`n"))

; Launch the TLS for editing
progToast.nextStep("Launching TLS file to edit")
VSCode.editScript("--goto " environmentsFilePath ":" firstNewEnvLine) ; Focus the line we added to

progToast.finish()
return


; Wait for me to move the new line to the proper place in the environments TLS and save, or to just close the file.
~^w::
~^s::
	if(GuiLib.showConfirmationPopup("Reformat environments TLS file?"))
		Run(Config.path["AHK_SOURCE"] "\standalone\reformatAllTLFiles.ahk " environmentsFilePath)
	ExitApp
return


;---------
; DESCRIPTION:    Check whether we're adding an entire SU version of environments - this affects where we insert our
;                 new TLS lines.
; PARAMETERS:
;  dataLines (I,REQ) - Array of new environment data lines from the database.
; RETURNS:        true/false
;---------
areAddingEntireSUVersion(dataLines) {
	; Adding the entire version involves adding 5 environments (3 DBC + 2 Normal)
	if(dataLines.length() != 5)
		return false
	
	; Comm ID should start with "SU" + 3-digit version number
	commId := dataLines[1].piece("^", 4)
	if(!commId.startsWith("SU"))
		return false
	if(!commId.sub(3, 3).isNum())
		return false
	
	; Not 100% guaranteed, but should be good enough to say this is the case.
	return true
}

;---------
; DESCRIPTION:    Check whether we're trying to add environments that already exist in the TLS file (based on their
;                 comm IDs), and check if the user wants to continue if so.
; PARAMETERS:
;  environmentLines (I,REQ) - Array of existing environment TLS lines
;  dataLines        (I,REQ) - Array of new environment data lines from the database
; RETURNS:        true if we're good to continue, false if we should exit.
;---------
handleDuplicateEnvironments(environmentLines, dataLines) {
	; Build an index of our new environments by commId
	newEnvironments := {}
	For _, line in dataLines {
		name   := line.piece("^", 1)
		commId := line.piece("^", 4)
		if(commId = "")
			Continue

		newEnvironments[commId] := name
	}

	; Check new environments against existing ones
	duplicateEnvironments := []
	For _, line in environmentLines {
		For newCommId, newName in newEnvironments {
			if(line.containsPiece(newCommId, "`t"))
				duplicateEnvironments.push(newName)
		}
	}

	; Prompt with duplicates
	if(duplicateEnvironments.length() > 0) {
		if(!GuiLib.showConfirmationPopup("These environments already exist in the TLS, add them again?" "`n`n" duplicateEnvironments.join("`n")))
			return false
	}

	return true
}

;---------
; DESCRIPTION:    Build a single new TLS line for an environment.
; PARAMETERS:
;  dataLine (I,REQ) - The line of environment data from the database. Format:
;                     	envDotTwo^displayName^abbrev^commId^denId^vdiId^versionNum^webURL
; RETURNS:        TLS line, broken up by (single - reformatting happens at the end) tabs.
;---------
buildTLSLine(dataLine) {
	shortMonth := versionShortName.beforeString(" ")
	shortYear  := versionShortName.afterString(" ")

	data := dataLine.split("^")
	envDotTwo   := data[1]
	displayName := data[2]
	abbrev      := data[3]
	commId      := data[4]
	denId       := data[5]
	vdiId       := data[6]
	versionNum  := data[7]
	webURL      := data[8]

	abbrev := abbrev ? abbrev : "***" ; Abbreviation defaults to a placeholder

	return displayName "`t" abbrev "`t" commId "`t" denId "`t" vdiId "`t" versionNum "`t" webURL
}

;---------
; DESCRIPTION:    Insert the new SU environment TLS lines into an array of existing lines, in their proper locations.
; PARAMETERS:
;  environmentLines (IO,REQ) - Array of environment TLS lines to add to.
;  newLines          (I,REQ) - Array of new environment TLS lines to add
; RETURNS:        Line number for the first environment we inserted
;---------
insertSULines(environmentLines, newLines) {
	dbcLines    := []
	normalLines := []
	
	; Separate out DBC vs normal lines (as they get inserted in different spots).
	For i, line in newLines {
		commId := line.piece("`t", 3)
		if(commId.contains("NL")) ; Assuming all DBC environments have "NL" in their comm ID
			dbcLines.push(line)
		else
			normalLines.push(line)
	}

	; Add an extra empty line to the end of each to space them out from the previous (physically following) version
	dbcLines.push("")
	normalLines.push("")
	
	dbcHeaderIndex  := environmentLines.contains("# ! DBC SUs")
	environmentLines.InsertAt(dbcHeaderIndex + 1, dbcLines*)
	
	normalHeaderIndex := environmentLines.contains("# ! Normal SUs")
	environmentLines.InsertAt(normalHeaderIndex + 1, normalLines*)

	return dbcHeaderIndex + 1
}
