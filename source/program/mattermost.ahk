#If MainConfig.isWindowActive("Mattermost")
	^k::Mattermost.insertLink()
#If

class Mattermost {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	;---------
	; DESCRIPTION:    Inserts the link on the clipboard as a link, with the selected text if there
	;                 is any (otherwise cursor will end in link text area).
	;---------
	insertLink() {
		linkText := getSelectedText()
		if(linkText) { ; Linking the selected text
			textLen := strLen(linkText)
			Send, {Left} ; Get to the start of the text
			Send, [
			Send, {Right %textLen%} ; Get to the end of the text
			Send, ]()
			Send, {Left} ; Get between the parens to add the URL.
		} else { ; Just an empty link tag
			Send, []()
			Send, {Left 3} ; Get back into the link title slot (between the brackets).
		}
	}	
}
