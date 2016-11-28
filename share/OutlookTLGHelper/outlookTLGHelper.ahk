/*
Author: Gavin Borg

Description: Uses the included INI file to generate a popup with a list of TLP codes and descriptions. When a user selects one of the choices, this script will send the generated TLG string (which should be the title of a given Outlook event on your TLG calendar).

Installation:
	Copy the containing folder (OutlookTLGHelper) to your local machine and run this script.
	Configure the Includes/epic_outlookTLG.ini file with the TLP codes and descriptions that you want.
	
	If you would like it to persist through reboots, add a shortcut to your local copy of this script to your startup folder.

Shortcuts:
	Ctrl+Shift+Alt+T:
		Highlight the block on your TLG Outlook calendar that you'd like to add an event to, then trigger this hotkey.
		A popup will appear which asks the user for which TLP/description that they want to add, then sends it and presses Enter (to save event).
	
Notes:
	When the popup appears, it will have several fields:
		First field   - Choice. Fill it with the number or abbreviation of the choice that you want from the list, and you'll get the corresponding TLP string for Outlook.
		MSG, DLG, TLP - If filled out with something other than their label ("MSG"/"DLG"/"TLP"), that portion of the string will use what you enter (rather than what's in the INI file for that column).
			This allows you to make choices that work on both general and specific levels.
			For example, take the "Immersion" row in Includes/epic_outlookTLG.ini:
				If you just give "im" in the first field, you'll get:
					20239, Immersion Trip
				But if you were to fill in "im" in the first field and "St Mikal's Home for the Diseased Immersion" in the MSG field, you'll get:
					20239, St Mikal's Home for the Diseased Immersion
	
	The INI file is in a tab-separated format:
		Columns must be separated by one or more tabs. Extra tabs are ignored.
		All columns are not required, but because we ignore extra tabs, you must have some non-whitespace character in order to skip a column to keep columns aligned.
		Columns are as follows:
			NAME   - Title shown for the given environment in the popup
			ABBREV - Abbreviation shown for the environment
			TLP    - TLP code
			MSG    - Free-text comment to go with entry
			DLG    - DLG (generally for dev or PQA)
		
		You can separate blocks of environments with titles using rows that begin with the # character.
		There are other special characters available, see selector.ahk if you're curious.
*/


; --------------------------------------------------
; - Configuration ----------------------------------
; --------------------------------------------------
{
	; Icon to show in the system tray for this script.
	iconPath := "epic_outlookTLG.ico" ; Comment out to use the default AHK icon.
	; #NoTrayIcon  ; Uncomment to hide the tray icon instead.
	
	; File to read list of TLP codes from.
	filePath := "epic_outlookTLG.ini"
	
	; Function to call when you submit a choice to the Selector popup.
	selectorFunction := "OUTLOOK_TLG"
	
	; By default, this script will wait in the background and activate with a hotkey, sticking around for multiple uses.
	; Uncomment the next line to launch helper immediately when the script is launched, then quit.
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
	title       := "OutlookTLGHelper"
	description := "Uses the included INI file to generate a popup with a list of TLP codes and descriptions. When a user selects one of the choices, this script will send the generated TLG string (which should be the title of a given Outlook event on your TLG calendar). See script header for details."
	
	hotkeys     := []
	hotkeys.Push(["Launch Outlook TLG Popup (Highlight block in Outlook first)", "Ctrl + Shift + Alt + T"])
	hotkeys.Push(["Emergency exit",                                              "Ctrl + Shift + Alt + Win + R"])
	
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
	; Builds a string to add to a calendar event (with the format the outlook/tlg calendar needs to import happily into Delorean), then sends it and an Enter keystroke to save it.
	OUTLOOK_TLG(actionRow) {
		tlp     := actionRow.data["TLP"]
		message := actionRow.data["MSG"]
		dlg     := actionRow.data["DLG"]
		
		actionRow.data["DOACTION"] := tlp 
		if(dlg)
			actionRow.data["DOACTION"] .= "////" dlg
		actionRow.data["DOACTION"] .= ", " message
		
		; Do it.
		if(actionRow.isDebug) { ; Debug mode.
			actionRow.debugResult := actionRow.data["DOACTION"]
		} else {
			textToSend := actionRow.data["DOACTION"]
			SendRaw, % textToSend
			Send, {Enter}
		}
	}
}


; --------------------------------------------------
; - Emergency exit ---------------------------------
; --------------------------------------------------
~^+!#r::ExitApp
