#SingleInstance Force        ; Running this script while it's already running just replaces the existing instance.
SetWorkingDir(A_ScriptDir)   ; Ensures a consistent starting directory.

Send("{LWin Up}{RWin Up}{LCtrl Up}{RCtrl Up}{LAlt Up}{RAlt Up}{LShift Up}{RShift Up}")
ExitApp
