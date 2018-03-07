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
		clipboard := removeStringFromEnd(title, " - Google Chrome")
	return
#IfWinActive
	
#If WinActive("ahk_exe chrome.exe") && MainConfig.isMachine(MACHINE_EpicLaptop)
	^+o::
		tag := cleanupText(getFirstLineOfSelectedText())
		
		WinGetActiveTitle, title
		title := removeStringFromEnd(title, " - Google Chrome")
		titleAry := strSplit(title, "/")
		routine := titleAry[1]
		if(!routine)
			return
		
		openEpicStudioRoutine(routine, tag)
	return
#If
