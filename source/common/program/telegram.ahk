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
		Send, ^1
	}
	
	
	; #PRIVATE#
	
	static ShareURLBase := "tg://msg_url?url=<URL>" ; Shares the given URL to telegram desktop, prompting you to pick a chat.
	; #END#
}
