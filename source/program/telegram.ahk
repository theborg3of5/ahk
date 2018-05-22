#If getWindowSetting("NAME") = "Telegram"
	Up::return
	`::Esc
	
	; Focus normal chat.
	^t::
		Send, {Down}{Down}{Enter}
	return
#If
