#If Config.isWindowActive("Telegram")
	Up::return   ; Block quoting behavior by default (Ctrl+Up still works fine)
	^t::Telegram.focusNormalChat() ; Focus normal chat.
#If