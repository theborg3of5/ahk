#If Config.isWindowActive("Putty")
	^c::return ; Disable breaking behavior for easy-to-hit-accidentally ^c, PuTTY already has a ^+c hotkey that works too.
	^v::Send, +{Insert} ; Normal paste, without all the inserting of spaces.
	+Tab::Send, {Left} ; Allow reverse field navigation.
	
	; Insert arbitrary text, inserting needed spaces to overwrite.
	^i::Putty.insertArbitraryText()
	
	; Screen wipes
	^l::Putty.wipeScreen()
	^+l::Putty.wipeScreen(true)
	
	; Get out of Chronicles
	^d::
		Send, +{F7 3}                ; Get out of (potentially-nested) open records
		Send, {PgDn 3}               ; Get out to main menu
		Send, quit{Enter}            ; Exit
		Putty.sendCommand("LOOKITT") ; Get back into Lookitt (in case we left)
		Sleep, 100
		Putty.wipeScreen()           ; Wipe the screen
	return
	
	; Scroll 1 line at a time
	^WheelUp::  Send, ^{PgUp}
	^WheelDown::Send, ^{PgDn}
	
	; Search within record edit screens
	^F9::Putty.recordEditSearch()
	^g:: Putty.recordEditSearch(true)
	
	; Open up settings window.
	!o::Putty.openSettingsWindow()
	
	; Open up the current log file.
	^+o::Putty.openCurrentLogFile()
	
	; Send specific commands
	^r:: Putty.sendCommand()
	^a:: Putty.sendCommand("BRIDGES")
	^e:: Putty.sendCommand("CHRONICLES")
	^+s::Putty.sendCommand("CR_STATUS")
	^+h::Putty.sendCommand("HB_FILERS")
	^o:: Putty.sendCommand("HS_CONFIG")
	^h:: Putty.sendCommand("HB")
	^z:: Putty.sendCommand("LOOKITT")
	^p:: Putty.sendCommand("PB")
	^+e::Putty.sendCommand("VIEW_RECORD")
#If
