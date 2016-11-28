; == Script setup. == ;

#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
DetectHiddenWindows, On
; #NoTrayIcon
; #Warn All

; State flags.
global suspended := 0

; Icon setup.
states                 := []
states["suspended", 0] := "shellGreen.ico"
states["suspended", 1] := "shellRed.ico"
setupTrayIcons(states)

; For common hotkeys.
isBorgMasterScript := 1