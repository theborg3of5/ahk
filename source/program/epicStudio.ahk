; EpicStudio hotkeys and helpers.
#If Config.isWindowActive("EpicStudio")
	; Remap some of the tools to get easier access to those I use often.
	!1::!3 ; EZParse
	!2::!5 ; Error List
	
	; Line operations
	$^d::EpicStudio.deleteLinePreservingClipboard()
	^l:: EpicStudio.duplicateLine()
	
	; Treat ^Enter the same as Enter - I never want to insert a line before the current one.
	^Enter::Send, {Enter}
	
	; Copy current code location
	!c:: EpicStudio.copyCleanCodeLocation()  ; Cleaned, just the actual location
	!#c::EpicStudio.copyLinkedCodeLocation() ; RTF location with link.
	
	; Link routine to currently open DLG in EMC2.
	^+l::EpicStudio.linkRoutineToCurrentDLG()
	
	; Generate and insert snippets
	:X:.snip::MSnippets.insertSnippet()
	
	; Tiny snippet to either add something in the middle
	::.qsplit:: ; Variable in the middle of a string
		Send, % """__"""
		Send, {Left 2}
	return
	::.split:: ; String in the middle of two variables
		Send, % "_""""_"
		Send, {Left 2}
	return
	
	; Debug code strings
	:X:gdblog::   ClipboardLib.send(Config.private["M_DEBUG_LOG"])
	:X:gdbbreak:: ClipboardLib.send(Config.private["M_DEBUG_BREAK"])
	:X:gdbpbreak::ClipboardLib.send(Config.private["M_DEBUG_BREAK_PATIENT"])
	:X:gdbsnap::  ClipboardLib.send(Config.private["M_DEBUG_SNAP_START"])
	
	; Debug, auto-search for workstation ID.
	~F5::EpicStudio.runDebug("WORKSTATION")
	F6::
		Send, {F5}
		EpicStudio.runDebug("USER")
	return

; Debug window
#If Config.isWindowActive("EpicStudio Attach to Process")
	; Search presets (match debug-launching ones above)
	F5::EpicStudio.doDebugSearch("WORKSTATION")
	F6::EpicStudio.doDebugSearch("USER")
#If
