; Word hotkeys.
#IfWinActive, ahk_class OpusApp
	; Save as
	^+s::Send, {F12}
	
	; Find next/previous
	^g::Send, ^{PgDn}
	^+g::Send, ^{PgUp}
	
	; Apply bullets
	^.::^+l
	
	; Jump to next *** token and select it.
	F2::
		Send, ^g    ; Find/replace popup (Go To tab)
		Send, !d    ; Find tab
		Send, !n    ; Focus "Find what" field
		Send, ***   ; String to search for
		Send, !m    ; More button (show search options)
		Send, !:    ; Focus "Search" (direction) dropdown
		Send, A     ; Search "All"
		Send, !l    ; Less button (hide search options, so More button is there next time we come through too)
		Send, !f    ; Find next
		Send, {Esc} ; Get out of the find popup/navigation pane
		
		; If the find popup is still open (presumably because we hit the "finished searching" popup), close it.
		if(WinActive("Find and Replace"))
			Send, {Esc}   ; Close the popup
	return
	
	; Make line movement alt + up/down instead of alt + shift + up/down to match notepad++ and ES.
	!Up::  Send, !+{Up}
	!Down::Send, !+{Down}
#IfWinActive
