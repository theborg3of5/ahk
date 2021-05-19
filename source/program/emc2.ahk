; Change code formatting hotkey to something more universal in various windows.
#If Config.isWindowActive("EMC2") || Config.isWindowActive("EMC2 DLG/XDS Issue Popup") || Config.isWindowActive("EMC2 QAN Notes") || Config.isWindowActive("EMC2 DRN Quick Review") || Config.isWindowActive("EMC2 XDS Magnify")
	^+c::Send, ^e
#If

; Main EMC2 window
#If Config.isWindowActive("EMC2")
	^h:: Send, ^7 ; Make ^h for server object, similar to ^g for client object.
	^+8::Send, !o ; Contact comment, EpicStudio-style.
	$F5::+F5      ; Make F5 work everywhere by mapping it to shift + F5.
	^+t::return   ; Block ^+t login from Hyperspace - it does very strange zoom-in things and other nonsense.
	
	; Link and record number things based on the current record.
	!c:: EMC2.copyCurrentRecord()          ; Get ID
	!w:: EMC2.openCurrentRecordWeb()       ; Open web version of the current object.
	!+w::EMC2.openCurrentRecordWebBasic()  ; Open "basic" web version (always EMC2 summary, even for Sherlock/Nova records) of the current object.
	^+o::EMC2.openCurrentDLGInEpicStudio() ; Take DLG # and pop up the DLG in EpicStudio sidebar.
	
	; SmartText hotstrings. Added to favorites to deal with duplicate/similar names.
	:X:qa.dbc:: EMC2.insertSmartText("DBC QA INSTRUCTIONS")
	:X:qa.sdbc::EMC2.insertSmartText("DBC SIMPLE AND STRAIGHTFORWARD QA INSTRUCTIONS")
	:X:qa.new:: EMC2.insertSmartText("QA INSTRUCTIONS - NEW CHANGES")
	
	:X:openall::EMC2.openRelatedQANsFromTable() ; Open all related QANs from an object in EMC2.
#If

; Design open
#If Config.isWindowActive("EMC2 XDS")
	; Disable Ctrl+Up/Down hotkeys, never hit these intentionally.
	^Down::return
	^Up::  return
#If

; Design email window
#If Config.IsWindowActive("EMC2 XDS Email") || Config.IsWindowActive("EMC2 DLG Email")
	:X:.dbcdevs::EMC2.sendDBCDevIDs()
#If

; Lock/unlock hotkeys by INI
#If Config.isWindowActive("EMC2 QAN") || Config.isWindowActive("EMC2 XDS")
	^l::Send, !l
#If Config.isWindowActive("EMC2 DLG")
	^l::Send, !+{F5}
#If
