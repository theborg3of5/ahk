
; Unread facebook group chat windows (don't respond to ^+i correctly).
#If WinExist("* ahk_exe " MainConfig.getWindowInfo("Pidgin").exe)
	^+i::
		WinActivate, % "* ahk_exe " MainConfig.getWindowInfo("Pidgin").exe
	return
#If

#IfWinActive, Buddy List
	; Hide buddy list when active.
	^!d::
		Send, !{F4}
	return

	; Hide/show status bar.
	$^!s::
		ControlSend, gdkWindowChild14, ^!s, Buddy List
	return
#IfWinActive
