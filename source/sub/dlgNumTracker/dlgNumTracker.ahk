#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
trayInfo := new ScriptTrayInfo("AHK: DLG Number Tracker", "hash.ico", "redHash.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_SubMaster, trayInfo)

global currDLGId
SetTimer, MainLoop, 5000 ; 5s, timer toggled by commonHotkeys' suspend hotkey.
SetTitleMatchMode, 2 ; Partial title matching.


MainLoop:
	; Don't do anything if EMC2 isn't open.
	if(!MainConfig.doesWindowExist("EMC2"))
		return
	
	record := new EpicRecord()
	record.initFromEMC2Title()
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
