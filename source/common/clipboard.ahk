; Clipboard-related functions.

copyWithHotkey(hotkeyKeys) {
	if(hotkeyKeys = "")
		return
	
	clipboard := "" ; Clear the clipboard so we can wait for it to actually be set
	Send, % hotkeyKeys
	ClipWait, 0.5 ; Wait for the minimum time (0.5 seconds) for the clipboard to contain the new info.
}
copyFilePathWithHotkey(hotkeyKeys) {
	copyWithHotkey(hotkeyKeys)
	
	path := clipboard
	if(path) {
		path := cleanupPath(path)
		path := mapPath(path)
	}
	
	setClipboardAndToast(path, "file path")
}
copyFolderPathWithHotkey(hotkeyKeys) {
	copyWithHotkey(hotkeyKeys)
	
	path := clipboard
	if(path) {
		path := cleanupPath(path)
		path := mapPath(path)
		path := appendCharIfMissing(path, "\") ; Add the trailing backslash since it's a folder
	}
	
	setClipboardAndToast(path, "folder path")
}

; Sends the selected text using the clipboard, fixing the clipboard as it finishes.
sendTextWithClipboard(text) {
	; DEBUG.popup("Text to send with clipboard", text)
	
	originalClipboard := clipboardAll ; Save the entire clipboard to a variable of your choice.
	clipboard := ""                   ; Clear the clipboard
	
	clipboard := text
	ClipWait, 0.5                     ; Wait for clipboard to contain the data we put in it (minimum time).
	Send, ^v
	Sleep, 100
	
	clipboard := originalClipboard    ; Restore the original clipboard. Note we're using clipboard (not clipboardAll).
}

setClipboardAndToast(newClipboardValue, clipLabel := "value", extraPreMessage := "") {
	clipboard := "" ; Clear the clipboard so we can wait for it to actually be set
	
	clipboard := newClipboardValue
	ClipWait, 2 ; Wait for 2 seconds for the clipboard to contain data.
	
	toastClipboardContents(clipLabel, extraPreMessage)
}
toastClipboardContents(clipLabel := "value", extraPreMessage := "") {
	if(clipLabel = "")
		clipLabel := "value"
	if(extraPreMessage != "")
		extraPreMessage .= "`n"
	
	if(clipboard = "")
		Toast.showMedium(extraPreMessage "Failed to get " clipLabel)
	else
		Toast.showMedium(extraPreMessage "Clipboard set to " clipLabel ":`n" clipboard)
}
