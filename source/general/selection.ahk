; Actions taken using the currently-selected text.

; Search
!+f::SearchLib.selectedTextPrompt()

; Turn the selected text into a link to the URL on the clipboard.
^+k::
	linkSelectedText() {
		HotkeyLib.waitForRelease()
		if(!Hyperlinker.linkSelectedText(Clipboard, errorMessage))
			new ErrorToast("Failed to link selected text", errorMessage).showMedium()
	}

; Open - open a variety of different things based on the selected text.
^!#o::  new ActionObject(SelectLib.getText()).openWeb()
^!#+o:: new ActionObject(SelectLib.getText()).openEdit()

; Copy link - copy links to a variety of different things based on the selected text.
^!#l:: new ActionObject(SelectLib.getText()).copyLinkWeb()
^!#+l::new ActionObject(SelectLib.getText()).copyLinkEdit()

; Hyperlink - get link based on the selected text and then apply it to that same text.
^!#k::  new ActionObject(SelectLib.getText()).linkSelectedTextWeb()
^!#+k:: new ActionObject(SelectLib.getText()).linkSelectedTextEdit()

; Grab the selected text and pop it into a new Notepad window
!v::
	putSelectedTextIntoNewNotepadWindow() {
		selectedText := SelectLib.getText()
		if(selectedText = "")
			return
		
		Notepad.openNewInstanceWithText(selectedText)
	}
