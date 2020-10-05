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

if(command != "SHOW_INFO" && !Config.doesWindowExist("Spotify")) { ; Don't launch Spotify just to show the info display
	Config.runProgram("Spotify")
	new Toast("Spotify not yet running, launching...").blockingOn().showMedium()
	ExitApp
}

; Send the command
Switch command {
	Case "PLAY_PAUSE":     Spotify.playPause()
	Case "PREVIOUS_TRACK": Spotify.previousTrack()
	Case "NEXT_TRACK":     Spotify.nextTrack()
	Case "SHOW_INFO":      Spotify.showCurrentInfo()
}

ExitApp

#Include ..\program\spotify.ahk ; At end because otherwise its hotkeys prevent the above execution - we just need the Spotify class.
