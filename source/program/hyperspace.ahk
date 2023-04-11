; Hyperspace main window
#If Hyperspace.isAnyVersionActive()
	$F5::+F5 ; Make F5 work everywhere by mapping it to shift + F5.
	^+t::Hyperspace.login(Config.private["WORK_ID"], Config.private["WORK_PASSWORD"]) ; Login
	^!c::Hyperspace.openCurrentDisplayHTML() ; Open the current display's HTML in IE.
#If

; HSWeb debugging - Hyperspace main window or IE
#If Hyperspace.isAnyVersionActive() || WinActive("Hyperspace ahk_exe IEXPLORE.EXE") || WinActive("Hyperspace ahk_exe chrome.exe")
	^+!c::Send, % Config.private["EPIC_HSWEB_CONSOLE_HOTKEY"]
#If
