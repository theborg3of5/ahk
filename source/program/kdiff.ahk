#IfWinActive, ahk_exe kdiff3.exe
	; Hotkey to toggle line wrapping.
	^+w::
		Send, !i
		Send, {Up 3}
		Send, {Enter}
	return
	
	; Split diff
	^q::
		KeyWait, Ctrl
		Send, {Alt}
		Send, {Left 4}{Down}
		Send, {Up 3}
		Send, {Enter}
	return
#IfWinActive
