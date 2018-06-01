#If getWindowSetting("NAME") = "Telegram"
	Up::return
	`::
		Send, {Esc}
	return
	
	; Focus normal chat.
	^t::
		Send, {Down}{Down}{Enter}
	return
#If
