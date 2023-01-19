; Generate and add lines for a new SU version to the environments TLS file.

#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
FileEncoding, UTF-8          ; Read files in UTF-8 encoding by default to handle special characters.

#Include <includeCommon>

; if(!GuiLib.showConfirmationPopup("Reformat all TL/TLS files?"))
; 	ExitApp

progToast := new ProgressToast("Adding environment TLS lines for new SU version").blockingOn()

progToast.nextStep("Reading file from database")
tlsLines := FileLib.fileLinesToArray(Config.path["EPIC_NFS_ASK"] "\temp\tlsLinesForSUs.txt").removeEmpties() ; Drop leading newline

progToast.nextStep("Reading Thunder IDs from shortcuts folder")
thunderIDs := getThunderIDsFromShortcuts()

progToast.nextStep("Generating TLS lines")
dbcLines := []
normalLines := []
versionShortName := ""
For i, line in tlsLines {
	; First line is the version "short name" (that will prefix most names)
	if(i = 1) {
		versionNum       := line.beforeString("|")
		versionShortName := line.afterString("|")
		Continue
	}
	
	line := buildTLSLine(line, versionNum, versionShortName, thunderIDs, isDBC)
	if(isDBC)
		dbcLines.push(line)
	else
		normalLines.push(line)
}
Debug.popup("tlsLines",tlsLines, "thunderIDs",thunderIDs, "dbcLines",dbcLines, "normalLines",normalLines)

; GDB TODO enhancement idea: check if the next (non-empty) line under each header matches (by name, first after indentation) what we're going to add, prompt user about replacing if so.
progToast.nextStep("Adding lines to environments TLS")
environmentsFilePath := FileLib.findConfigFilePath("epicEnvironments.tls")
environmentLines := FileLib.fileLinesToArray(environmentsFilePath)

dbcHeaderIndex := environmentLines.contains("# ! DBC SUs")
For i, line in dbcLines
	environmentLines.InsertAt(dbcHeaderIndex + i, line)
environmentLines.InsertAt(dbcHeaderIndex + dbcLines.length() + 1, "") ; Empty newline

normalHeaderIndex := environmentLines.contains("# ! Normal SUs")
For i, line in normalLines
	environmentLines.InsertAt(normalHeaderIndex + i, line)
environmentLines.InsertAt(normalHeaderIndex + normalLines.length() + 1, "") ; Empty newline
Debug.popup("environmentLines",environmentLines)

FileLib.replaceFileWithString(environmentsFilePath, environmentLines.join("`r`n"))

; Reformat epicEnvironments TLS ; GDB TODO add option to reformat a specific file (as a command line argument probably?) instead of everything, without a prompt
progToast.nextStep("Reformatting TLS file")
Run("C:\Users\gborg\ahk\source\standalone\reformatAllTLFiles.ahk")

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

