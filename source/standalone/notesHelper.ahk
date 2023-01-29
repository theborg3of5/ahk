#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
DetectHiddenWindows, On

#Include <includeCommon>
ScriptTrayInfo.Init("AHK: Notes helper")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)

#If Config.isWindowActive("OneNote")

:CB0*X?:mL::superscriptSides()
:CB0*X?:mR::superscriptSides()
:CB0*X?:uL::superscriptSides()
:CB0*X?:uR::superscriptSides()

#If


superscriptSides() {
	Send, {Shift Down}{Left 2}{Shift Up} ; Select text
	Send, ^+= ; Superscript
	Send, {Right} ; Deselect, cursor back where it started
	Send, ^+= ; Remove superscript
}
