; Google Chrome hotkeys.
#IfWinActive, ahk_exe chrome.exe
	; Options hotkey.
	!o::
		Send, !e
		Sleep, 100
		Send, s
	return
	
	; Copy title, stripping off the " - Google Chrome" at the end.
	!c::
		WinGetActiveTitle, title
		
		ending := " - Google Chrome"
		titleLen  := strLen(title)
		endingLen := strLen(ending)
		if(subStr(title, titleLen - endingLen + 1) = ending)
			title := subStr(title, 1, titleLen - endingLen)
		
		clipboard := title
	return
#IfWinActive
