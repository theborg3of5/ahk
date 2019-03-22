#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#Include <includeCommon>
setCommonHotkeysType(HOTKEY_TYPE_SubMaster)
scriptTitle := "AHK: DLG Number Tracker"
setUpTrayIcons("hash.ico", "redHash.ico", scriptTitle)

global currDLGId
SetTimer, MainLoop, 10000 ; 10s, timer toggled by commonHotkeys' suspend hotkey.
SetTitleMatchMode, 2 ; Partial title matching.


MainLoop:
	; Don't do anything if EMC2 isn't open.
	if(!MainConfig.doesWindowExist("EMC2"))
		return
	
	getEMC2Info(ini, id, MainConfig.windowInfo["EMC2"].titleString)
	if(ini != "DLG")
		return
	
	currDLGId := id
	trayMessage := "
	(LTrim
		" scriptTitle "
		Press Ctrl + Alt + i to insert DLG number.
		Current DLG: " currDLGId "
	)"
	Menu, Tray, Tip, % trayMessage
return

^!i::
	Send, % currDLGId
return

#Include <commonHotkeys>
