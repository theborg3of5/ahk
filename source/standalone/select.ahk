; Script used to call a standalone instance of the selector.

#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <autoInclude>

; We'll put the first command line argument in filePath, the second in actionType, etc.
scriptArgsToVars(["filePath", "actionType", "silentChoice", "iconName"], "-") ; If a value is "-", we'll set that variable to blank.
; DEBUG.popup("Filepath", filePath, "Action type", actionType, "Silent choice", silentChoice, "Icon name", iconName)

Selector.select(filePath, actionType, silentChoice, iconName)

ExitApp

; Universal suspend, reload, and exit hotkeys.
#Include %A_ScriptDir%\..\common\commonHotkeys.ahk
