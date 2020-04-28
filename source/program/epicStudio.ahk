; EpicStudio hotkeys and helpers.
#If Config.isWindowActive("EpicStudio")
	; Remap some of the tools to get easier access to those I use often.
	!1::!3 ; EZParse
	!2::!5 ; Error List
	!3::!6 ; Call Hierarchy
	!4::!8 ; Item expert
	
	; Line operations
	$^d::EpicStudio.deleteLinePreservingClipboard()
	^l::EpicStudio.duplicateLine()
	
	; Treat ^Enter the same as Enter - I never want to insert a line before the current one.
	^Enter::Send, {Enter}
	
	; Copy current code location
	!c:: EpicStudio.copyCleanCodeLocation()  ; Cleaned, just the actual location
	!#c::EpicStudio.copyLinkedCodeLocation() ; RTF location with link.
	
	; Link routine to currently open DLG in EMC2.
	^+l::EpicStudio.linkRoutineToCurrentDLG()
	
	; Generate and insert snippet
	:X:.snip::MSnippets.insertSnippet()
	
	; Debug, auto-search for workstation ID.
	~F5::EpicStudio.runDebug("ws:" Config.private["WORK_COMPUTER_NAME"])
	F6::
		Send, {F5}
		EpicStudio.runDebug("user:" Config.private["WORK_USERNAME"])
	return
#If
