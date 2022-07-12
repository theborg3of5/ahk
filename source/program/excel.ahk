; Excel hotkeys.
#If Config.isWindowActive("Excel")
	; Copy the current document location
	!c::
		Send, !1 ; Document location (quick access position #1, should select field)
		ClipboardLib.copyFilePathWithHotkey("^c")
	return
	
	; Save as
	^+s::Send, {F12}
	
	; Insert/delete row
	^=::
		Send, ^+= 		; Insert popup
		Send, !r 		; Entire row
		Send, {Enter} 	; Accept popup
	return
	$^-::
		Send, ^- 		; Delete popup
		Send, !r 		; Entire row
		Send, {Enter} 	; Accept popup
	return
	
	; New worksheet
	^t::Send, +{F11}
	
	; Next/previous worksheet
	^Tab::
	XButton1::
		Send, ^{PgDn}
	return
	^+Tab:: ; Have to make sure the shift gets released, so can't be basic hotkey (which acts as blind mode?).
	XButton2::
		Send, ^{PgUp}
	return
	
	; Fill down
	^+f::Send, !hfid ; Home tab > Fill > Down
	
	; Fix column widths
	^+w::Excel.autoFixColumnWidth()
	
	; Bold and freeze the first row (assumed to be a header)
	^+b::Excel.boldFreezeHeaderRow()
	
	; Filter and format table nicely.
	!b::
		Send, ^a^a ; Select All (twice to get everything)
		Send, !at  ; Data tab > Filter
		Excel.boldFreezeHeaderRow()
		Excel.autoFixColumnWidth()
	return
#If
