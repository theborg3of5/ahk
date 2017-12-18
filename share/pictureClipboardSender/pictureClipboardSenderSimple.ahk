/*
Author: Gavin Borg

Description: Allows you to save/load pictures (or anything else, really) to/from the clipboard, and paste them with hotstrings.

Installation:
	Copy this folder to your local machine and run the .ahk file.
	If you would like it to persist through reboots, add a shortcut to the .ahk file to your startup folder.

Hotstrings (just type them):
	.saveClipboard - Save the current clipboard to a file that can be read/pasted with the functions in this script.
	.noRepro       - Pastes the image stored in clips/cannotReproduce.clip
	.yesterday     - Pastes the image stored in clips/itWorkedYesterday.clip
	
Notes:
	Feel free to add your own! It's as simple as:
		1. Copy the image you want onto the clipboard.
		2. Save it off to a file using the .saveClipboard hotstring (just type that).
		3. Create a new hotstring below in the "Main" section. Format:
				:*:<hotstringToType>::
					sendFileWithClipboard("<path relative to this script>")
				return
		4. Save, reload the script, and enjoy!
	Note that the hotstring does not have to match the filename - feel free to make the hotstrings whatever you want.
*/


; --------------------------------------------------
; - Configuration ----------------------------------
; --------------------------------------------------
{
	; Icon to show in the system tray for this script.
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
}


; --------------------------------------------------
; - Main -------------------------------------------
; --------------------------------------------------
:*:.saveClipboard::
	saveClipboardToFile()
return

:*:.noRepro::
	sendFileWithClipboard("clips/cannotReproduce.clip")
return

:*:.yesterday::
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
; - Emergency exit ---------------------------------
; --------------------------------------------------
~^+!#r::ExitApp
