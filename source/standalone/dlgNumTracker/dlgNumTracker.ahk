#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#Include <includeCommon>
scriptHotkeyType := HOTKEY_TYPE_SUB_MASTER

global suspended := 0
setUpTrayIconsSimple("suspended", "hash.ico", "redHash.ico")
SetTimer, MainLoop, 10000 ; 10s, timer toggled by commonHotkeys' suspend hotkey.

global currDLGId
SetTitleMatchMode, 2 ; Partial title matching.
emc2Title := " - EMC2 ahk_exe EpicD82.exe"


MainLoop:
	; Don't do anything if EMC2 isn't open.
	if(!WinExist(emc2Title))
		return
	
	getEMC2Info(ini, id, emc2Title)
	if(ini != "DLG")
		return
	
	currDLGId := id
	Menu, Tray, Tip, Press Ctrl + Alt + i to insert DLG number. `nCurrent DLG: %currDLGId%
return

^!i::
	Send, % currDLGId
return

#Include <commonHotkeys>
