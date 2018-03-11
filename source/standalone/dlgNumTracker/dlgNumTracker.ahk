#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#Include <includeCommon>
scriptHotkeyType := HOTKEY_TYPE_SUB_MASTER
setUpTrayIcons("hash.ico", "redHash.ico")

global currDLGId
SetTimer, MainLoop, 10000 ; 10s, timer toggled by commonHotkeys' suspend hotkey.
SetTitleMatchMode, 2 ; Partial title matching.


MainLoop:
	; Don't do anything if EMC2 isn't open.
	if(!WinExist(" - EMC2 ahk_exe EpicD82.exe"))
		return
	
	getEMC2Info(ini, id, " - EMC2 ahk_exe EpicD82.exe")
	if(ini != "DLG")
		return
	
	currDLGId := id
	Menu, Tray, Tip, Press Ctrl + Alt + i to insert DLG number. `nCurrent DLG: %currDLGId%
return

^!i::
	Send, % currDLGId
return

#Include <commonHotkeys>
