/*
Author: Gavin Borg

Description: A couple of hotkeys for easier work with HTML in Hyperspace.

Installation:
	Copy this file (.ahk) to your local machine and run it.
	If you would like it to persist through reboots, move the local script (or add a shortcut to it) to your startup folder.

Shortcuts:
	Ctrl + Alt + C:
		Takes the HTML from the current control, stuffs it in a file, and opens that file in IE. Great for using IE's debug tools for CSS tweaks.
	Ctrl + Alt + O:
		For use with Debug XML on. Grabs the tempdata filepath at the bottom (to where the XML downloaded lives) and opens it.
	
*/


; --------------------------------------------------
; - Configuration ----------------------------------
; --------------------------------------------------
{
	; Icon to show in the system tray for this script.
	iconPath := "" ; Comment out to use the default AHK icon.
	; #NoTrayIcon  ; Uncomment to hide the tray icon instead.
	
	htmlFilePath := "C:\Users\gborg\Dev\hsOutput.html"
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
	title       := "Hyperspace HTML Tools"
	description := "A couple of hotkeys for easier work with HTML in Hyperspace."
	
	hotkeys     := []
	hotkeys.Push(["Emergency exit",          "Ctrl + Shift + Alt + Win + R"])
	hotkeys.Push(["Open current HTML in IE", "Ctrl + Alt + C"])
	hotkeys.Push(["Open Debug XML folder",   "Ctrl + Alt + O"])
	
	setupTray(title, description, hotkeys, iconPath)
	scriptLoaded := true
	
	global SUBTYPE_FilePath := "FILEPATH"
}


; --------------------------------------------------
; - Main -------------------------------------------
; --------------------------------------------------
#If WinActive("ahk_class ThunderRT6FormDC") || WinActive("ahk_class ThunderFormDC") || WinActive("ahk_class ThunderRT6MDIForm") || WinActive("ahk_class ThunderMDIForm")
	; Grab the current html, stuff it in a file, and show it in IE for dev tools.
	^!c::
		html := getHyperspaceHTML()
		FileDelete, %htmlFilePath%
		FileAppend, %html%, %htmlFilePath%
		Run, C:\Program Files\Internet Explorer\iexplore.exe %htmlFilePath%
	return
	
	; With XML debug on - grabs the path to the tempdata folder from the bottom of the screen, opens it.
	^!o::
		Send, ^a
		text := getSelectedText()
		Loop, Parse, text, `n, `r
		{
			; DEBUG.popup(A_LoopField)
			if(isPath(A_LoopField)) {
				filePath := A_LoopField
				break
			}
		}
		
		; DEBUG.popup("Found path", filePath)
		if(filePath)
			Run, % filePath
	return
#If


; --------------------------------------------------
; - Supporting functions ---------------------------
; --------------------------------------------------
{
	getHyperspaceHTML() {
		; Save off the clipboard to restore and wipe it for our own use.
		ClipSaved := ClipboardAll
		Clipboard := 
		
		; Grab the HTML with HTMLGrabber hotkey.
		SendPlay, , ^+!c
		Sleep, 100
		
		; Get it off of the clipboard and restore the clipboard.
		textFound := clipboard
		Clipboard := ClipSaved
		ClipSaved = ; Free memory
		
		return textFound
	}
	
	; Grabs the selected text using the clipboard, fixing the clipboard as it finishes.
	getSelectedText() {
		ClipSaved := ClipboardAll ; Save the entire clipboard to a variable of your choice.
		clipboard :=              ; Clear the clipboard
		
		Send, ^c
		ClipWait, 1               ; Wait for the clipboard to actually contain data.
		
		textFound := clipboard
		
		clipboard := ClipSaved    ; Restore the original clipboard. Note the use of Clipboard (not ClipboardAll).
		ClipSaved =               ; Free the memory in case the clipboard was very large.
		
		return textFound
	}
	
	; Test whether something is a filepath.
	; Also may change the path slightly to make it runnable.
	isPath(ByRef text, ByRef type = "") {
		colonSlashPos := InStr(text, "://")
		protocols := ["http", "ftp"]
		
		if(subStr(text, 1, 8) = "file:///") { ; URL'd filepath.
			text := subStr(text, 9) ; strip off the file:///
			text := RegExReplace(text, "%20", A_Space)
			; DEBUG.popup("Trimmed path", text)
			type := SUBTYPE_FilePath
		} else if(subStr(text, 2, 2) = ":\") { ; Windows filepath
			type := SUBTYPE_FilePath
		} else if(subStr(text, 1, 2) = "\\") { ; Windows network path
			type := SUBTYPE_FilePath
		}
		
		; DEBUG.popup("isPath", "Finish", "Type", type)
		return type
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



