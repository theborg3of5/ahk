; Word hotkeys.
#IfWinActive, ahk_class OpusApp
	; Open (dialog, not screen)
	^o::Send, ^!{F2}
	
	; Save as
	^+s::Send, {F12}
	
	; Find next/previous
	^g::Send, ^{PgDn}
	^+g::Send, ^{PgUp}
	
	; Apply bullets
	^.::^+l
	
	; Strikethrough
	^-::
		Send, !h
		Send, 4
	return
	
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
	
	; Expand/collapse headings
	!Right::
		Send, {AppsKey}
		Send, e       ; Expand / Collapse
		Send, {Right} ; In case menu didn't expand because there was another E menu item
		Send, e       ; Expand Heading
		Sleep, 100
		if(WinActive("ahk_class Net UI Tool Window ahk_exe WINWORD.EXE")) ; Right-click menu still open, as header was already expanded
			Send, {Esc 2}
	return
	!Left::
		Send, {AppsKey}
		Send, e       ; Expand / Collapse
		Send, {Right} ; In case menu didn't expand because there was another E menu item
		Send, c       ; Collapse Heading
		Sleep, 100
		if(WinActive("ahk_class Net UI Tool Window ahk_exe WINWORD.EXE")) ; Right-click menu still open, as header was already collapsed
			Send, {Esc 2}
	return
#IfWinActive
