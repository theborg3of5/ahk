; Hotkeys for getting/sending and manipulating text.

; Select all with special per-window handling.
$^a::WindowActions.selectAll()

; Backspace shortcut for those that don't handle it well.
$^Backspace::WindowActions.deleteWord()

^!v::
	HotkeyLib.waitForRelease()
	Send, {Text}%Clipboard%
return

; Turn the selected text into a link to the URL on the clipboard.
^+k::
	linkSelectedText() {
		HotkeyLib.waitForRelease()
		if(!Hyperlinker.linkSelectedText(Clipboard, errorMessage))
			new ErrorToast("Failed to link selected text", errorMessage).showMedium()
	}
	
; Send a (newline-separated) text/URL combo from the clipboard as a link.
^+#k::
	sendLinkedTextFromClipboard() {
		HotkeyLib.waitForRelease()
		text := Clipboard.beforeString("`n")
		url  := Clipboard.afterString("`n")
		
		; Send and select the text
		ClipboardLib.send(text)
		textLen := text.length()
		Send, {Shift Down}{Left %textLen%}{Shift Up}
		
		if(!Hyperlinker.linkSelectedText(url, errorMessage))
			new ErrorToast("Failed to link text", errorMessage).showMedium()
	}

; Turn clipboard into standard string and send it.
!+n::
	sendStandardEMC2ObjectString() {
		HotkeyLib.waitForRelease()
		ao := new ActionObjectEMC2(Clipboard)
		ClipboardLib.send(ao.standardEMC2String) ; Can contain hotkey chars
		
		; Special case for OneNote: link the INI/ID as well.
		if(Config.isWindowActive("OneNote"))
			OneNote.linkEMC2ObjectInLine(ao.ini, ao.id)
	}

; Send the clipboard as a list.
^#v::new FormattedList(Clipboard).sendList()

; Grab the selected text and pop it into a new Notepad window
!v::
	putSelectedTextIntoNewNotepadWindow() {
		selectedText := SelectLib.getText()
		if(selectedText = "")
			return
		
		LaunchLib.openNewNotepadWithText(selectedText)
	}