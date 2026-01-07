; Hotkeys for getting/sending and manipulating text.

; Populate the clipboard from an input box.
!v::
	setClipboard() {
		text := InputBox("Set clipboard", "Enter text to set the clipboard to:")
		if (text)
			ClipboardLib.setAndToast(text, "value")
	}

; Send clipboard as plain text.
^!v::
	sendUnwrappedPlainText() {
		HotkeyLib.waitForRelease()

		newText := Clipboard

		; Unwrap by replacing all newlines with spaces
		newText := newText.replace("`r`n"," ")
		newText := newText.replace("`r"," ")
		newText := newText.replace("`n"," ")

		; Reduce multiple spaces to singles
		while(newText.contains("  "))
			newText := newText.replace("  ", " ")

		; Drop leading/trailing spaces
		newText := newText.withoutWhitespace()

		Send, {Text}%newText%
	}
	
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
