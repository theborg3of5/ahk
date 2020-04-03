; Send a command directly to Spotify on this machine (not using media commands because those can be caught by remote desktop).
#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#NoTrayIcon
DetectHiddenWindows, On

#Include <includeCommon>

command = %1% ; Input from command line
if(!command)
	ExitApp

; Send the command
if(command = "PLAY_PAUSE")
	Spotify.playPause()
else if(command = "PREVIOUS_TRACK")
	Spotify.previousTrack()
else if(command = "NEXT_TRACK")
	Spotify.nextTrack()

ExitApp

#Include ..\program\spotify.ahk ; At end because otherwise its hotkeys prevent the above execution
