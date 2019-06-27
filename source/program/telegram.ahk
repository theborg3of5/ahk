#If MainConfig.isWindowActive("Telegram")
	; Up::return   ; Block quoting behavior by default (Ctrl+Up still works fine)
	`::Send, {Esc} ; Escape closes the window, so add another hotkey to duplicate the functionality (get rid of quoting stuff)
	^t::Telegram.focusNormalChat() ; Focus normal chat.
#If

class Telegram {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	;---------
	; DESCRIPTION:    Focus the "Normal" chat that's the only one I use in Telegram.
	;---------
	focusNormalChat() {
		Send, {Down}{Enter}
	}
}