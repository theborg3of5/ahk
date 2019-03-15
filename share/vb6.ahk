/*
Author: Gavin Borg

Description: Adds a number of shortcuts for VB6.

Installation:
	1. If VB is set to run as admin, AutoHotkey must also be set to run as admin. To do this:
		Find AutoHotkey.exe (Located in C:\Program Files\AutoHotkey)
		Right-click -> Properties -> Compatibility Tab -> Run this program as an administrator
	2. Copy this containing folder (HeadersParserComment) to your desktop and run the .ahk file within.
	3. Set the USER_INTIALS variable below to the initials you want to appear on contact comments in VB.

	If you would like it to persist through reboots, move the local script (or add a shortcut to it) to your startup folder.

Shortcuts:
	Pause (Break):
		Switches between design and code view for VB controls.
	Ctrl+Y/Ctrl+Shift+Z: 
		These will now “redo”. This was created because by default, Ctrl+Y cuts a line.
	Ctrl+M:
		Opens the make window for the current project. Uses the File->Make… item.
	Ctrl+Shift+H:
		Opens the Epic Headers popup found in Add-ins->Epic Headers.
	Ctrl+Shift+P:
		Opens the Epic VBParse popup found in Add-ins->Epic VBParse.
	Ctrl+Shift+R:
		Opens the references window. Note that the references window opens slowly.
	Ctrl+8:
		Generates a contact comment, similar to EpicStudio (i.e., *gdb 08/15 123456 - )
	Ctrl+F:
		Only applies to the References or Components windows, will prompt you for a reference to find and scroll to.
		Enter the full or partial (beginning of) name of the reference and press Enter to have the script scroll there.
		For convenience, you may use "*" instead of "Epic Systems" to save keystrokes.
	Ctrl+Shift+F:
		Create all required procedure stubs from an interface.
		Start with your cursor on the "Implements ..." line.

Notes:
	If you run VB6 as an admin, you need to also run AutoHotkey.exe (typically in C:\Program Files\AutoHotkey\) as an admin as well.
		Failing to do so will result in this script not appearing to work at all.
	The contact comment hotkey pulls the DLG ID from the title of the VBG that is currently open; as such, it will only work correctly if you open the project using a VBG with a title of DLG###### (which EMC2 normally creates for you).
	If only the commenting hotkeys don't work, you may need to take new screenshots for those two toolbar buttons and replace the ones in the folder (the folder on your desktop, that is, not the server folder).
*/


; --------------------------------------------------
; - Configuration ----------------------------------
; --------------------------------------------------
{
	USER_INITIALS := "" ; YOUR INITIALS HERE
	
	; Icon to show in the system tray for this script.
	iconPath := "C:\Program Files (x86)\Microsoft Visual Studio\VB98\VB6.EXE" ; Comment out to use the default AHK icon.
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
	
	; Constants
	global STRING_CASE_MIXED := 0
	global STRING_CASE_UPPER := 1
	global STRING_CASE_LOWER := 2
	
	; Tray setup for double-click help popup, icon, etc.
	title       := "VB6 hotkeys"
	description := "Adds hotkeys to Visual Basic 6."
	
	hotkeys     := []
	hotkeys.Push(["Switch between design/code view",                       "Pause (Break)"])
	hotkeys.Push(["Redo",                                                  "Ctrl + Y / Ctrl + Shift + Z"])
	hotkeys.Push(["Make window (via File > Make)",                         "Ctrl + M"])
	hotkeys.Push(["Epic Headers popup",                                    "Ctrl + Shift + H"])
	hotkeys.Push(["Epic VBParse popup",                                    "Ctrl + Shift + P"])
	hotkeys.Push(["Contact comment",                                       "Ctrl + 8"])
	hotkeys.Push(["Quick search (References/Components window only)",      "Ctrl + F"])
	hotkeys.Push(["Create all required procedure stubs from an interface. Start with your cursor on the 'Implements ...' line.", "Ctrl + Shift + F"])
	hotkeys.Push(["Emergency exit",                                        "Ctrl + Shift + Alt + Win + R"])
	
	setupTray(title, description, hotkeys, iconPath)
	scriptLoaded := true
}


