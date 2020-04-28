#If Config.isWindowActive("OneTastic Macro Editor")
	; Insert statement hotkeys
	^`;::!6 ; Insert comment 
	
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
