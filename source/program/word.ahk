; Word hotkeys.
#IfWinActive, ahk_class OpusApp

; ; Draw line
; ^+l::
	; MouseGetPos, xPrevi, yPrevi
	; Click down, 55, 85
	; Sleep, 500
	; Click up, 55, 85
	; MouseMove, xPrevi, yPrevi
; return

; Save as, ctrl shift s.
^+s::
	Send !fa
return

; Open last opened docs: continues after first, thru 9th.
^+t::
	Send !f
	Send {%incrementor%}
	incrementor+=1
	if (CurrentSetting >= 10)
		incrementor = 1
return

#IfWinActive
