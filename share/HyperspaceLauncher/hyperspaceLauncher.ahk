/*
Author: Gavin Borg

Description: Uses the included INI file to generate a popup with a list of Hyperspace versions and environments. When a user selects one of the choices, this script will launch (local) Hyperspace with that version and connect to the given environment.

Installation:
	Copy the containing folder (HyperspaceLauncher) to your local machine and run this script.
	Configure the Includes/epic_hyperspace.ini file with the environments that you want.
	
	If you would like it to persist through reboots, add a shortcut to your local copy of this script to your startup folder.

Shortcuts:
	Ctrl+Shift+Alt+H:
		Launch a popup which asks what version and environment of Hyperspace you'd like to launch, then do so.
	
Notes:
	The INI file is in a tab-separated format:
		All columns are required, and columns must to be separated by one or more tabs. Extra tabs are ignored.
		Important columns are as follows (others are unused and may be removed):
			NAME    - Title shown for the given environment in the popup
			ABBREV  - Abbreviation shown for the environment
			COMM_ID - Identifier for the environment, can be found in EMC2. If not given, we'll just launch the given version with the usual environment selection popup.
			MAJOR   - Major version (example: 2015 is 8.2, so major version is 8)
			MINOR   - Minor version (example: 2015 is 8.2, so minor version is 2)
		You can separate blocks of environments with titles using rows that begin with the # character.
		There are other special characters available, see selector.ahk if you're curious.
*/


; --------------------------------------------------
; - Configuration ----------------------------------
; --------------------------------------------------
{
	; Icon to show in the system tray for this script.
	iconPath := "C:\Program Files (x86)\Epic\v8.3\Shared Files\EpicD83.exe" ; Comment out to use the default AHK icon.
	; #NoTrayIcon  ; Uncomment to hide the tray icon instead.
	
	; File to read list of Hyperspace environments from.
	filePath := "epic_environments.ini"
	
	; Function to call when you submit a choice to the Selector popup.
	selectorFunction := "DO_HYPERSPACE"
	
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
	global epicExeBase   := "C:\Program Files (x86)\<EPICNAME>\v<MAJOR>.<MINOR>\Shared Files\EpicD<MAJOR><MINOR>.exe EDAppServers<MAJOR><MINOR>.EpicApp Env=<ENVIRONMENT>"
	
	; Tray setup for double-click help popup, icon, etc.
	title       := "HyperspaceLauncher"
	description := "A generic popup that allows users to choose a version/environment of Hyperspace, then launches it. See script header for details."
	
	hotkeys     := []
	hotkeys.Push(["Launch Hyperspace", "Ctrl + Shift + Alt + H"])
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
	^+!h::
		Selector.select(filePath, selectorFunction)
	return
}


; --------------------------------------------------
; - Supporting functions ---------------------------
; --------------------------------------------------
{
	; Run Hyperspace.
	DO_HYPERSPACE(actionRow) {
		versionMajor := actionRow.data["MAJOR"]
		versionMinor := actionRow.data["MINOR"]
		environment  := actionRow.data["COMM_ID"]
		
		; Build run path.
		runString := buildHyperspaceRunString(versionMajor, versionMinor, environment)
		
		; Do it.
		if(actionRow.isDebug) ; Debug mode.
			actionRow.debugResult := runString
		else
			MsgBox, % runString
			; Run, % runString
	}
	
	buildHyperspaceRunString(versionMajor, versionMinor, environment) {
		global epicExeBase
		runString := epicExeBase
		
		; Handling for 2010 special path.
		if(versionMajor = 7 && versionMinor = 8)
			runString := RegExReplace(runString, "<EPICNAME>", "EpicSys")
		else
			runString := RegExReplace(runString, "<EPICNAME>", "Epic")
		
		; Versioning and environment.
		runString := RegExReplace(runString, "<MAJOR>", versionMajor)
		runString := RegExReplace(runString, "<MINOR>", versionMinor)
		runString := RegExReplace(runString, "<ENVIRONMENT>", environment)
		
		return runString
	}
}


; --------------------------------------------------
; - Emergency exit ---------------------------------
; --------------------------------------------------
~^+!#r::ExitApp
