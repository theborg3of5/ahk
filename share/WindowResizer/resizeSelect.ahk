/*
Author: Gavin Borg

Description: Launches a popup that allows the user to resize the window to one of any number of preset sizes.

Installation:
	Copy the containing folder (ResizeSelector) to your local machine and run this script.
	If you would like it to persist through reboots, add a shortcut to your local copy of this script to your startup folder.

Shortcuts:
	Alt+Win+S:
		Launch the popup to choose what size you want to resize the active window to.

Notes:
	You can add/remove preset sizes to the popup by editing resize.ini in this folder.
*/


; --------------------------------------------------
; - Configuration ----------------------------------
; --------------------------------------------------
{
	iniPath := "resize.ini" ; File where the list of preset window sizes comes from. Feel free to add your own to that file!
	
	; Icon to show in the system tray for this script.
	iconPath := "resize.ico" ; Comment out to use the default AHK icon.
	; #NoTrayIcon  ; Uncomment to hide the tray icon instead.
}


; --------------------------------------------------
; - Setup, Includes, Constants ---------------------
; --------------------------------------------------
{
	#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
	#SingleInstance Force        ; Running this script while it's already running just replaces the existing instance.
	SendMode Input               ; Recommended for new scripts due to its superior speed and reliability.
	SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
	
	#Include Includes/
		#Include _trayHelper.ahk
		
		; For Selector use
		#Include data.ahk
		#Include io.ahk
		#Include selector.ahk
		#Include selectorChoice.ahk
		#Include string.ahk
		#Include tableList.ahk
		#Include tableListMod.ahk
	
	; Tray setup for double-click help popup, icon, etc.
	title       := "Resize Selector"
	description := "Launches a popup that allows the user to resize the window to one of any number of preset sizes."
	hotkeys     := []
	hotkeys.Push(["Launch resizing popup", "Alt + Win + S"])
	hotkeys.Push(["Emergency exit", "Ctrl + Shift + Alt + Win + R"])
	
	setupTray(title, description, hotkeys, iconPath)
	scriptLoaded := true
}


; --------------------------------------------------
; - Main -------------------------------------------
; --------------------------------------------------
#!s::
	Selector.select(iniPath, "RESIZE")
return

; Resizes the active window to the given dimensions.
RESIZE(actionRow) {
	width  := actionRow.data["WIDTH"]
	height := actionRow.data["HEIGHT"]
	WinMove, A, , , , width, height
}

; --------------------------------------------------
; - Emergency exit ---------------------------------
; --------------------------------------------------
~^+!#r::ExitApp