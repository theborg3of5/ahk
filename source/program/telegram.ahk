#If getWindowSetting("NAME") = "Telegram"
	Up::return
	`::
		Send, {Esc}
	return
	
	; Focus normal chat.
	^t::telegramFocusNormalChat()
	
	; Avoid ":p" triggering praying emoji by adding a space.
	:::p::
		Send, :p{Space}
	return
#If

telegramFocusNormalChat() {
	Send, {Down}{Down}{Enter}
}