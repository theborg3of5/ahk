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

; Load Thunder IDs from shortcuts
progToast.nextStep("Reading Thunder IDs from shortcuts folder")
thunderIDs := getThunderIDsFromShortcuts()

; Generate new TLS lines to insert
progToast.nextStep("Generating new TLS lines")
newLines := []
For i, dataLine in dataLines
	newLines.push(buildTLSLine(dataLine, thunderIDs))

; Add new lines to environments TLS
progToast.nextStep("Adding new TLS lines")

if(addingEntireSUVersion) {
	firstNewEnvLine := insertSULines(environmentLines, newLines) ; SU environments go into (multiple) special spots
} else {
	firstNewEnvLine := 3 ; By default we add everything at the top, just after various headers
	environmentLines.InsertAt(firstNewEnvLine, newLines*) ; Otherwise just add them all to the top
}

; Save updated TLS lines to file
progToast.nextStep("Writing to TLS file")
FileLib.replaceFileWithString(environmentsFilePath, environmentLines.join("`r`n"))

; Launch the TLS for editing
progToast.nextStep("Launching TLS file to edit")
Config.runProgram("VSCode", "--goto " environmentsFilePath ":" firstNewEnvLine) ; Focus the line we added to

progToast.finish()
return


; Wait for me to move the new line to the proper place in the environments TLS and save, or to just close the file.
~^w::
~^s::
	if(GuiLib.showConfirmationPopup("Reformat environments TLS file?"))
		Run(Config.path["AHK_SOURCE"] "\standalone\reformatAllTLFiles.ahk " environmentsFilePath)
	ExitApp
return


; GDB doc
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

; GDB TODO doc
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
; DESCRIPTION:    Pull the environment names and corresponding Thunder IDs from Launchy shortcuts.
; RETURNS:        Associative array: { environmentName: thunderId }
;                 Note that environmentName is the display name in Thunder (including any folder names!)
;---------
getThunderIDsFromShortcuts() {
	thunderIDs := {}

	shortcutsFolder := Config.path["USER_ROOT"] "\Thunder Shortcuts"
	Loop, Files, %shortcutsFolder%\*.lnk
	{
		FileGetShortcut(A_LoopFilePath, "", "", thunderId) ; Argument is the thunder ID we need
		name := A_LoopFileName.removeFromStart(namePrefix).removeFromEnd("." A_LoopFileExt)
		thunderIDs[name] := thunderId
	}

	return thunderIDs
}

;---------
; DESCRIPTION:    Build a single new TLS line for an SU environment.
; PARAMETERS:
;  dataLine         (I,REQ) - The line of environment data from the database. Format:
;                             	commId|denId|envName|webURL ; GDB TODO redoc
;  versionNum       (I,REQ) - The dotted version number (i.e. 10.4)
;  versionShortName (I,REQ) - The version "short" name (i.e. Feb 22)
;  thunderIDs       (I,REQ) - Associate array of { environmentName: thunderId }
;  isDBC            (O,REQ) - Set to true if this is a DBC environment, false otherwise.
; RETURNS:        TLS line, broken up by tabs.
;---------
buildTLSLine(dataLine, thunderIDs) {
	shortMonth := versionShortName.beforeString(" ")
	shortYear  := versionShortName.afterString(" ")

	data := dataLine.split("^")
	envName     := data[1]
	displayName := data[2]
	abbrev      := data[3]
	commId      := data[4]
	denId       := data[5]
	vdiId       := data[6]
	versionNum  := data[7]
	webURL      := data[8]

	displayName := displayName ? displayName : envName ; Display name defaults to the full environment name ; GDB TODO may not need if I pull a nicer one on database
	abbrev := abbrev ? abbrev : "***" ; Abbreviation defaults to a placeholder
	
	; Thunder ID (mapped from full environment name)
	thunderId := mapNameToThunderID(thunderIDs, envName)

	return displayName "`t" abbrev "`t" commId "`t" denId "`t" thunderId "`t" vdiId "`t" versionNum "`t" webURL
}

; GDB TODO doc
mapNameToThunderID(thunderIDs, envName) {
	For name, id in thunderIDs {
		if(name.endsWith(envName))
			return id ; Just return the first match.
	}

	return "***" ; If no match, use a placeholder.
}

;---------
; DESCRIPTION:    Check whether the version already exists in the environments TLS,
;                 and ask the user to confirm if they still want to add it.
; PARAMETERS:
;  environmentLines (I,REQ) - Array of TLS lines from the current environments TLS file.
;  versionShortName (I,REQ) - The "short" name of the version (i.e. Feb 22)
; RETURNS:        true if we can continue, false if we need to exit
;---------
checkIfVersionExists(environmentLines, versionShortName) { ; GDB TODO remove
	matchingLine := ""
	For _, line in environmentLines {
		line := line.withoutWhitespace()
		if(line.startsWith(versionShortName)) {
			matchingLine := line
			Break
		}
	}
	
	if(matchingLine != "")
		return GuiLib.showConfirmationPopup("SU version """ versionShortName """ already appears in TLS: `n" matchingLine "`n`nDo you want to new TLS lines anyway?")
	
	return true
}

;---------
; DESCRIPTION:    Insert the new TLS lines into an array of existing lines.
; PARAMETERS:
;  environmentLines (IO,REQ) - Array of environment TLS lines to add to.
;  dbcLines          (I,REQ) - Array of new DBC SU environment TLS lines to add
;  normalLines       (I,REQ) - Array of new non-DBC SU environment TLS lines to add
;--------- ; GDB TODO redoc
insertSULines(ByRef environmentLines, newLines) {
	dbcLines    := []
	normalLines := []
	
	; Separate out DBC vs normal lines (as they get inserted in different spots).
	For i, line in newLines {
		commId := line.piece("`t", 3)
		if(commId.contains("NL"))
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
