#If Config.isWindowActive("Telegram")
	Up::return   ; Block quoting behavior by default (Ctrl+Up still works fine)
	`::Send, {Esc} ; Escape closes the window, so add another hotkey to duplicate the functionality (get rid of quoting stuff)
	^t::Telegram.focusNormalChat() ; Focus normal chat.
#If

class Telegram {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Share the provided URL to Telegram and focus the normal chat.
	; PARAMETERS:
	;  url (I,REQ) - The URL to share.
	;---------
	shareURL(url) {
		launchURL := this.ShareURLBase.replaceTag("URL", url)
		Run(launchURL)
		
		WinWaitActive, % Config.windowInfo["Telegram"].titleString
		
		Telegram.focusNormalChat()
	}
	
	
	; #INTERNAL#
	
	;---------
	; DESCRIPTION:    Focus the "Normal" chat that's the only one I use in Telegram.
	;---------
	focusNormalChat() {
		Send, {Down}{Enter}
	}
	
	
	; #PRIVATE#
	
	static ShareURLBase := "tg://msg_url?url=<URL>" ; Shares the given URL to telegram desktop, prompting you to pick a chat.
	; #END#
}
