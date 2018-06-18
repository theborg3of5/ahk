#If getWindowSetting("NAME") = "Telegram"
	Up::return
	`::
		Send, {Esc}
	return
	
	; Focus normal chat.
	^t::
		Send, {Down}{Down}{Enter}
	return
	
	; Avoid ":p" triggering praying emoji by adding a space.
	:::p::
		Send, :p{Space}
	return
#If
