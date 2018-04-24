#IfWinActive, ahk_class Notepad++
	; New document.
	^t::^n
	
	; Re-open last closed document.
	^+t::
		Send, !f
		Send, 1
	return
	
	!+x::return
	
	::dbpop::
		SendRaw, DEBUG.popup(") ; ending quote for syntax highlighting: "
		Send, {Left} ; Get inside parens
	return
	
	; Function header
	::`;`;`;::
		headerText = 
		( RTrim0
		;---------
		; DESCRIPTION:    
		; PARAMETERS:
		;  paramName (I/O/IO,REQ/OPT) - 
		; RETURNS:        
		; SIDE EFFECTS:   
		; NOTES:          
		;---------
		)
		SendRaw, % headerText
	return
#IfWinActive
