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
		copyChromeTitle() {
			title := WinGetActiveTitle()
			clipboard := removeStringFromEnd(title, " - Google Chrome")
		}
#IfWinActive
	
#If WinActive("ahk_exe chrome.exe") && MainConfig.isMachine(MACHINE_EpicLaptop)
	^+o::
		openEpicStudioRoutineFromCodesearch() {
			tag := cleanupText(getFirstLineOfSelectedText())
			
			title := WinGetActiveTitle()
			title := removeStringFromEnd(title, " - Google Chrome")
			titleAry := strSplit(title, "/")
			routine := titleAry[1]
			if(!routine)
				return
			
			openEpicStudioRoutine(routine, tag)
		}
#If
