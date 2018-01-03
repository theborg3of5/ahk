#IfWinActive, ahk_class SUMATRA_PDF_FRAME
	; Bookmarks panel.
	^b::Send, {F12}

	; Vim-like navigation.
	$`;::
		ControlGetFocus, currControl
		if(currControl != "Edit2")
			Send, {PgDn}
		else
			Send, `;
	return
	$p::
		ControlGetFocus, currControl
		if(currControl != "Edit2")
			Send, {PgUp}
		else
			Send, p
	return

	; Show/hide toolbar.
	^/::
		Send, !v
		Sleep, 100
		Send, t
	return

	; Show/hide favorites.
	$F11::
	^e::
		Send, !a
		Sleep, 100
		Send, {Down 2}
		Send, {Enter}
	return

	; Retain fullscreening ability.
	!Enter::
		Send, {F11}
	return

	; Want to close on Esc, but also just unfocus controls at top if focused.
	Escape::
		ControlGetFocus, currControl, A
		if(currControl = "Edit1")
			Send, {Tab 2}
		else if(currControl = "Edit2")
			Send, {Tab}
		else
			WinClose
	return

	; Kill unconventional hotkey to quit.
	^q::return
	
	; Find forward/back.
	^g::F3
	^+g::+F3
	
	; Save as is Ctrl+S
	^+s::Send, ^s
#IfWinActive
