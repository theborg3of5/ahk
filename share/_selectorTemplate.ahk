/*
Author: Gavin Borg

Description: 

Installation:
	Copy the containing folder (***) to your local machine and run this script.
	Configure the Includes/***.ini file with the *** that you want.
	
	If you would like it to persist through reboots, add a shortcut to your local copy of this script to your startup folder.

Shortcuts:
	
	
Notes:
	When the popup appears, it will have several fields:
		First field   - Choice. Fill it with the number or abbreviation of the choice that you want from the list, and you'll get the corresponding ***.
		*** - If filled out with something other than their label (***), that portion of the string will use what you enter (rather than what's in the INI file for that column).
			This allows you to make choices that work on both general and specific levels.
			
	The INI file is in a tab-separated format:
		Columns must be separated by one or more tabs. Extra tabs are ignored.
		All columns are not required, but because we ignore extra tabs, you must have some non-whitespace character in order to skip a column to keep columns aligned.
		Columns are as follows:
			NAME   - Title shown for the given environment in the popup
			ABBREV - Abbreviation shown for the environment
			*** - 
		
		You can separate blocks of environments with titles using rows that begin with the # character.
		There are other special characters available, see selector.ahk if you're curious.
*/


; --------------------------------------------------
; - Configuration ----------------------------------
; --------------------------------------------------
{
	; Icon to show in the system tray for this script.
	iconPath := "***" ; Comment out to use the default AHK icon.
	; #NoTrayIcon  ; Uncomment to hide the tray icon instead.
	
	; File to read list of *** from.
	filePath := "***"
	
	; Function to call when you submit a choice to the Selector popup.
	selectorFunction := "***"
	
	; By default, this script will wait in the background and activate with a hotkey, sticking around for multiple uses.
	; Uncomment the next line to launch Hyperspace immediately when the script is launched, then quit.
	; mode := "RUN_ONCE"
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
		#Include selectorRow.ahk
		#Include string.ahk
		#Include tableList.ahk
		#Include tableListMod.ahk
		#Include debug.ahk        ; For debug mode (i.e., using "+d val" in the input field, see selectorActions.ahk for details)
	
	; Constants
	
	; Tray setup for double-click help popup, icon, etc.
	title       := "***"
	description := "Uses the included INI file to generate a popup with a list of ***. When a user selects one of the choices, this script will ***. See script header for details."
	
	hotkeys     := []
	hotkeys.Push(["Launch *** popup ", "Ctrl + Shift + Alt + T"])
	hotkeys.Push(["Emergency exit",    "Ctrl + Shift + Alt + Win + R"])
	
	setupTray(title, description, hotkeys, iconPath)
	scriptLoaded := true
}


; --------------------------------------------------
; - Main -------------------------------------------
; --------------------------------------------------
{
	if(mode = "RUN_ONCE") { ; Run once and exit.
		Selector.select(filePath, selectorFunction)
		ExitApp
	}
	
	; Hotkey if we want to have the script wait in the background, activate by hotkey, and stick around for multiple uses.
	^+!t::
		Selector.select(filePath, selectorFunction)
	return
}


; --------------------------------------------------
; - Supporting functions ---------------------------
; --------------------------------------------------
{
	; ***
}


; --------------------------------------------------
; - Emergency exit ---------------------------------
; --------------------------------------------------
~^+!#r::ExitApp
