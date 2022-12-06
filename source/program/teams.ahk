#If Config.isWindowActive("Teams")
	!a:: Send, ^+m ; Toggle mute
	!z:: Send, ^+o ; Toggle video
	!o:: Send, ^,  ; Settings
	^+/::Send, ^.  ; Show hotkeys
	^+c::copyCondensedTeamsConversation()
#If

;---------
; DESCRIPTION:    Take messages copied from Teams, condense them, and put them back on the clipboard.
;---------
copyCondensedTeamsConversation() {
	clipboard := getCondensedTeamsConversation(SelectLib.getText())
	Toast.ShowMedium("Clipboard set to condensed Teams conversation")
}

;---------
; DESCRIPTION:    Take messages copied from Teams and condense them into a more compact form for saving off.
; PARAMETERS:
;  messages (I,REQ) - Full copied text of the messages
; RETURNS:        New string in this format (with messages from the same person being combined under one sender name header):
;                 	senderName
;                 		message1Text
;                 		message2Text
;---------
getCondensedTeamsConversation(messages) {
	conversation := ""

	For _, message in condenseTeamsMessagesBySender(messages) {
		conversation := conversation.appendLine(message.sender)
		
		text := "`t" message.text.replace("`n", "`n`t") ; Indent every line of the message
		conversation := conversation.appendLine(text)
	}

	return conversation
}

;---------
; DESCRIPTION:    Parse a bunch of copied Teams messages into discrete blocks, divided up by sender name.
; PARAMETERS:
;  messages (I,REQ) - Full copied text of the messages
; RETURNS:        Array of message objects: {sender, text}
;---------
condenseTeamsMessagesBySender(messages) {
	condensedMessages := []
	newline := "`r`n"

	For _, message in messages.split([newline newline "["], newline) {
		sender := message.firstLine().afterString("] ")
		text := message.afterString(newline)
		text := text.removeRegEx("`r`n( (like|heart|laugh|surprised|sad|angry) \d+)+$") ; Remove reactions line (at the bottom of a message)
		text := text.replace(newline newline, newline) ; Drop extra newlines

		previousMessage := condensedMessages.last()
		if(previousMessage.sender = sender) {
			previousMessage.text := previousMessage.text.appendLine(text)
		} else {
			condensedMessages.push( {sender:sender, text:text} )
		}
	}

	return condensedMessages
}