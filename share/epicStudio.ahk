/*
Author: Gavin Borg

Description: 
	Adds some useful shortcuts to EpicStudio:
		Hotkeys that shortcut the debug search process by adding common conditions (with your specific values) into the search box.
		Provides a GUI-based approach to generating the needed "#GENERATE" code for Chronicles Data Operations in Caché.

Installation:
	1. Copy this file (epicStudio.ahk) to your local machine and run it.
	2. Edit the epicComputerName variable below to your workstation name (epic#####).
	3. Run the edited file.
	
	If you would like it to persist through reboots, move the local script (or add a shortcut to it) to your startup folder.

Usage:
	Hotkeys added:
		F5		Runs debug as before, but now auto-populates your workstation name, so you immedicately see relevant results.
		F6		Same as F5, but also fills in the exe string for Text (aka Reflection).
		F7		Same as F5, but also fills in the exe string for Hyperspace.
		F8		Same as F5, but also fills in the exe string for VB.

Notes:
	None.
*/


; --------------------------------------------------
; - Configuration ----------------------------------
; --------------------------------------------------
{
	epicComputerName := "epic#####" 								; YOUR WORKSTATION NAME HERE

	; Icon to show in the system tray for this script.
	iconPath := "C:\Program Files (x86)\EpicStudio\EpicStudio.exe" ; Comment out to use the default AHK icon.
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
	
	; Executable names for different sorts of things we might like to debug.
	global hyperspaceExe         := "EpicD"
	global reflectionExe         := "^%ZeINPTS"
	global vbExe                 := "vb6"
	
	esDebugTitles  := ["", "[Debug]"]
	esDebugStrings := [reflectionExe, hyperspaceExe, vbExe]
	
	; Tray setup for double-click help popup, icon, etc.
	title       := "EpicStudio hotkeys"
	description := "Adds debug hotkeys to EpicStudio which use the workstation configured above to make finding the right process easy."
	
	hotkeys     := []
	hotkeys.Push(["Debug w/ WS",               "F5"])
	hotkeys.Push(["Debug w/ WS + Text search", "F6"])
	hotkeys.Push(["Debug w/ WS + HS search",   "F7"])
	hotkeys.Push(["Debug w/ WS + VB search",   "F8"])
	hotkeys.Push(["Emergency exit",            "Ctrl + Shift + Alt + Win + R"])
	
	setupTray(title, description, hotkeys, iconPath)
	scriptLoaded := true
}


; --------------------------------------------------
; - Main -------------------------------------------
; --------------------------------------------------
{ ; Main EpicStudio window.
#IfWinActive, ahk_exe EpicStudio.exe
	; Debug, auto-search for workstation ID.
	$F5::
		esRunDebug("ws:" epicComputerName)
	return
	
	; Debug, auto-search for workstation ID and Reflection exe.
	F6::
		esRunDebug("ws:" epicComputerName " exe:" reflectionExe)
	return
	
	; Debug, auto-search for workstation ID and EpicD exe (aka Hyperspace).
	F7::
		esRunDebug("ws:" epicComputerName " exe:" hyperspaceExe)
	return
	
	; Debug, auto-search for workstation ID and VB exe.
	F8::
		esRunDebug("ws:" epicComputerName " exe:" vbExe)
	return
#IfWinActive
}


