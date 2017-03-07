; Excel hotkeys.
#IfWinActive, ahk_class XLMAIN
	; Auto-fix column width 
	^+w::
		autoFixColumnWidth()
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
	
	; Filter and format table nicely.
	^+b::
		Send, ^a
		Send, ^a
		
		Send, !at      ; Filter
		
		autoFixColumnWidth()
		
		Send, ^{Home}  ; Get back to top-left cell
		Send, +{Space} ; Select whole row
		Send, ^b       ; Bold it
		Send, !wfr		; Freeze top row
	return
	
	autoFixColumnWidth() {
		Send, !h
		Send, o
		Send, i
	}
	
#IfWinActive
