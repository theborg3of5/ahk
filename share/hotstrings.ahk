/*
Author: Gavin Borg

Description: Adds a number of useful hotstrings universally.

Installation:
	Copy this file (hotstrings.ahk) to your local machine and run it.
	If you would like it to persist through reboots, move the local script (or add a shortcut to it) to your startup folder.

Shortcuts:
	See individual hotstrings below - just type one to replace it with the appropriate text.

Notes:
	None.
*/


; --------------------------------------------------
; - Configuration ----------------------------------
; --------------------------------------------------
{
	; Icon to show in the system tray for this script.
	iconPath := "" ; Comment out to use the default AHK icon.
	; #NoTrayIcon  ; Uncomment to hide the tray icon instead.
	
	epicSourceQA83        := "C:\EpicSource\8.3\App QA\"
	epicHBFolder          := "Hospital Billing\"
	epicEBFolder          := "Enterprise Billing\"
	epicFoundationProject := "Foundations\EpicDesktop\Desktop\ED.vbp"
}


; --------------------------------------------------
; - Setup, Includes, Constants ---------------------
; --------------------------------------------------
{
	#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
	#SingleInstance Force        ; Running this script while it's already running just replaces the existing instance.
	SendMode Input               ; Recommended for new scripts due to its superior speed and reliability.
	SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
	
	; Tray setup for double-click help popup, icon, etc.
	title       := "Hotstrings"
	description := "Auto-replaces typed strings with other things."
	hotkeys     := []
	hotkeys.Push(["Date: 6/25/16", "idate{Space}"])
	hotkeys.Push(["Date: 6-25-16", "dashidate"])
	hotkeys.Push(["Date: 6_25_16", "uidate"])
	hotkeys.Push(["Date: Saturday, 6/25/16", "didate"])
	hotkeys.Push(["Date: 6/25/16, Saturday", "iddate"])
	hotkeys.Push(["Time: 1:20 PM", "itime{Space}"])
	hotkeys.Push(["Date + time: 1:20 PM 6/25/16", "idatetime OR itimedate"])
	
	hotkeys.Push(["Program Files folder", "pff"])
	hotkeys.Push(["Program Files (x86) folder", "xpff"])
	hotkeys.Push(["App QA folder", "esf"])
	hotkeys.Push(["HB folder", "hesf"])
	hotkeys.Push(["EB folder", "eesf"])
	hotkeys.Push(["Foundations ED.vbp project", "fesf"])
	
	hotkeys.Push(["Emergency exit",         "Ctrl + Shift + Alt + Win + R"])
	
	setupTray(title, description, hotkeys, iconPath)
	scriptLoaded := true
}


; --------------------------------------------------
; - Main -------------------------------------------
; --------------------------------------------------
{
	{ ; Date and time.
		::idate:: ; No * -> waits until a finishing char (like space or enter) is pressed after typing out hotstring.
			sendDateTime("M/d/yy")
			
			; Excel special.
			if(WinActive("ahk_class XLMAIN"))
				Send, {Tab}
		return
		
		:*:dashidate::
			sendDateTime("M-d-yy")
		return
		:*:uidate::
			sendDateTime("M_d_yy")
		return
		:*:didate::
			sendDateTime("dddd`, M/d/yy")
		return
		:*:iddate::
			sendDateTime("M/d/yy`, dddd")
		return
		
		::itime:: ; No * -> waits until a finishing char (like space or enter) is pressed after typing out hotstring.
			sendDateTime("h:mm tt")
		return
		
		:*:idatetime::
		:*:itimedate::
			sendDateTime("h:mm tt M/d/yy")
		return
	}
	
	{ ; Folder paths
		:*:pff::C:\Program Files\
		:*:xpff::C:\Program Files (x86)\
		
		:*:esf::
			Send, % epicSourceQA83
		return
		
		:*:hesf::
			Send, % epicSourceQA83 epicHBFolder
		return
		:*:eesf::
			Send, % epicSourceQA83 epicEBFolder
		return
		
		:*:fesf::
			Send, % epicSourceQA83 epicFoundationProject
		return
		
		:*:sfesf::C:\Program Files (x86)\Epic\v8.2\Shared Files\
		:*:tesf::C:\ProgramData\Epic\82\TempData\
		:*:xesf::C:\ProgramData\Epic\HYPERSPACE\V8.2\SERVERDATA\CDETCP\DATA
	}
}


; --------------------------------------------------
; - Supporting functions ---------------------------
; --------------------------------------------------
{
	getDateTime(format, daysPlus = 0) {
		if(daysPlus != 0) {
			dateTimeVar := a_now
			dateTimeVar += daysPlus, days
		}
		
		FormatTime, var, %dateTimeVar%, %format%
		return var
	}

	sendDateTime(format, daysPlus = 0) {
		Send, % getDateTime(format, daysPlus)
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