; --------------------------------------------------
; - Main -------------------------------------------
; --------------------------------------------------
; Main VB window.
#IfWinActive, ahk_class wndclass_desked_gsk
	; Redo, not yank.
	^y::
	^+z::
		Send, !e
		Sleep, 100
		Send, r
	return
	
	; Code vs. design swap. Note: only works if mini-window within window is maximized within outer window.
	Pause::
		WinGetTitle, title
		StringTrimRight, title, title, 2
		parenPos := InStr(title, "(")
		StringTrimLeft, title, title, parenPos
		
		if(title = "Code") {
			Send, +{F7}
		} else if(title = "Form" || title = "UserControl") {
			Send, {F7}
		}
	return
	
	; Make hotkey.
	^m::
		Send, !f
		Sleep, 100
		Send, k
	return
	
	; Epic Headers Addin.
	^+h::
		Send, !a
		Sleep, 100
		Send, {Up}{Enter}
	return
	
	; Epic VB Parse Addin.
	^+p::
		Send, !a
		Sleep, 100
		Send, {Up 2}{Enter}
	return
	
	; References window.
	^+r::
		Send, !p
		Sleep, 100
		Send, n
	return

	; Contact comment hotkey.
	^8::
		; Date
		FormatTime, date, , MM/yy
		
		; DLG - uses VBG title, usually DLG######
		ControlGetText, projectName, PROJECT1
		splitName := StrSplit(projectName, " ")
		dlgName := splitName[splitName.MaxIndex()]
		
		outStr .= "' *" USER_INITIALS " " date " " SubStr(dlgName, 4) " - "
		
		SendRaw, % outStr
	return
	
	; Create all required procedure stubs from an interface.
	^+f::
		vbGetComboBoxClasses(firstField, secondField)
		; DEBUG.popup("First", firstField, "Second", secondField)
		
		ControlGet, CurrentProcedure, List, Selected, %secondField%
		; DEBUG.popup("Current procedure", CurrentProcedure)
		
		; Allow being on "Implements ..." line instead of having left combobox correctly selected first.
		if(CurrentProcedure = "(General)") {
			ClipSave := clipboard ; Save the current clipboard.
			
			selectCurrentLine()
			Send, ^c
			
			Sleep, 100 ; Allow clipboard time to populate.
			
			lineString := clipboard
			clipboard := ClipSave ; Restore clipboard
			
			; Pull the class name from the implements statement.
			StringTrimLeft, className, lineString, 11
			
			; Trims trailing spaces via "Autotrim" behavior.
			className = %className%
			
			; Open the dropdown so we can see everything.
			ControlFocus, %secondField%, A
			Send, {Down}
			Sleep, 100
			
			ControlGet, ObjectList, List, , %secondField%
			; DEBUG.popup("List of objects", ObjectList)
			
			classRow := 0
			
			Loop, Parse, ObjectList, `n  ; Rows are delimited by linefeeds (`n).
			{
				if(A_LoopField = className) {
					; DEBUG.popup("Class name", className, "Is on row", A_Index)
					classRow := A_Index
					break
				}
			}
			
			Control, Choose, %classRow%, %secondField%, A
		}
		
		LastItem := ""
		SelectedItem := ""
		
		ControlFocus, %firstField%, A
		Send, {Down}
		
		Sleep, 100
		
		ControlGet, List, List, , %firstField%
		; DEBUG.popup("List of functions", List)
		
		RegExReplace(List, "`n", "", countNewLines)
		countNewLines++
		
		Loop %countNewLines% {			
			ControlFocus, %firstField%, A
			Control, Choose, %A_Index%, %firstField%, A
		}
	return
#IfWinActive

; References/components windows.
#If WinActive("References - ") || WinActive("Components")
	^f::
		SAME_THRESHOLD := 10
		
		InputBox, userIn, Partial Search, Please enter the first portion of the row to find. You may replace "Epic Systems " with "* "
		if(ErrorLevel) {
			return
		}
		
		StringReplace, userIn, userIn, * , Epic Systems , All
		
		prevRow := ""
		prevLine := ""
		numSame := 1
		notFoundYet := true
		
		currLine := userIn
		currLen := StrLen(userIn)
		
		ControlGetText, currRow, Button5, A
		if(currLine < currRow) {
			Send, {Home}
		}
		
		firstChar := SubStr(currLine, 1, 1)
		
		; Loop downwards through lines.
		While, notFoundYet {
			SendRaw, %firstChar%
			
			Sleep, 1
			ControlGetText, currRow, Button5, A
			; MsgBox, %currRow%
			
			; This block controls for the end of the listbox, it stops when the last SAME_THRESHOLD rows are the same.
			if(currRow = prevRow) {
				numSame++
			} else {
				numSame := 1
			}
			; MsgBox, Row: %currRow% `nPrevious: %prevRow% `nnumSame: %numSame%
			if(numSame = SAME_THRESHOLD) { ; Pretty sure we're at the end now, finish.
				notFoundYet := false
			}
			
			prevRow := currRow
			
			; If it matches our input, finish.
			if(SubStr(currRow, 1, currLen) = currLine) {
				notFoundYet := false
			}
		}
	return
#IfWinActive


; --------------------------------------------------
; - Supporting Functions ---------------------------
; --------------------------------------------------
{
	; Obtains the classNNs for the two top comboboxes.
	vbGetComboBoxClasses(ByRef firstField, ByRef secondField) {
		WinGet, List, ControlList, A
		; DEBUG.popup(List, "Control list in window")
		
		Loop, Parse, List, `n  ; Rows are delimited by linefeeds (`n).
		{
			if(InStr(A_LoopField, "ComboBox")) {
				ControlGetPos, x, y, w, h, %A_LoopField%, A
				; DEBUG.popup(A_LoopField, "Class name", A_Index, "On row", x, "X", y, "Y")
				
				; When two in a row have the same y value, they're what we're looking for.
				if(y = yPast) {
					; DEBUG.popup(x, "Got two! `nX", y, "Y", yPast, "Y past")
					firstField := A_LoopField
					
					break
				}
				
				yPast := y
				secondField := A_LoopField
			}
		}
		
		; DEBUG.popup(secondField, "Field 1", firstField, "Field 2")
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
