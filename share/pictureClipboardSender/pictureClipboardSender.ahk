/*
Author: Gavin Borg

Description: Allows you to save/load pictures (or anything else, really) to/from the clipboard, and paste them with hotstrings.

Installation:
	Copy this folder to your local machine and run the .ahk file.
	If you would like it to persist through reboots, add a shortcut to the .ahk file to your startup folder.

Hotstrings:
	.saveClipboard     - Save the current clipboard to a file that can be read/pasted with the functions in this script.
	.cannotReproduce   - Pastes the image stored in clips/cannotReproduce.clip
	.itWorkedYesterday - Pastes the image stored in clips/itWorkedYesterday.clip
	
Notes:
	Feel free to save off your own .clip files using the .saveClipboard hotstring or saveClipboardToFile() function, and create new hotstrings for specific images.
*/


; --------------------------------------------------
; - Configuration ----------------------------------
; --------------------------------------------------
{
	; Icon to show in the system tray for this script.
	iconPath := "" ; Comment out to use the default AHK icon. ; GDB TODO
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
	
	; ; GDB TODO - delete either this or the tray section below.
	; #Include Includes/
		; #Include _trayHelper.ahk
	
	; ; Tray setup for double-click help popup, icon, etc.
	; title       := ""
	; description := ""
	
	; hotkeys     := []
	; hotkeys.Push(["Emergency exit",         "Ctrl + Shift + Alt + Win + R"])
	
	; setupTray(title, description, hotkeys, iconPath)
	scriptLoaded := true
}


; --------------------------------------------------
; - Main -------------------------------------------
; --------------------------------------------------
:*:.saveClipboard::
	saveClipboardToFile()
return

:*:.cannotReproduce::
	sendFileWithClipboard("clips/cannotReproduce.clip")
return

:*:.itWorkedYesterday::
	sendFileWithClipboard("clips/itWorkedYesterday.clip")
return


; --------------------------------------------------
; - Supporting functions ---------------------------
; --------------------------------------------------
{
	saveClipboardToFile(filePath = "") {
		; If no path was given, prompt the user with a popup.
		if(!filePath)
			FileSelectFile, filePath, S, %A_ScriptDir%\clips\*.clip, What file should the clipboard be saved to?, *.clip
		if(!filePath)
			return
		
		FileAppend, %ClipboardAll%, %filePath%
	}

	sendFileWithClipboard(filePath = "") {
		; If no path was given, prompt the user with a popup.
		if(!filePath)
			FileSelectFile, filePath, S, %A_ScriptDir%\clips\*.clip, What file should be sent?
		if(!filePath)
			return
		
		; Save off the current clipboard and blank it out so we can wait for it to be filled from the file.
		tempClip := ClipboardAll
		Clipboard := 
		
		readFileToClipboard(filePath)
		
		Send, ^v
		
		Sleep, 500 ; If this isn't delayed, it overwrites the clipboard before the paste actually happens.
		Clipboard := tempClip
	}

	; Read a file (which we assume is in clipboard format, saved from the clipboard) and put it on the clipboard.
	readFileToClipboard(filePath = "") {
		; If no path was given, prompt the user with a popup.
		if(!filePath)
			FileSelectFile, filePath, S, , What file should be placed on the clipboard?, *.clip
		if(!filePath)
			return
		
		FileRead, Clipboard, *c %filePath% ; *c = clipboard-format file
		ClipWait, 5, 1
	}
}


; --------------------------------------------------
; - Tray Stuff -------------------------------------
; --------------------------------------------------
{
	; ; This is what double-clicking the icon points to, shows the popup.
	; MoreInfo:
		; if(scriptLoaded) {
			; ; Show the user what we've done (that is, the popup)
			; Gui, Show, W%popupWidth%, % scriptTitle
			; return
		; }

	; ; Build the help popup, set the tray icon, etc.
	; setupTray(title, description, hotkeys, iconPath, width = 500) {
		; global scriptTitle, popupWidth ; These three lines are to give the script title and width to the subroutine above.
		; scriptTitle       := title
		; popupWidth        := width
		
		; ; Set tray icon (if path given)
		; if(FileExist(iconPath))
			; Menu, Tray, Icon, %iconPath%
		
		; ; Set mouseover text for icon
		; Menu, Tray, Tip, 
		; (LTrim
			; %title%, double-click for details.
			
			; Emergency Exit: Ctrl+Shift+Alt+Win+R
		; )
		
		; ; Build right-click menu
		; Menu, Tray, NoStandard               ; Remove the standard menu items
		; Menu, Tray, Add, More Info, MoreInfo ; More info item
		; Menu, Tray, Add                      ; Separator
		; Menu, Tray, Standard                 ; Put the standard menu items back at the bottom
		; Menu, Tray, Default, More Info       ; Make more info item the default (activated when icon double-clicked)
		
		; ; Put together double-click help popup.
		; textWidth   := width - 30      ; Room so we don't overflow
		; columnWidth := textWidth / 2   ; Divide space in half
		; labelHeight := 25              ; Distance between tops of labels (title-description and inside hotkey table)
		
		; labelPos       := "W" columnWidth " section xs" ; Use xs to get back to first column for each label, then starting a new section so we only ever create 2 columns with ys.
		; keyPos         := "W" columnWidth " ys" ; ys put us in a new column of the current section (which was started by the corresponding label)
		
		; ; General GUI properties
		; Gui, Font, s12
		; Gui, Margin, 10, 10
		
		; ; Title
		; Gui, Font, w700 underline ; Bold, underline.
		; Gui, Add, Text, , % title
		
		; ; Description
		; Gui, Font, norm
		; Gui, Margin, , 0  ; Want this close to the title.
		; Gui, Add, Text, W%textWidth%, % description
		
		; ; Hotkey table.
		; Gui, Font, underline
		; Gui, Margin, , 10 ; Space between "Hotkeys" and description
		; Gui, Add, Text, , Hotkeys
		; Gui, Font, norm
		
		; Gui, Margin, , 5 ; Less space between rows within the table.
		; For i,ary in hotkeys {
			; ; Label
			; label := ary[1]
			; Gui, Add, Text, W%columnWidth% section xs, % label ; Use xs to get back to first column for each label, then starting a new section so we only ever create 2 columns with ys.
			
			; ; Hotkey
			; key := ary[2]
			; Gui, Add, Text, W%columnWidth% ys, % key ; ys put us in a new column of the current section (which was started by the corresponding label)
		; }
		
		; Gui, Margin, , 10 ; Padding at the bottomm.
	; }
}


; --------------------------------------------------
; - Emergency exit ---------------------------------
; --------------------------------------------------
~^+!#r::ExitApp



