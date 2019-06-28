; Unread facebook group chat windows (don't respond to ^+i correctly).
#IfWinExist, * ahk_exe pidgin.exe
	^+i::WinActivate, * ahk_exe pidgin.exe ; Focus them.
#IfWinExist
