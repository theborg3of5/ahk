; Word hotkeys.
#IfWinActive, ahk_class OpusApp
	; Save as, ctrl shift s.
	^+s::
		Send !fa
	return
#IfWinActive
