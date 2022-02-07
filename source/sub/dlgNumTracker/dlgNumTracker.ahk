#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
scriptTitle := "AHK: DLG Number Tracker"
ScriptTrayInfo.Init(scriptTitle, "hash.ico", "redHash.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Sub)
CommonHotkeys.setSuspendTimerLabel("UpdateID")

global currDLGId
SetTimer, UpdateID, 5000 ; 5s
SetTitleMatchMode, % TitleMatchMode.Contains


UpdateID:
	; Don't do anything if EMC2 isn't open.
	if(!Config.doesWindowExist("EMC2"))
		return
	
	record := new EMC2Record().initFromEMC2Title()
	if(record.ini != "DLG")
		return
	currDLGId := record.id
	
	trayMessage := "
		( LTrim
			" scriptTitle "
			Press Ctrl + Alt + i to insert DLG number.
			Current DLG: " currDLGId "
		)"
	Menu, Tray, Tip, % trayMessage
return

^!i::
	Send, % currDLGId
return
