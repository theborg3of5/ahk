; Google Chrome hotkeys.
#IfWinActive, ahk_exe chrome.exe
	; Options hotkey.
	!o::
		Send, !e ; Main hamburger menu.
		Sleep, 100
		Send, s  ; Settings
	return
	
	; Extensions hotkey.
	^+e::
		Send, !e ; Main hamburger menu.
		Sleep, 100
		Send, l  ; More tools
		Send, e  ; Extensions
	return
	
	; Copy title, stripping off the " - Google Chrome" at the end.
	!c::
		copyChromeTitle() {
			title := WinGetActiveTitle()
			title := removeStringFromEnd(title, " - Google Chrome")
			
			if(MainConfig.isMachine(MACHINE_EpicLaptop)) {
				; Special handling for CodeSearch - just get the routine name, plus the current selection as the tag.
				if(stringEndsWith(title, " - CodeSearch")) {
					routine := getStringBeforeStr(title, "/")
					tag     := cleanupText(getFirstLineOfSelectedText())
					
					if(tag != "")
						title := tag "^" routine
					else
						title := routine
				}
			}
			
			setClipboardAndToast(title, "title")
		}
	
	; Send to Telegram (and pick the right chat).
	~!t::
		WinWaitActive, % MainConfig.getWindowTitleString("Telegram")
		telegramFocusNormalChat()
	return
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