; --------------------------------------------------
; - Supporting functions ---------------------------
; --------------------------------------------------
{
	; Run EpicStudio in debug mode, given a particular string to search for.
	esRunDebug(searchString) {
		; Always send F5, even in debug mode - continue.
		Send, {F5}
		
		; Don't try and debug again if ES is already doing so.
		if(!isESDebugging()) {
		
			WinWait, Attach to Process, , 5
			if(!ErrorLevel) {
				Send, {Tab}{Down 2}
				SendRaw, % searchString
				Send, {Enter}{Down}
			}
		
		}
	}

	; Checks if ES is already in debug mode or not.
	isESDebugging() {
		global esDebugTitles, esDebugStrings
		
		return isWindowInStates(["active"], esDebugTitles, esDebugStrings, 2, "Slow")
	}

	; See if a window exists or is active with a given TitleMatchMode.
	isWindowInStates(states, titles, texts, matchMode = 1, speed = "Fast", findHidden = "Off") {
		retVal := false
		For i,s in states {
			For j,t in titles {
				For k,x in texts {
					if(isWindowInState(s, t, x, matchMode, speed)) {
						return true
					}
				}
			}
		}
		
		return false
	}

	isWindowInState(state, title = "", text = "", matchMode = 1, speed = "Fast") {
		SetTitleMatchMode, % matchMode
		SetTitleMatchMode, % speed
		
		retVal := false
		if(state = "active") {
			retVal := WinActive(title, text)
		} else if(InStr(state, "exist")) {
			retVal := WinExist(title, text)
		}
		
		SetTitleMatchMode, 1
		SetTitleMatchMode, Fast
		
		return retVal
	}
}


; --------------------------------------------------
; - Tray Stuff -------------------------------------
; --------------------------------------------------
{
	; This is what double-clicking the icon points to, shows the popup.
	MoreInfo:
		if(scriptLoaded) {
			; Show the user what we've done (that is, the popup)
			Gui, Show, W%popupWidth%, % scriptTitle
			return
		}

	; Build the help popup, set the tray icon, etc.
	setupTray(title, description, hotkeys, iconPath, width = 500) {
		global scriptTitle, popupWidth ; These three lines are to give the script title and width to the subroutine above.
		scriptTitle       := title
		popupWidth        := width
		
		; Set tray icon (if path given)
		if(FileExist(iconPath))
			Menu, Tray, Icon, %iconPath%
		
		; Set mouseover text for icon
		Menu, Tray, Tip, 
		(LTrim
			%title%, double-click for details.
			
			Emergency Exit: Ctrl+Shift+Alt+Win+R
		)
		
		; Build right-click menu
		Menu, Tray, NoStandard               ; Remove the standard menu items
		Menu, Tray, Add, More Info, MoreInfo ; More info item
		Menu, Tray, Add                      ; Separator
		Menu, Tray, Standard                 ; Put the standard menu items back at the bottom
		Menu, Tray, Default, More Info       ; Make more info item the default (activated when icon double-clicked)
		
		; Put together double-click help popup.
		textWidth   := width - 30      ; Room so we don't overflow
		columnWidth := textWidth / 2   ; Divide space in half
		labelHeight := 25              ; Distance between tops of labels (title-description and inside hotkey table)
		
		labelPos       := "W" columnWidth " section xs" ; Use xs to get back to first column for each label, then starting a new section so we only ever create 2 columns with ys.
		keyPos         := "W" columnWidth " ys" ; ys put us in a new column of the current section (which was started by the corresponding label)
		
		; General GUI properties
		Gui, Font, s12
		Gui, Margin, 10, 10
		
		; Title
		Gui, Font, w700 underline ; Bold, underline.
		Gui, Add, Text, , % title
		
		; Description
		Gui, Font, norm
		Gui, Margin, , 0  ; Want this close to the title.
		Gui, Add, Text, W%textWidth%, % description
		
		; Hotkey table.
		Gui, Font, underline
		Gui, Margin, , 10 ; Space between "Hotkeys" and description
		Gui, Add, Text, , Hotkeys
		Gui, Font, norm
		
		Gui, Margin, , 5 ; Less space between rows within the table.
		For i,ary in hotkeys {
			; Label
			label := ary[1]
			Gui, Add, Text, W%columnWidth% section xs, % label ; Use xs to get back to first column for each label, then starting a new section so we only ever create 2 columns with ys.
			
			; Hotkey
			key := ary[2]
			Gui, Add, Text, W%columnWidth% ys, % key ; ys put us in a new column of the current section (which was started by the corresponding label)
		}
		
		Gui, Margin, , 10 ; Padding at the bottomm.
	}
}


; --------------------------------------------------
; - Emergency exit ---------------------------------
; --------------------------------------------------
~^+!#r::ExitApp
