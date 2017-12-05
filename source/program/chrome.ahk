; Google Chrome hotkeys.
#IfWinActive, ahk_class Chrome_WidgetWin_1
	; Options hotkey.
	!o::
		Send, !e
		Sleep, 100
		Send, s
	return
#IfWinActive
