; SmartTextBox handling
#If Config.isWindowActive("EMC2") || Config.isWindowActive("EMC2 DLG/XDS Issue Popup") || Config.isWindowActive("EMC2 QAN Notes") || Config.isWindowActive("EMC2 DRN Quick Review") || Config.isWindowActive("EMC2 XDS Content")
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
	$F5::+F5      ; Make F5 work everywhere by mapping it to shift + F5.
	^+t::return   ; Block ^+t login from Hyperspace - it does very strange zoom-in things and other nonsense.
	
	; Link and record number things based on the current record.
	!c:: EpicLib.copyEMC2RecordIDFromText(WinGetTitle("A")) ; Copy ID
	^+o::EMC2.openCurrentDLGInEpicStudio()                  ; Take DLG # and pop up the DLG in EpicStudio sidebar.
	
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

; Design open
#If Config.isWindowActive("EMC2 XDS")
	; Disable Ctrl+Up/Down hotkeys, never hit these intentionally.
	^Down::return
	^Up::  return
#If

; Design email window
#If Config.isWindowActive("EMC2 XDS Email") || Config.isWindowActive("EMC2 DLG Email") || Config.isWindowActive("EMC2 XDS Submit")
	:X:.dbcdevs::EMC2.sendDBCDevIDs()
#If

; Lock/unlock hotkeys by INI
#If Config.isWindowActive("EMC2 QAN") || Config.isWindowActive("EMC2 XDS")
	^l::Send, !l
#If Config.isWindowActive("EMC2 DLG")
	^l::Send, !+{F5}
#If
