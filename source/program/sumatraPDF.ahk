#IfWinActive, ahk_class SUMATRA_PDF_FRAME
	; Bookmarks panel.
	^b::Send, {F12}

	; Vim-like navigation.
	$`;::sendUnlessControlFocused("{PgDn}", "Edit2")
	$p::sendUnlessControlFocused("{PgUp}", "Edit2")
	sendUnlessControlFocused(keysToSend, unlessControl) {
		ControlGetFocus, currControl
		if(currControl != unlessControl)
			Send, % keysToSend
		else
			Send, % A_ThisHotkey
	}

	; Show/hide toolbar.
	^/::
		Send, !v
		Sleep, 100
		Send, t
	return

	; Want to close on Esc, but also just unfocus controls at top if focused.
	Escape::
		sendEscapeToSumatra() {
			ControlGetFocus, currControl, A
			if(currControl = "Edit1")
				Send, {Tab 2}
			else if(currControl = "Edit2")
				Send, {Tab}
			else
				WinClose
		}

	; Kill unconventional hotkey to quit.
	^q::return
	
	; Find forward/back.
	^g::F3
	^+g::+F3
	
	; Save as is Ctrl+S
	^+s::Send, ^s
#IfWinActive
