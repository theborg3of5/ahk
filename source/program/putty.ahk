#If Config.isWindowActive("Putty")
	^c::return ; Disable breaking behavior for easy-to-hit-accidentally ^c, PuTTY already has a ^+c hotkey that works too.
	^v::Send, +{Insert} ; Normal paste, without all the inserting of spaces.
	+Tab::Send, {Left} ; Allow reverse field navigation.
	
	; Insert arbitrary text, inserting needed spaces to overwrite.
	^i::Putty.insertArbitraryText()
	
	; Screen wipe
	^l::
		Send, !{Space}
		Send, t ; Reset terminal
		Sleep, 100
		Send, {Enter} ; Show prompt
	return
	; Screen wipe and clear scrollback
	^+l::
		Send, !{Space}
		Send, t ; Reset terminal
		Send, !{Space}
		Send, l ; Clear scrollback
		Sleep, 100
		Send, {Enter} ; Show prompt
	return
	
	; Scrolling (^PgUp/^PgDn scrolls one line at a time)
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
	^o:: Putty.sendCommand("HS_CONFIG")
	^h:: Putty.sendCommand("HB")
	^z:: Putty.sendCommand("LOOKITT")
	^p:: Putty.sendCommand("PB")
	^+e::Putty.sendCommand("VIEW_RECORD")
#If
