#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
scriptTitle := "AHK: DLG Number Tracker"
ScriptTrayInfo.Init(scriptTitle, "hash.ico", "redHash.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Sub)

global currDLGId
SetTimer, MainLoop, 5000 ; 5s, timer toggled by commonHotkeys' suspend hotkey.
SetTitleMatchMode, % TitleMatchMode.Contains


MainLoop:
	; Don't do anything if EMC2 isn't open.
	if(!Config.doesWindowExist("EMC2"))
		return
	
	record := new EpicRecord().initFromEMC2Title()
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
