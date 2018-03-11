#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#Include <includeCommon>
scriptHotkeyType := HOTKEY_TYPE_SUB_MASTER
setUpTrayIcons("turtle.ico", "turtleRed.ico")

SetTimer, MainLoop, 5000 ; 5s, timer toggled by commonHotkeys' suspend hotkey.
SetTitleMatchMode, RegEx


MainLoop:
	WinWaitActive, ^C:\\EpicSource\\\d\.\d\\DLG-(\w+)[-\\].* - Commit - TortoiseSVN
	ControlGetText, DLG, Edit2
	if(DLG = "") {
		WinGetActiveTitle, Title
		RegExMatch(Title, "^C:\\EpicSource\\\d\.\d\\DLG-(\w+)[-\\].* - Commit - TortoiseSVN", DLG)
		
		dlgFirstChar := SubStr(DLG1, 1, 1)
		if(isAlpha(dlgFirstChar)) {
			StringUpper, dlgFirstChar, dlgFirstChar
			ControlSend, Edit2, %dlgFirstChar%
			DLG1 := SubStr(DLG1, 2)
		}
		
		ControlSend, Edit2, %DLG1%
		Send, {Tab 2}
	}
return

#Include <commonHotkeys>
