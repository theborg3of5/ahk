; Actions taken using the currently-selected text.

; Search
!+f::SearchLib.selectedTextPrompt()

; Turn the selected text into a link to the URL on the clipboard.
^+k::
	linkSelectedText() {
		HotkeyLib.waitForRelease()
		if(!Hyperlinker.linkSelectedText(Clipboard, errorMessage))
			Toast.ShowError("Failed to link selected text", errorMessage)
	}

; Open - open a variety of different things based on the selected text.
^!#o:: new ActionObject(SelectLib.getText()).openWeb()
^!#+o::new ActionObject(SelectLib.getText()).openEdit()
#o::   new ActionObject(SelectLib.getText()).openWeb()  ; Work keyboard blocks everything with #!o, so here are some alternatives.
#+o::  new ActionObject(SelectLib.getText()).openEdit() 


; Copy link - copy links to a variety of different things based on the selected text.
^!#l:: new ActionObject(SelectLib.getText()).copyLinkWeb()
^!#+l::new ActionObject(SelectLib.getText()).copyLinkEdit()

; Hyperlink - get link based on the selected text and then apply it to that same text.
^!#k:: new ActionObject(SelectLib.getText()).linkSelectedTextWeb()
^!#+k::new ActionObject(SelectLib.getText()).linkSelectedTextEdit()

; Grab the selected text and pop it into a new Notepad++ window
!#v::
	selectedTextToNotepad() {
		; Check physical state so we can tell the difference between the keys being pressed vs. sent by keyboard macros.
		if(!GetKeyState("v", "P"))
			return
		
		; Get the selected text to use
		selectedText := SelectLib.getText()
		if(selectedText = "")
			return

		; Open it up in Notepad++
		NotepadPlusPlus.openTempText(selectedText)
	}
