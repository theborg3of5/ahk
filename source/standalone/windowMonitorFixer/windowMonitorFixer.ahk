; Move windows back to their correct monitors after all are moved to main monitor (generally after remote desktopping or the like)

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, force
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include <autoInclude>
isSingleUserScript := true

winListFilePath := MainConfig.getSetting("MACHINE") "_WINDOWS.ini"

; Get the list of monitors and their dimensions.
monitorList := getMonitorInfo()
; DEBUG.popup("Monitor list", monitorList)

; Parse out the list of windows and what monitors they should be on.
windowList := TableList.parseFile(winListFilePath)
; DEBUG.popup("Windows filepath", winListFilePath, "Parsed List", windowList)

; Move the windows to those respective monitors.
For i,windowRow in windowList {
	destMonitor := windowRow["MONITOR"]
	winIdentifier := windowRow["ID"]
	
	; DEBUG.popup("WindowMonitorFixer", "Looking for window", "Name", windowRow["NAME"], "ID", winIdentifier, "Monitor", destMonitor)
	WinGet, MatchedWinList, List, %winIdentifier%
	if(!MatchedWinList)  ; Window doesn't exit, so bail.
		Continue
	
	; DEBUG.popup("WindowMonitorFixer", "Looking for windows that match", "Identifier", winIdentifier, "Name", windowRow["NAME"])
	winList := convertPseudoArrayToObject("MatchedWinList") ; Get a real object from the pseudoarray.
	For j,winHandle in winList {
		winID := "ahk_id " winHandle
		moveWindowToMonitor(winID, destMonitor, monitorList)
	}
}

ExitApp

; Universal suspend, reload, and exit hotkeys.
#Include %A_ScriptDir%\..\..\common\commonHotkeys.ahk
