; Send a specific media key, to be executed by external program (like Microsoft keyboard special keys).
#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

; Run in Outlook only.
if(!WinActive("ahk_class rctrl_renwnd32"))
	ExitApp

quickStepNumber = %1% ; Input from command line
if(!quickStepNumber)
	ExitApp
	
Send, ^+%quickStepNumber%
