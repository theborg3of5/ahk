; Dump a bunch of info about the active window into Notepad.
#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>

; Give the target window a chance to regain focus (it presumably lost it when we launched the script).
Sleep, 500

info := []
info.push("ID",                 WinGet("ID", "A"))
info.push("Name",               Config.findWindowInfo("A").name)
info.push("EXE",                WinGet("ProcessName", "A"))
info.push("Class",              WinGetClass("A"))
info.push("Title",              WinGetTitle("A"))
info.push("Tooltip Text",       WindowLib.getTooltipText())
info.push("Current Control ID", ControlGetFocus("A"))
info.push("VisualWindow",       new VisualWindow("A"))

Debug.notepad(info*)

ExitApp
