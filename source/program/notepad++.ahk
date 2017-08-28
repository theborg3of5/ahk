#IfWinActive, ahk_class Notepad++
	; New document.
	^t::^n
	
	; Re-open last closed document.
	^+t::
		Send, !f
		Send, 1
	return
	
	; ; Contact comment.
	; ^+8::
		; Send, % "  `;*" 
		; Send, % initials " " getDateTime("M/yy") " - "
	; return
#IfWinActive
