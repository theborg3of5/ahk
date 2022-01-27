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

; Send specific (Unicode) symbols
#`;::
	selectSymbol() {
		code := new Selector("symbols.tls").selectGui("UNICODE")
		if(code != "")
			Send, % Chr("0x" code)
	}
