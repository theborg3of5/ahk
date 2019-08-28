#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
trayInfo := new ScriptTrayInfo("AHK: Color Picker", "color.ico", "colorRed.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone, trayInfo)

