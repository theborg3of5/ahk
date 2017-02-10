
; Hotkeys for opening a pidgin chat window with specific users
#+m::pidginMessageToUser(mikalEmailAddress)

; Unread facebook group chat windows (don't respond to ^+i correctly).
#If WinExist("* ahk_exe " MainConfig.getProgram("Pidgin", "EXE"))
	^+i::
		WinActivate, % "* ahk_exe " MainConfig.getProgram("Pidgin", "EXE")
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

pidginMessageToUser(user) {
	Run, % MainConfig.getProgram("Pidgin", "PATH") " --protocolhandler=xmpp:" user "?message"
}
