﻿
; Hotkeys for opening a pidgin chat window with specific users
#+m::pidginMessageToUser(mikalAddress)

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
	Run, % BorgConfig.getProgram("Pidgin", "PATH") " --protocolhandler=xmpp:" user "?message"
}
