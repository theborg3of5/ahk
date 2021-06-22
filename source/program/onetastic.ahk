#If Config.isWindowActive("Onetastic Macro Editor")
	; Insert "empty" (comment) line
	^Enter::
		Send, !Q ; Insert comment 
		Send, {Enter} ; Edit comment text
		WinWaitActive, Comment Editor
		Send, {Delete}{Enter}
	return
	
	; Comment out selected lines
	^`;::
		commandLines := ClipboardLib.getWithHotkey("^c")
		numNewlines := commandLines.removeFromEnd("`n").countMatches("`n") ; Figure out how many lines are in the selection, ignoring the trailing newline
		Send, !Q ; Insert comment
		Send, {Up} ; Get back into previously-selected block
		Send, {Shift Down}{Up %numNewlines%}{Shift Up} ; Reselect the original block
		Send, ^{Down} ; Move lines down once, which should put them under out new comment line
	return
	
	; Move line up/down
	!Up::  Send, ^{Up}
	!Down::Send, ^{Down}
	
	; Collapse/expand
	!Left:: Send, ^{Left}
	!Right::Send, ^{Right}
	
	; New macro function
	^n::^NumpadAdd
	
	; Import
	^i::Send, !fp ; File > Import
	
	; Delete macro
	^d::Send, !fd ; File > Delete
	
	; Open function header edit window
	^e::^F2
	
	; Open XML window
	^+o::Onetastic.openEditXMLPopup()
	
	; Copy/set current function XML
	^+x::Onetastic.copyCurrentXML()
#If
