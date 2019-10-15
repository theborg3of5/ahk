; Clipboard-related functions.

;---------
; DESCRIPTION:    Wrapper for different copy hotkeys, that ensures we actually copy something (and
;                 wait long enough for it to actually be on the clipboard).
; PARAMETERS:
;  hotkeyKeys (I,REQ) - The keys to send in order to copy something to the clipboard.
; RETURNS:        true if we successfully copied something, false otherwise.
;---------
copyWithHotkey(hotkeyKeys) {
	if(hotkeyKeys = "")
		return
	
	clipboard := "" ; Clear the clipboard so we can wait for it to actually be set
	Send, % hotkeyKeys
	ClipWait, 0.5 ; Wait for the minimum time (0.5 seconds) for the clipboard to contain the new info.
	
	return (ErrorLevel != 1)
}
;---------
; DESCRIPTION:    Copy something using the provided functor object, but make sure that we actually
;                 get something on the clipboard.
; PARAMETERS:
;  boundFunc (I,REQ) - Functor object to run in order to copy something to the clipboard.
; RETURNS:        true if we successfully copied something, false otherwise.
;---------
copyWithFunction(boundFunc) {
	if(!boundFunc)
		return
	
	clipboard := "" ; Clear the clipboard so we can wait for it to actually be set
	%boundFunc%()
	ClipWait, 0.5 ; Wait for the minimum time (0.5 seconds) for the clipboard to contain the new info.
	
	return (ErrorLevel != 1)
}

;---------
; DESCRIPTION:    Copy a file or folder path with the provided hotkeys, making sure that:
;                  * We wait long enough for the file/folder to get onto the clipboard
;                  * The path has been cleaned up and mapped
; PARAMETERS:
;  hotkeyKeys (I,REQ) - The keys to send in order to copy the file/folder to the clipboard.
; NOTES:          For folders, we'll also append a trailing backslash if one is missing.
;---------
copyFilePathWithHotkey(hotkeyKeys) {
	copyWithHotkey(hotkeyKeys)
	
	path := clipboard
	if(path)
		path := FileLib.cleanupPath(path)
	
	setClipboardAndToastValue(path, "file path")
}
copyFolderPathWithHotkey(hotkeyKeys) {
	copyWithHotkey(hotkeyKeys)
	
	path := clipboard
	if(path) {
		path := FileLib.cleanupPath(path)
		path := path.appendIfMissing("\") ; Add the trailing backslash since it's a folder
	}
	
	setClipboardAndToastValue(path, "folder path")
}

;---------
; DESCRIPTION:    Set the clipboard to the given value and show a toast about it.
; PARAMETERS:
;  newClipboardValue (I,REQ) - The value to put on the clipboard.
;  clipLabel         (I,OPT) - The label to show in the toast, clipboard set to <clipLabel> or similar (see Clip.toastClipboard)
;---------
setClipboardAndToastState(newClipboardValue, clipLabel := "value") {
	Clip.setClipboard(newClipboardValue)
	toastNewClipboardState(clipLabel)
}
;---------
; DESCRIPTION:    Set the clipboard to the given value and show a toast about it which includes the value.
; PARAMETERS:
;  newClipboardValue (I,REQ) - The value to put on the clipboard.
;  clipLabel         (I,OPT) - The label to show in the toast, clipboard set to <clipLabel> or similar (see Clip.toastClipboard)
;---------
setClipboardAndToastValue(newClipboardValue, clipLabel := "value") {
	Clip.setClipboard(newClipboardValue)
	toastNewClipboardValue(clipLabel)
}

;---------
; DESCRIPTION:    Set the clipboard to the given value and show an error toast about it.
; PARAMETERS:
;  newClipboardValue (I,REQ) - The value to put on the clipboard.
;  clipLabel         (I,REQ) - The label to show in the toast, clipboard set to <clipLabel> or similar (see Clip.toastClipboard)
;  problemMessage    (I,REQ) - The problem that occurred.
;  errorMessage      (I,OPT) - What went wrong on a technical level.
;---------
setClipboardAndToastError(newClipboardValue, clipLabel, problemMessage, errorMessage := "") {
	if(clipLabel = "")
		clipLabel := "value"
	
	Clip.setClipboard(newClipboardValue)
	new ErrorToast(problemMessage, errorMessage, "Clipboard set to " clipLabel ":`n" clipboard).showMedium()
}

;---------
; DESCRIPTION:    Show a toast about the clipboard's current state (basically whether it's set or not).
; PARAMETERS:
;  clipLabel (I,REQ) - The label to show in the toast, clipboard set to <clipLabel> or similar (see Clip.toastClipboard)
;---------
toastNewClipboardState(clipLabel := "value") {
	Clip.toastClipboard(clipLabel, false)
}
;---------
; DESCRIPTION:    Show a toast about the clipboard's current state (basically whether it's set or not),
;                 also including the actual value.
; PARAMETERS:
;  clipLabel (I,REQ) - The label to show in the toast, clipboard set to <clipLabel> or similar (see Clip.toastClipboard)
;---------
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
	; Debug.popup("Text to send with clipboard", text)
	
	originalClipboard := clipboardAll ; Save off the entire clipboard.
	clipboard := ""                   ; Clear the clipboard
	
	clipboard := text
	ClipWait, 0.5                     ; Wait for clipboard to contain the data we put in it (minimum time).
	Send, ^v
	Sleep, 100
	
	clipboard := originalClipboard    ; Restore the original clipboard. Note we're using clipboard (not clipboardAll).
}


; Clipboard-related helper functions.
class Clip {

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
	; DESCRIPTION:    Show a toast for the current clipboard value, basically whether it's set or not.
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
