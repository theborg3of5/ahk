﻿#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
DetectHiddenWindows, On

#Include <includeCommon>
ScriptTrayInfo.Init("AHK: Notes helper")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)

#If Config.isWindowActive("OneNote")

; Hotstrings for various people/directions
:CB0*X?:mL::superscriptSides()
:CB0*X?:mR::superscriptSides()
:CB0*X?:mBL::superscriptSides()
:CB0*X?:mBR::superscriptSides()
:CB0*X?:mFL::superscriptSides()
:CB0*X?:mFR::superscriptSides()
:CB0*X?:mI::superscriptSides()
:CB0*X?:mO::superscriptSides()
:CB0*X?:mBI::superscriptSides()
:CB0*X?:mBO::superscriptSides()
:CB0*X?:mFI::superscriptSides()
:CB0*X?:mFO::superscriptSides()

:CB0*X?:uL::superscriptSides()
:CB0*X?:uR::superscriptSides()
:CB0*X?:uBL::superscriptSides()
:CB0*X?:uBR::superscriptSides()
:CB0*X?:uFL::superscriptSides()
:CB0*X?:uFR::superscriptSides()
:CB0*X?:uI::superscriptSides()
:CB0*X?:uO::superscriptSides()
:CB0*X?:uBI::superscriptSides()
:CB0*X?:uBO::superscriptSides()
:CB0*X?:uFI::superscriptSides()
:CB0*X?:uFO::superscriptSides()

:CB0*X?:bL::superscriptSides()
:CB0*X?:bR::superscriptSides()
:CB0*X?:bFL::superscriptSides()
:CB0*X?:bFR::superscriptSides()
:CB0*X?:bBL::superscriptSides()
:CB0*X?:bBR::superscriptSides()
:CB0*X?:bO::superscriptSides()
:CB0*X?:bO::superscriptSides()
:CB0*X?:bFO::superscriptSides()
:CB0*X?:bFO::superscriptSides()
:CB0*X?:bBO::superscriptSides()
:CB0*X?:bBO::superscriptSides()

#If


superscriptSides() {
	hotstring := A_ThisHotkey.afterString(":", true)
	length := hotstring.length()

	Send, {Shift Down}{Left %length%}{Shift Up} ; Select text
	Send, ^+= ; Superscript
	Send, {Right} ; Deselect, cursor back where it started
	Send, ^+= ; Remove superscript
}
