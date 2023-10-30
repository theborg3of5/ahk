; Generate and add a line for a specific environment to the environments TLS file.

#Include <includeCommon>
FileEncoding, UTF-8 ; Read files in UTF-8 encoding by default to handle special characters.

progToast := new ProgressToast("Adding environment TLS lines for new SU version").blockingOn()

; Read file from database
progToast.nextStep("Reading file from database")
dataLines := FileLib.fileLinesToArray(Config.path["EPIC_NFS_ASK"] "\temp\environmentData.txt").removeEmpties() ; Drop any leading/trailing newlines
if(dataLines.length() = 0) {
	Toast.BlockAndShowError("Can't add new TLS lines", "No data in database file")
	ExitApp
}

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
; GDB TODO bits to handle for merge with SUs logic:
;  - Handle DBC vs normal environments separately. Ideas for how:
;     - Separate out DBC vs. normal environments with an extra newline or special-character line (maybe just a simple "-"), call above logic once per set
;     - Write two files, run this entire script twice (downside: needless double reformatting, having to launch it twice)
;  - Figure out how to deal with versionShortName stuff (used only to check whether version already exists - maybe we rely on a more generic "environment(s) already exist" check instead?)

; Add new lines to environments TLS
progToast.nextStep("Adding new TLS lines")
; insertTLSLines(environmentLines, newLines) ; GDB TODO for SUs merge
environmentLines.InsertAt(newLines, 1) ; Add to top of file

; Save updated TLS lines to file
progToast.nextStep("Writing to TLS file")
FileLib.replaceFileWithString(environmentsFilePath, environmentLines.join("`r`n"))

; Launch the TLS for editing
progToast.nextStep("Launching TLS file to edit")
Config.runProgram("VSCode", environmentsFilePath)

progToast.finish()
return

; Wait for me to move the new line to the proper place in the environments TLS and save, or to just close the file.
~^w::
~^s::
	if(GuiLib.showConfirmationPopup("Reformat environments TLS file?"))
		Run(Config.path["AHK_SOURCE"] "\standalone\reformatAllTLFiles.ahk " environmentsFilePath)
	ExitApp
return

