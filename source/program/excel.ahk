; Excel hotkeys.
#IfWinActive, ahk_class XLMAIN
	; Auto-fix column width 
	^+w::
		Send, !h
		Send, o
		Send, i
	return

	; Insert/delete row
	^=::
		Send, ^+= 		; Insert row
		Send, !r 		; Shift down entire row
		Send, {Enter} 	; Accept popup
	return
	$^-::
		Send, ^- 		; Delete row
		Send, !r 		; Shift down entire row
		Send, {Enter} 	; Accept popup
	return

	; Next/previous worksheet
	^Tab::^PgDn
	^+Tab:: ; Have to make sure the shift gets released (not blind mode like the above one).
		Send, ^{PgUp}
	return
#IfWinActive
