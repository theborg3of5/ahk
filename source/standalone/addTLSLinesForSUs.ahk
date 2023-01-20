; Generate and add lines for a new SU version to the environments TLS file.

#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
FileEncoding, UTF-8          ; Read files in UTF-8 encoding by default to handle special characters.

#Include <includeCommon>

progToast := new ProgressToast("Adding environment TLS lines for new SU version").blockingOn()

; Read file from database
progToast.nextStep("Reading file from database")
suDataLines := FileLib.fileLinesToArray(Config.path["EPIC_NFS_ASK"] "\temp\suEnvironmentData.txt").removeEmpties() ; Drop leading newline
if(suDataLines.length() = 0) {
	Toast.BlockAndShowError("Can't add new TLS lines", "No data in database file")
	ExitApp
}

; Read Thunder IDs from shortcuts
progToast.nextStep("Reading Thunder IDs from shortcuts folder")
thunderIDs := getThunderIDsFromShortcuts()

; Generate new TLS lines to insert
progToast.nextStep("Generating new TLS lines")
generateTLSLines(suDataLines, thunderIDs, dbcLines, normalLines, versionShortName)

; Read in existing TLS
progToast.nextStep("Reading in existing environments")
environmentsFilePath := FileLib.findConfigFilePath("epicEnvironments.tls")
environmentLines := FileLib.fileLinesToArray(environmentsFilePath)
if(!checkIfAlreadyAdded(environmentLines, versionShortName))
	ExitApp

; Add new lines to environments TLS
progToast.nextStep("Inserting new TLS lines")
insertTLSLines(environmentLines, dbcLines, normalLines)

; Save result to file
progToast.nextStep("Writing to TLS file")
FileLib.replaceFileWithString(environmentsFilePath, environmentLines.join("`r`n"))

; Reformat epicEnvironments TLS ; GDB TODO add option to reformat a specific file (as a command line argument probably?) instead of everything, without a prompt
progToast.nextStep("Reformatting TLS file")
Run("C:\Users\gborg\ahk\source\standalone\reformatAllTLFiles.ahk " environmentsFilePath)

progToast.finish()
ExitApp




getThunderIDsFromShortcuts() {
	thunderIDs := {}

	namePrefix := "New for Export "
	shortcutsFolder := Config.path["USER_ROOT"] "\Thunder Shortcuts"
	Loop, Files, %shortcutsFolder%\%namePrefix%*.lnk
	{
		FileGetShortcut(A_LoopFilePath, "", "", thunderId)
		name := A_LoopFileName.removeFromStart(namePrefix).removeFromEnd("." A_LoopFileExt)
		thunderIDs[name] := thunderId
	}

	return thunderIDs
}


generateTLSLines(suDataLines, thunderIDs, ByRef dbcLines, ByRef normalLines, ByRef versionShortName) {
	dbcLines         := []
	normalLines      := []
	versionShortName := ""
	
	; First line is the version number + short name, for use across all TLS lines.
	firstLine := suDataLines[1]
	versionNum       := firstLine.beforeString("|")
	versionShortName := firstLine.afterString("|")
	suDataLines.removeAt(1)

	For i, line in suDataLines {
		line := buildTLSLine(line, versionNum, versionShortName, thunderIDs, isDBC)
		if(isDBC)
			dbcLines.push(line)
		else
			normalLines.push(line)
	}
}


buildTLSLine(dataLine, versionNum, versionShortName, thunderIDs, ByRef isDBC) {
	shortMonth := versionShortName.beforeString(" ")
	shortYear  := versionShortName.afterString(" ")

	data := dataLine.split("|")
	commId  := data[1]
	denId   := data[2]
	envName := data[3]
	webURL  := data[4]

	isDBC := commId.contains("NL")

	; Display name is the version name + type of environment
	if(commId.contains("DEV"))
		typeName := "Dev"
	else if(commId.contains("S1"))
		typeName := "S1"
	else if(commId.contains("S2"))
		typeName := "Final"
	name := versionShortName " " typeName

	; Abbreviation
	abbrev := buildAbbreviation(isDBC, typeName, shortMonth, shortYear, versionNum)

	; Thunder ID (mapped from full environment name)
	thunderId := thunderIDs[envName]

	; VDI ID
	if(typeName = "Final") ; Final environments have "stage 2" IDs
		vdiSuffix := "st2"
	else
		vdiSuffix := "st1" ; Dev and Stage 1 both use "stage 1" IDs
	vdiId := StringLower(shortMonth) shortYear vdiSuffix

	return name "`t" abbrev "`t" commId "`t" denId "`t" thunderId "`t" vdiId "`t" versionNum "`t" webURL
}

buildAbbreviation(isDBC, typeName, shortMonth, shortYear, versionNum) {
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


checkIfAlreadyAdded(environmentLines, versionShortName) {
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


insertTLSLines(ByRef environmentLines, dbcLines, normalLines) {
	headerIndex := environmentLines.contains("# ! DBC SUs")
	For i, line in dbcLines
		environmentLines.InsertAt(headerIndex + i, line)
	environmentLines.InsertAt(headerIndex + dbcLines.length() + 1, "") ; Empty newline to space out from previous version

	headerIndex := environmentLines.contains("# ! Normal SUs")
	For i, line in normalLines
		environmentLines.InsertAt(headerIndex + i, line)
	environmentLines.InsertAt(headerIndex + normalLines.length() + 1, "") ; Empty newline to space out from previous version
}