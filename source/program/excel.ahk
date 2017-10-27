; Excel hotkeys.
#IfWinActive, ahk_class XLMAIN
	; Auto-fix column width 
	^+w::
		autoFixColumnWidth()
	return
	
	^+b::
		boldFreezeHeaderRow()
	return
	
	; Save as
	^+s::
		Send, {F12}
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
	^Tab::
	XButton1::
		Send, ^{PgDn}
	return
	^+Tab:: ; Have to make sure the shift gets released, so can't be basic hotkey (which acts as blind mode?).
	XButton2::
		Send, ^{PgUp}
	return
	
	; Autosum
	^!s::
		Sleep, 200
		Send, !hus
	return
	
	; Unfreeze everything (when something frozen)
	^+f::
		Send, !wff
	return
	
	; Filter and format table nicely.
	!b::
		Send, ^a	      ; Select
		Send, ^a			; All
		
		Send, !at      ; Filter
		
		boldFreezeHeaderRow()
		autoFixColumnWidth()
	return
	
	autoFixColumnWidth() {
		Send, ^a
		Send, ^a
		Send, !h
		Send, o
		Send, i
	}
	
	boldFreezeHeaderRow() {
		Send, ^{Home}  ; Get back to top-left cell
		Send, +{Space} ; Select whole row
		Send, ^b       ; Bold it
		Send, !wfr		; Freeze top row
	}
	
#IfWinActive
