#If Config.isWindowActive("OneTastic Macro Editor")
	; Insert "empty" (comment) line
	^Enter::
		Send, !6 ; Insert comment 
		Send, {Enter} ; Edit comment text
		WinWaitActive, Comment Editor
		Send, {Delete}{Enter}
	return
	
	; Comment out selected lines
	^`;::
		commandLines := ClipboardLib.getWithHotkey("^c")
		numNewlines := commandLines.removeFromEnd("`n").countMatches("`n") ; Figure out how many lines are in the selection, ignoring the trailing newline
		Send, !6 ; Insert comment
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
	
	; Open macro info window
	^i::
		Send, !f ; File
		Send, i  ; Edit Macro Info...
	return
	
	; Open function header edit window
	^e::^F2
	
	; Delete current function
	^d::OneTastic.deleteCurrentFunction()
	
	; Open XML window
	^+o::OneTastic.openEditXMLPopup()
	
	; Copy/set current function XML
	^+x::OneTastic.copyCurrentXML()
	^+s::OneTastic.setCurrentXML(clipboard)
	
	; Update the current macro using the XML on the clipboard.
	^!i::OneTastic.refreshMacroFromXML(clipboard)
#If
