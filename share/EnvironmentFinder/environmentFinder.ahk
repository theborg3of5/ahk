/*
Author: Gavin Borg

Description: 

Installation:
	Copy the containing folder (EnvironmentFinder) to your local machine and run this script.
	Configure the Includes/epic_environments.ini file with the environments that you want.
	
	If you would like it to persist through reboots, add a shortcut to your local copy of this script to your startup folder.

Shortcuts:
	Ctrl+F:
		When on an environment list window, show a popup to choose an environment to locate. Upon submission, it will try to find the environment chosen.
	
Notes:
	For Citrix/remote desktop situations, this will only pick the group you're asking for. This is due to restrictions on what AHK is able to access (it can't see the actual list of environments).
	
	When the popup appears, it will have several fields:
		First field - Choice. Fill it with the number or abbreviation of the choice that you want from the list, and you'll get the corresponding environment selected.
			
	The INI file is in a tab-separated format:
		Columns must be separated by one or more tabs. Extra tabs are ignored.
		All columns are not required, but because we ignore extra tabs, you must have some non-whitespace character in order to skip a column to keep columns aligned.
		Important columns are as follows (others are unused and may be removed):
			NAME      - Title shown for the given environment in the popup
			ABBREV    - Abbreviation shown for the environment
			ENV_GROUP - Full name of the environment group that the environment lives under.
			ENV_TITLE - Full name of the environemnt.
		
		You can separate blocks of environments with titles using rows that begin with the # character.
		There are other special characters available, see selector.ahk if you're curious.
*/


; --------------------------------------------------
; - Configuration ----------------------------------
; --------------------------------------------------
{
	; Icon to show in the system tray for this script.
	iconPath := "" ; Comment out to use the default AHK icon.
	; #NoTrayIcon  ; Uncomment to hide the tray icon instead.
	
	; File to read list of environments from.
	filePath := "epic_environments.ini"
	
	; Function to call when you submit a choice to the Selector popup.
	selectorFunction := "RET_DATA"
	
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
	title       := "Environment Finder"
	description := "When on the environment list window, uses the included INI file to generate a popup with a list of environments. When a user selects one of the choices, this script will try to find that environment. See script header for details."
	
	hotkeys     := []
	hotkeys.Push(["Launch environments popup ", "Ctrl + F"])
	hotkeys.Push(["Emergency exit",             "Ctrl + Shift + Alt + Win + R"])
	
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
	; Epic environment list window - title contains "Connection Status", and EXE is one of Snapper, Hyperspace (partial EXE name match), VB, or Citrix.
	#If isEpicEnvironmentListWindow()
		; Shows a list to the user, who can decide which environment they want to launch, then it will find and focus that one in the environment list window.
		^f::
			data := Selector.select(filePath, selectorFunction)
			pickEnvironment(data["ENV_TITLE"], data["ENV_GROUP"])
		return
	#If
}


; --------------------------------------------------
; - Supporting functions ---------------------------
; --------------------------------------------------
{
	isEpicEnvironmentListWindow() {
		; Title always contains "Connection Status".
		tempMatchMode := A_TitleMatchMode
		SetTitleMatchMode, 2 ; 2 means search anywhere within title
		if(!WinActive("Connection Status"))
			return false
		SetTitleMatchMode, % tempMatchMode
		
		; Executable matches one of the following
		if(exeActive("Snapper.exe")) ; Snapper
			return true
		if(exeActive("EpicD", true)) ; Any version of Hyperspace (second parameter is partial name matching)
			return true
		if(exeActive("VB6.EXE"))     ; VB6
			return true
		if(exeActive("WFICA32.exe")) ; Citrix
			return true
		if(exeActive("mstsc.exe"))   ; Remote desktop
		
		return false
	}
	
	; Within an Epic environment list window (title is usually "Connection Status"), pick the given environment by name (exact name match).
	; For remote (Citrix) windows, it won't select the specific environment, but will pick the given environment group and focus the environment list.
	pickEnvironment(envName, envGroup = "<All Environments>") {
		; Figure out if we're dealing with a local or remote (like Citrix) window.
		isLocal := !(exeActive("WFICA32.EXE") || exeActive("mstsc.exe")) ; Citrix, remote desktop
		
		; DEBUG.popup("epic", "pickEnvironment", "Environment name", envName, "Group", envGroup, "Current window is local", isLocal)

		; If you're local, make sure that the group listbox is focused.
		; Note that for Citrix, we have to assume the group listbox is focused (which it typically is by default).
		if(isLocal)
			ControlFocus, ThunderRT6ComboBox1, A
		
		SendRaw, %envGroup% ; Pick the given environment group (or <All Environments> by default)
		Send, {Tab}{Home}   ; Focus environment list and start at the top
		
		if(isLocal) {
			Loop, 5 { ; Try a few times in case it's a large environment list for the group.
				Sleep, 500
				
				; Get the list from the listbox.
				ControlGet, envList, List, , ThunderRT6ListBox1, A ; List doesn't support Selected option, so we'll have to figure it out ourselves.		
				if(envList)
					Break
			}
			; DEBUG.popup("Finished trying to get the environment list", envList)
			
			; Parse through list to find where our desired environment is.
			Loop, Parse, envList, `n ; Each line is an entry in the list.
			{
				if(A_LoopField = envName) {
					countFromTop := A_Index - 1
					Break
				}
			}
			; DEBUG.popup("Environment list raw", envList, "Looking for", envName, "Found at line-1", countFromTop)
			
			Send, {Down %countFromTop%} ; Down as many times as needed to hit the desired row.
		}
	}

	exeActive(exeName, partialMatch = false) {
		WinGet, currEXE, ProcessName, A
		if(partialMatch)
			return InStr(currExe, exeName)
		else
			return (currEXE = exeName)
	}
	
	; Return data array, for when we want more than just one value back.
	RET_DATA(actionRow) {
		if(actionRow.isDebug) ; Debug mode.
			actionRow.debugResult := actionRow.data
		
		return actionRow.data
	}
}


; --------------------------------------------------
; - Emergency exit ---------------------------------
; --------------------------------------------------
~^+!#r::ExitApp
