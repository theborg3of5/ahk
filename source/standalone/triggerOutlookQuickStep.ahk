; Send a specific media key, to be executed by external program (like Microsoft keyboard special keys).
#NoTrayIcon

; Run in Outlook only.
if(!WinActive("ahk_class rctrl_renwnd32"))
	ExitApp

quickStepNumber = %1% ; Input from command line
if(!quickStepNumber)
	ExitApp
	
Send, ^+%quickStepNumber%
