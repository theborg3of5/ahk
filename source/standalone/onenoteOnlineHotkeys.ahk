#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
DetectHiddenWindows, On

#Include <includeCommon>
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)

^+=::
	Click, 379, 261
	Click, 404, 328
return

^=::
	Click, 379, 261
	Click, 411, 298 
return