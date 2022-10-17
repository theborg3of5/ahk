; Launch the bunch of programs I typically need open, for use after I restart the computer.
#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>

Config.runProgram("Explorer", Explorer.ThisPCFolderUUID)
Config.runProgram("OneNote")
if(Config.contextIsWork) {
	Config.runProgram("Outlook")
	Config.runProgram("EMC2", "EMC2Update env=TRACKAPPTCP")
	Config.runProgram("EpicStudio")
	Config.runProgram("Thunder")
}

ExitApp
