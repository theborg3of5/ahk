; Google Chrome hotkeys.
#IfWinActive, ahk_exe chrome.exe
	; Options hotkey.
	!o::
		Send, !e
		Sleep, 100
		Send, s
	return
#IfWinActive
