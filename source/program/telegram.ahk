#If MainConfig.isWindowActive("Telegram")
	Up::return
	`::
		Send, {Esc}
	return
	
	; Focus normal chat.
	^t::telegramFocusNormalChat()
#If

telegramFocusNormalChat() {
	Send, {Down}{Enter}
}