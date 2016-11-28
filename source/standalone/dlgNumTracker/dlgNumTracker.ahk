#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <autoInclude>

; State flags.
global suspended := 0

; Icon setup.
states                 := []
states["suspended", 0] := "hash.ico"
states["suspended", 1] := "redHash.ico"
setupTrayIcons(states)

loopDuration := 10 * 1000 ; 60 * 1000
SetTimer, MainLoop, %loopDuration% ; Timer for "MainLoop" will be toggled by commonHotkeys' suspend hotkey.

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

; Universal suspend, reload, and exit hotkeys.
#Include %A_ScriptDir%\..\..\common\commonHotkeys.ahk