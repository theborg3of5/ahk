; Hotkeys for getting/sending and manipulating text.

; Send clipboard as plain text.
^!v::
	HotkeyLib.waitForRelease()
	Send, {Text}%Clipboard%
return
	
; Send a (newline-separated) text/URL combo from the clipboard as a link.
^+#k::
	sendLinkedTextFromClipboard() {
		HotkeyLib.waitForRelease()
		
		value := clipboard.replace("`r`n", "`n") ; Replace `r`n with just `n to avoid counting/highlighting mishaps
		text := value.beforeString("`n")
		url  := value.afterString("`n")
		
		; Send and select the text
		ClipboardLib.send(text)
		textLen := text.length()
		Send, {Shift Down}{Left %textLen%}{Shift Up}
		
		if(!Hyperlinker.linkSelectedText(url, errorMessage))
			Toast.ShowError("Failed to link text", errorMessage)
	}

; Send the clipboard as a list.
^#v::new FormattedList(Clipboard).sendList()

; Send specific symbols
#`;::
	selectSymbols() {
		symbols := new Selector("symbols.tls").promptMulti("CHAR")
		For _, symbol in symbols
			Send, % symbol
	}