; GDB TODO doc
handleDuplicateEnvironments(environmentLines, dataLines) {
	; Build an index of our new environments by commId
	newEnvironments := {}
	For _, line in dataLines {
		name   := line.piece(1, "|")
		commId := line.piece(3, "|")
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
; DESCRIPTION:    Pull the environment names and corresponding Thunder IDs from the "New for Export"
;                 environment folder, using the Launchy shortcuts.
; RETURNS:        Associative array: { environmentName: thunderId }
;---------
getThunderIDsFromShortcuts() {
	thunderIDs := {}

	; namePrefix := "New for Export " ; GDB TODO clean up
	shortcutsFolder := Config.path["USER_ROOT"] "\Thunder Shortcuts"
	Loop, Files, %shortcutsFolder%\%namePrefix%*.lnk
	{
		FileGetShortcut(A_LoopFilePath, "", "", thunderId) ; Argument is the thunder ID we need
		name := A_LoopFileName.removeFromStart(namePrefix).removeFromEnd("." A_LoopFileExt)
		thunderIDs[name] := thunderId
	}

	return thunderIDs
}

;---------
; DESCRIPTION:    Take the environment data from the database and use it go generate new environment TLS lines.
; PARAMETERS:
;  dataLines        (I,REQ) - Array of lines to process:
;                             	First line: 		versionNum|versionShortName
;                             	All other lines: 	commId|denId|envName|webURL
;  thunderIDs       (I,REQ) - Associate array of { environmentName: thunderId }
;  dbcLines         (O,REQ) - New TLS lines for DBC SU environments
;  normalLines      (O,REQ) - New TLS lines for normal (non-DBC) SU environments
;  versionShortName (O,REQ) - The "short name" for the version we're dealing with (i.e. Feb 22)
;---------
generateTLSLines(dataLines, thunderIDs, ByRef newLines) { ; GDB TODO remove
	newLines := []
	
	For i, line in dataLines
		newLines.push(buildTLSLine(line, versionNum, versionShortName, thunderIDs))

	return newLines
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

	data := dataLine.split("|")
	name       := data[1]
	abbrev     := data[2]
	commId     := data[3]
	denId      := data[4]
	vdiId      := data[5]
	versionNum := data[6]
	webURL     := data[7]

	; ; Display name is the version name + type of environment
	; if(commId.contains("DEV"))
	; 	typeName := "Dev"
	; else if(commId.contains("S1"))
	; 	typeName := "S1"
	; else if(commId.contains("S2"))
	; 	typeName := "Final"
	; name := versionShortName " " typeName
	
	; ; Abbreviation
	; isDBC := commId.contains("NL")
	; abbrev := buildAbbreviation(isDBC, typeName, shortMonth, shortYear, versionNum)

	; Thunder ID (mapped from full environment name)
	thunderId := mapNameToThunderID(thunderIDs, envName)
	; thunderId := thunderIDs[envName] ; GDB TODO handle folder names by looking for something that ENDS WITH the environment name

	; ; VDI ID
	; if(typeName = "Final") ; Final environments have "stage 2" IDs
	; 	vdiSuffix := "st2"
	; else
	; 	vdiSuffix := "st1" ; Dev and Stage 1 both use "stage 1" IDs
	; vdiId := StringLower(shortMonth) shortYear vdiSuffix

	return envName "`t" abbrev "`t" commId "`t" denId "`t" thunderId "`t" vdiId "`t" versionNum "`t" webURL
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
; DESCRIPTION:    Build the abbreviations string for the given info.
; PARAMETERS:
;  isDBC      (I,REQ) - true if this is a DBC environment, false otherwise.
;  typeName   (I,REQ) - The name of the "type" of environment, from "Dev"/"S1"/"Final"
;  shortMonth (I,REQ) - The short name of the version month (i.e. Feb)
;  shortYear  (I,REQ) - The two-character year of the version (i.e. 22)
;  versionNum (I,REQ) - The dotted version number (i.e. 10.4)
; RETURNS:        Abbreviation string (abbrev1 | abbrev2)
;---------
buildAbbreviation(isDBC, typeName, shortMonth, shortYear, versionNum) { ; GDB TODO move to database
	; Prefix is determined by the type of environment, goes on both abbreviations
	prefix := ""
	; "d" prefix for DBC environments
	if(isDBC)
		prefix .= "d"
	; "q"/"f" prefix for Stage 1/Final environments
	if(typeName = "S1")
		prefix .= "q"
	else if(typeName = "Final")
		prefix .= "f"
	
	; Date abbreviation is prefix + monthFirstLetter + year
	dateAbbrev := prefix StringLower(shortMonth.charAt(1)) shortYear

	; Version abbreviation is prefix + i + versionNumWithNoDot
	versionAbbrev := prefix "i" versionNum.remove(".")
	versionAbbrev := versionAbbrev.postPadToLength(6) ; Right-pad it so the pipes all line up

	return versionAbbrev " | " dateAbbrev
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
;---------
insertTLSLines(ByRef environmentLines, dbcLines, normalLines) { ; GDB TODO figure out SU merge
	headerIndex := environmentLines.contains("# ! DBC SUs")
	For i, line in dbcLines
		environmentLines.InsertAt(headerIndex + i, line)
	environmentLines.InsertAt(headerIndex + dbcLines.length() + 1, "") ; Empty newline to space out from previous version

	headerIndex := environmentLines.contains("# ! Normal SUs")
	For i, line in normalLines
		environmentLines.InsertAt(headerIndex + i, line)
	environmentLines.InsertAt(headerIndex + normalLines.length() + 1, "") ; Empty newline to space out from previous version
}
