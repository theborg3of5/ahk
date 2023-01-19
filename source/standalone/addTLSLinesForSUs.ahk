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
For i, line in tlsLines {
	; GDB TODO probably switch to just delimited data from database in file, handle all formatting/processing here instead
	
	lineBits := line.split("<TAB>")

	; 1 is empty right now (we start with the delimiter)
	name := lineBits[2]
	abbrev := lineBits[3]
	commId := lineBits[4]
	denId := lineBits[5]
	; 6 is ***** for thunder ID right now
	vdiId := lineBits[7]
	versionNum := lineBits[8]
	webURL := lineBits[9]
	envName := lineBits[10]

	; GDB TODO add warning/error when there's no match (ideally showing both input and options we failed to match to)
	line := line.replace("*****", thunderIDs[envName]) ; Replace thunder ID placeholder by matching on environment name
	line := line.beforeString("<TAB>", true) ; Drop environment name (only needed to find thunder ID)
	line := line.replace("<TAB>", "`t") ; Plug in actual tabs

	if(envName.startsWith("NETHERLANDS")) ; GDB TODO turn this into a flag somewhere, check the same thing as we use to build abbreviation (that uses commId containing "NL" right now)
		dbcLines.push(line)
	else
		normalLines.push(line)
}
Debug.popup("tlsLines",tlsLines, "thunderIDs",thunderIDs, "dbcLines",dbcLines, "normalLines",normalLines)

progToast.nextStep("Adding lines to environments TLS")
environmentsFilePath := FileLib.findConfigFilePath("epicEnvironments.tls")
environmentLines := FileLib.fileLinesToArray(environmentsFilePath)

; GDB TODO enhancement idea: check if the next (non-empty) line under each header matches (by name, first after indentation) what we're going to add, prompt user about replacing if so.

dbcHeaderIndex := environmentLines.contains("# ! DBC SUs")
For i, line in dbcLines
	environmentLines.InsertAt(dbcHeaderIndex + i, line)
environmentLines.InsertAt(dbcHeaderIndex + dbcLines.length() + 1, "") ; Empty newline

normalHeaderIndex := environmentLines.contains("# ! Normal SUs")
For i, line in normalLines
	environmentLines.InsertAt(normalHeaderIndex + i, line)
environmentLines.InsertAt(normalHeaderIndex + normalLines.length() + 1, "") ; Empty newline
Debug.popup("environmentLines",environmentLines)

; GDB TODO might need to explicitly use `r`n instead of just `n when writing back to the file
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
	; Debug.popup("thunderIDs",thunderIDs)

	return thunderIDs
}