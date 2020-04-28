; Hyperspace main window
#If Hyperspace.isAnyVersionActive()
	$F5::+F5 ; Make F5 work everywhere by mapping it to shift + F5.
	
	; Login hotkeys.
	^+t::Hyperspace.login(Config.private["WORK_ID"], Config.private["WORK_PASSWORD"])
	^!t::Hyperspace.login(Config.private["WORK_ID"], Config.private["WORK_PASSWORD"], false) ; Don't use last department (=)
	
	^!c::Hyperspace.openCurrentDisplayHTML() ; Open the current display's HTML in IE.
	
	^!l::Send, ^!l ; Bypass the normal linking hotkey everywhere else, as logging out is more helpful here.
#If

; HSWeb debugging - Hyperspace main window or IE
#If Hyperspace.isAnyVersionActive() || WinActive("Hyperspace ahk_exe IEXPLORE.EXE") || WinActive("Hyperspace ahk_exe chrome.exe")
	^!d::Send, % Config.private["EPIC_HSWEB_CONSOLE_HOTKEY"]
#If

; HSWeb Debug Console
#If WinActive(Config.private["EPIC_HSWEB_CONSOLE_TITLESTRING"])
	::.trace::
		Send, % Config.private["EPIC_HSWEB_FORCE_TRACE_COMMAND"]
		Send, {Left 2} ; Get inside parens and quotes
	return
#If
