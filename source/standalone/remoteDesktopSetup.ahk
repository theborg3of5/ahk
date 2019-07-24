#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>

; Mute the remote computer (this one)'s volume.
startMuteState := VA_GetMasterMute()
VA_SetMasterMute(1)


; Restore settings and exit.
^+x::
	VA_SetMasterMute(startMuteState)
	ExitApp
return
