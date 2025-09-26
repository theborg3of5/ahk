; SmartTextBox handling
#If Config.isWindowActive("EMC2") || Config.isWindowActive("EMC2 Popup")
	^+c::Send, ^e ; Apply code formatting
	^.:: ; Start bulleted list
		Send, {Home}   ; Get to start of line if we're not already there (doesn't handle word wrapping)
		Send, *{Space} ; Trigger automatic list creation
		Send, {Escape} ; Get rid of the "undo automatic list" popup.
	return
	^/::
		Send, {Home}    ; Get to start of line if we're not already there (doesn't handle word wrapping)
		Send, 1.{Space} ; Trigger automatic list creation
		Send, {Escape}  ; Get rid of the "undo automatic list" popup.
	return
#If

; Main EMC2 window
#If Config.isWindowActive("EMC2")
	^h:: Send, ^7 ; Make ^h for server object, similar to ^g for client object.
	^+h::Send, ^h ; Keep access to the "find and replace" hotkey.
	$F5::+F5      ; Make F5 work everywhere by mapping it to shift + F5.
	^+t::return   ; Block ^+t login from Hyperspace - it does very strange zoom-in things and other nonsense.
	
	; Link and record number things based on the current record.
	!c:: EpicLib.copyEMC2RecordIDFromText(WinGetTitle("A")) ; Copy ID
	^+o::VSCode.openCurrentDLG()                            ; Take DLG # and pop up the DLG in EpicStudio sidebar.
	
	; SmartPhrase hotstrings.
	:X:qa.dbc:: EMC2.insertSmartPhrase("DBCQA")
	:X:qa.sdbc::EMC2.insertSmartPhrase("DBCQASIMPLE")
	:X:qa.new:: EMC2.insertSmartPhrase("QANEW")
	:X:qa.sec::
		EMC2.insertSmartPhrase("SECTION")
		Sleep, 750 ; Have to wait for phrase to finish inserting
		Send, {Down}{Enter} ; Select and submit the only choice - a list that inserts the text.
	return
	
	; De-emphasized "contact comment"
	^8::EMC2.insertSmartPhrase("SIDENOTE")
#If

; Worklist: use the currently-selected row to perform actions instead of the title.
#If Config.isWindowActive("EMC2 Worklist")
	!w::EMC2.openCurrentWorklistItemWeb() ; Open the selected item in web.
#If

; DLG open
#If Config.isWindowActive("EMC2 DLG")
	!i::
		openDLGIssues() {
			record := EpicLib.getBestEMC2RecordFromText(WinGetTitle("A"))
			new ActionObjectEMC2(record.id, "DLG-I").openWeb() ; Just use the ID that we got, override the INI with the issues-specific one.
		}
	!h::
		openDLGHistory() {
			record := EpicLib.getBestEMC2RecordFromText(WinGetTitle("A"))
			new ActionObjectEMC2(record.id, "DLG-H").openWeb() ; Just use the ID that we got, override the INI with the issues-specific one.
		}
#If

; Design open
#If Config.isWindowActive("EMC2 XDS")
	; Disable Ctrl+Up/Down hotkeys, never hit these intentionally.
	^Down::return
	^Up::  return
#If

; Lock/unlock hotkeys by INI
#If Config.isWindowActive("EMC2 QAN")
	^l::Send, !l
#If Config.isWindowActive("EMC2 XDS")
	^l::Send, ^+!i
#If Config.isWindowActive("EMC2 DLG")
	^l::Send, !+{F5}
#If

; Email windows
#If Config.isWindowActive("EMC2 Email Popup")
	:X:.dbcdevs::EMC2.sendDBCDevIDs()
#If
