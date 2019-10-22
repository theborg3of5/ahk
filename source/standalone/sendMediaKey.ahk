; Send a specific media key, to be executed by external program (like Microsoft keyboard special keys).
#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#NoTrayIcon

#Include <includeCommon>

inputKeys = %1% ; Input from command line
if(!inputKeys)
	ExitApp

For _,key in inputKeys.split(",")
	Send, {%key%}

ExitApp
