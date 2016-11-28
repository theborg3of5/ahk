/*
Author: Originally found at http://wiki.epic.com/main/AutoHotkey#Fill_in_DLG_numbers_for_SVN . Modified slightly by Gavin Borg.

Description: Auto-fills the DLG field in the TortoiseSVN commit window, using the URL displayed.

Installation:
	Copy the containing folder (TortoiseSVN_DLGFiller) to your local machine and run this script.
	If you would like it to persist through reboots, add a shortcut to your local copy of this script to your startup folder.

Notes:
	This works by running in the background, waiting for a window whose title matches the tortoiseSVN title regex below.
	Since it operates based on the title of the window, it unfortunately won't work for repositories not in the C:\EpicSource\v#.#\<DLG#>\... format.
*/


; --------------------------------------------------
; - Configuration ----------------------------------
; --------------------------------------------------
{
	; Icon to show in the system tray for this script.
	iconPath := "turtle.ico" ; Comment out to use the default AHK icon.
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
	
	; Tray setup for double-click help popup, icon, etc.
	title       := "TortoiseSVN DLG Filler"
	description := "Auto-fills the DLG field in the TortoiseSVN commit window, using the URL displayed."
	hotkeys     := []
	hotkeys.Push(["Emergency exit", "Ctrl + Shift + Alt + Win + R"])
	
	setupTray(title, description, hotkeys, iconPath)
	scriptLoaded := true
}


; --------------------------------------------------
; - Main -------------------------------------------
; --------------------------------------------------
{
	SetTitleMatchMode RegEx ; Determines how we're searching titles, in this case with Regular Expressions.

	Loop {
		WinWaitActive, ^C:\\EpicSource\\\d\.\d\\DLG-(\d+)[-\\].* - Commit - TortoiseSVN
		ControlGetText, DLG, Edit2
		if(DLG = "") {
			WinGetActiveTitle, Title
			RegExMatch(Title, "^C:\\EpicSource\\\d\.\d\\DLG-(\d+)[-\\].* - Commit - TortoiseSVN", DLG)
			ControlSend, Edit2, %DLG1%
		}
		
		Sleep, 5000 ; Wait 5 seconds before going again, to reduce idle looping.
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
