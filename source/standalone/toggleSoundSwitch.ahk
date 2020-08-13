; Toggle SoundSwitch's input and output sources.
#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>

if(Config.isWindowActive("Remote Desktop")) {
	needReactivate := true
	origIdString := WindowLib.getIdTitleString("A")
	WinActivate, ahk_class Shell_TrayWnd ; Windows taskbar - unobtrusive to activate, but gets us out of remote desktop stealing all keys
}

Send, ^{F12}
Sleep, 500
Send, ^+{F12}

if(needReactivate)
	WinActivate, % origIdString

ExitApp
