; EpicStudio hotkeys and helpers.
#If Config.isWindowActive("EpicStudio")
	; Remap some of the tools to get easier access to those I use often.
	!1::!3 ; EZParse
	!2::!4 ; MBuilderES
	!3::!6 ; Error List
	
	; Line operations
	$^d::EpicStudio.deleteLine()
	^l:: EpicStudio.duplicateLine()
	
	; Treat ^Enter the same as Enter - I never want to insert a line before the current one.
	^Enter::Send, {Enter}

	; Use subword navigation with !#left/right, and keep !left/right for history navigation.
	!Left::Send, ^+-
	!Right::Send, ^+=
	^#Left::Send, !{Left}
	^#Right::Send, !{Right}
	
	; Copy current code location
	!c:: EpicStudio.copyCleanCodeLocation()  ; Cleaned, just the actual location
	!#c::EpicStudio.copyLinkedCodeLocation() ; RTF location with link.
	
	; Link routine to currently open DLG in EMC2.
	^+l::EpicStudio.linkRoutineToCurrentDLG()
	
	; Take DLG # and stick it into MBuilder linting.
	^+m::MBuilder.lintCurrentDLG()

	; Generate and insert snippets
	:X:.snip::MSnippets.insertSnippet()

	; Fix typos that EpicStudio handles badly
	:*0:d QUIT::d  QUIT
	:*0:d q::d  q

	; Turn an old name line into a scope line.
	:X:.scope::EpicStudio.fixNameScope()
	
	; Tiny snippet to insert a string or variable (with linking _s) in the middle of something
	::.qsplit:: ; Variable in the middle of a string
	::.qs::
		Send, % """__"""
		Send, {Left 2}
	return
	::.split:: ; String in the middle of two variables
		Send, % "_""""_"
		Send, {Left 2}
	return

	; Tag-length-measuring tens string.
	::.taglen::
		Send, {End}{Home 2} ; Get to very start of line (before indent)
		Send, {Shift Down}{End}{Shift Up} ; Select entire line
		if(SelectLib.getCleanFirstLine())
			Send, {Delete} ; Delete the contents (only needed if the line isn't completely empty, otherwise we lose the newline)
		Send, % "`t; " StringLib.getTenString(31).removeFromStart("123456") ; First 6 chars are the tab (width=4), semicolon, and space.
	return

	; Contact comment, but also include the REVISIONS: header.
	^+8::EpicStudio.insertContactCommentWithHeader()
	
	; Comment "borders" that are sized to match the current line (plus 1 extra overhang)
	^-::EpicStudio.wrapLineInCommentBorder("-")
	^=::EpicStudio.wrapLineInCommentBorder("=")
	
	; Debug code strings
	:X:gdblog::   ClipboardLib.send(Config.private["M_DEBUG_LOG"])
	:X:dbpop::    ClipboardLib.send(Config.private["M_DEBUG_LOG"])
	:X:gdbbreak:: ClipboardLib.send(Config.private["M_DEBUG_BREAK"])
	:X:gdbpbreak::ClipboardLib.send(Config.private["M_DEBUG_BREAK_PATIENT"])
	:X:gdbsnap::  ClipboardLib.send(Config.private["M_DEBUG_SNAP_START"])
	:X:.clip::    ClipboardLib.send(EpicStudio.getClipboardAsMString())

	; Redo the indentation for the selected documentation lines
	^+Enter::new HeaderDocBlock().rewrapSelection(EpicStudio.TabWidth)
	
	; Debug, auto-search for workstation ID.
	~F5::EpicStudio.launchDebug()

; Debug popup
#If Config.isWindowActive("EpicStudio Debug Window")
	F5::EpicStudio.runDebugSearch()
#If
