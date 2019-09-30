; Clipboard-related functions.

copyWithHotkey(hotkeyKeys) {
	if(hotkeyKeys = "")
		return
	
	clipboard := "" ; Clear the clipboard so we can wait for it to actually be set
	Send, % hotkeyKeys
	ClipWait, 0.5 ; Wait for the minimum time (0.5 seconds) for the clipboard to contain the new info.
	
	return (ErrorLevel != 1)
}
copyWithFunction(boundFunc) {
	if(!boundFunc)
		return
	
	clipboard := "" ; Clear the clipboard so we can wait for it to actually be set
	%boundFunc%()
	ClipWait, 0.5 ; Wait for the minimum time (0.5 seconds) for the clipboard to contain the new info.
	
	return (ErrorLevel != 1)
}

copyFilePathWithHotkey(hotkeyKeys) {
	copyWithHotkey(hotkeyKeys)
	
	path := clipboard
	if(path) {
		path := cleanupPath(path)
		path := mapPath(path)
	}
	
	setClipboardAndToastValue(path, "file path")
}
copyFolderPathWithHotkey(hotkeyKeys) {
	copyWithHotkey(hotkeyKeys)
	
	path := clipboard
	if(path) {
		path := cleanupPath(path)
		path := mapPath(path)
		path := path.appendIfMissing("\") ; Add the trailing backslash since it's a folder
	}
	
	setClipboardAndToastValue(path, "folder path")
}

setClipboardAndToastState(newClipboardValue, clipLabel := "value") {
	Clip.setClipboard(newClipboardValue)
	toastNewClipboardState(clipLabel)
}
setClipboardAndToastValue(newClipboardValue, clipLabel := "value") {
	Clip.setClipboard(newClipboardValue)
	toastNewClipboardValue(clipLabel)
}
setClipboardAndToastError(newClipboardValue, clipLabel, problemMessage, errorMessage := "") {
	if(clipLabel = "")
		clipLabel := "value"
	
	Clip.setClipboard(newClipboardValue)
	new ErrorToast(problemMessage, errorMessage, "Clipboard set to " clipLabel ":`n" clipboard).showMedium()
}

toastNewClipboardState(clipLabel := "value") {
	Clip.toastClipboard(clipLabel, false)
}
toastNewClipboardValue(clipLabel := "value") {
	Clip.toastClipboard(clipLabel, true)
}

;---------
; DESCRIPTION:    Add something to the clipboard history, restoring the original clipboard value.
; PARAMETERS:
;  textToSave (I,REQ) - Text to add to the clipboard history.
;---------
addToClipboardHistory(textToSave) {
	originalClipboard := clipboardAll
	
	clipboard := textToSave
	saveCurrentClipboard()
	
	clipboard := originalClipboard
	saveCurrentClipboard()
}

;---------
; DESCRIPTION:    Force the clipboard manager to store the current value, generally useful just
;                 before you change the clipboard to something else.
;---------
saveCurrentClipboard() {
	if(Ditto) ; If the Ditto class exists we can use it to save to the clipboard with Ditto with no wait time.
		Ditto.saveCurrentClipboard()
	else ; Otherwise, just wait a second for it to register normally.
		Sleep, 1000
}

;---------
; DESCRIPTION:    Send the provided text using the clipboard, restoring the clipboard afterwards.
; PARAMETERS:
;  text (I,REQ) - The text to send.
;---------
sendTextWithClipboard(text) {
	; DEBUG.popup("Text to send with clipboard", text)
	
	originalClipboard := clipboardAll ; Save off the entire clipboard.
	clipboard := ""                   ; Clear the clipboard
	
	clipboard := text
	ClipWait, 0.5                     ; Wait for clipboard to contain the data we put in it (minimum time).
	Send, ^v
	Sleep, 100
	
	clipboard := originalClipboard    ; Restore the original clipboard. Note we're using clipboard (not clipboardAll).
}

; Clipboard-related helper functions.
class Clip { ; Would ideally be named Clipboard, but that's reserved.

; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Set the clipboard to the given value, and wait to make sure it applies before returning.
	; PARAMETERS:
	;  value (I,REQ) - Value to set.
	;---------
	setClipboard(value) {
		clipboard := "" ; Clear the clipboard so we can wait for it to actually be set
		
		clipboard := value
		ClipWait, 2 ; Wait for 2 seconds for the clipboard to contain data.
	}
	
	;---------
	; DESCRIPTION:    Show a toast for the current clipboard value.
	; PARAMETERS:
	;  clipLabel          (I,OPT) - The label to show - "Clipboard set to <clipLabel>"
	;  showClipboardValue (I,REQ) - Set to true to also include the actual value in the toast, after a
	;                               colon and newline.
	;---------
	toastClipboard(clipLabel, showClipboardValue) {
		if(clipLabel = "")
			clipLabel := "value"
		
		if(clipboard = "") {
			new ErrorToast("Failed to get " clipLabel).showMedium()
		} else {
			clipMessage := "Clipboard set to " clipLabel
			if(showClipboardValue)
				clipMessage .= ":`n" clipboard
			new Toast(clipMessage).showMedium()
		}
	}
}
