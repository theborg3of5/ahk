; == Script setup. == ;

#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
DetectHiddenWindows, On
; #NoTrayIcon
; #Warn All

; State flag and icons
global suspended := 0
setUpTrayIconsSimple("suspended", "shellGreen.ico", "shellRed.ico")

; For common hotkeys.
isMainMasterScript := 1