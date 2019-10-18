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
	
	Clipboard := "" ; Clear the clipboard so we can wait for it to actually be set
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
	
	Clipboard := "" ; Clear the clipboard so we can wait for it to actually be set
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
	
	path := Clipboard
	if(path)
		path := FileLib.cleanupPath(path)
	
	setClipboardAndToastValue(path, "file path")
}
copyFolderPathWithHotkey(hotkeyKeys) {
	copyWithHotkey(hotkeyKeys)
	
	path := Clipboard
	if(path) {
		path := FileLib.cleanupPath(path)
		path := path.appendIfMissing("\") ; Add the trailing backslash since it's a folder
	}
	
	setClipboardAndToastValue(path, "folder path")
}

;---------
; DESCRIPTION:    Get some content using a BoundFunc object which copies something to the clipboard.
; PARAMETERS:
;  boundFunc (I,REQ) - A BoundFunc object created with Func.Bind() or ObjBindMethod(), which will
;                      copy the desired content to the clipboard.
; RETURNS:        The copied content.
;---------
getWithClipboardUsingFunction(boundFunc) { ; boundFunc is a BoundFunc object created with Func.Bind() or ObjBindMethod().
	if(!boundFunc)
		return
	
	originalClipboard := ClipboardAll ; Back up the clipboard since we're going to use it to get the selected text.
	copyWithFunction(boundFunc)
	
	textFound := Clipboard
	Clipboard := originalClipboard    ; Restore the original clipboard. Note we're using Clipboard (not ClipboardAll).
	
	return textFound
}

;---------
; DESCRIPTION:    Set the clipboard to the given value and show a toast about it.
; PARAMETERS:
;  newClipboardValue (I,REQ) - The value to put on the clipboard.
;  clipLabel         (I,OPT) - The label to show in the toast, clipboard set to <clipLabel> or similar (see ClipboardLib.toastClipboard)
;---------
setClipboardAndToastState(newClipboardValue, clipLabel := "value") {
	ClipboardLib.set(newClipboardValue)
	toastNewClipboardState(clipLabel)
}
;---------
; DESCRIPTION:    Set the clipboard to the given value and show a toast about it which includes the value.
; PARAMETERS:
;  newClipboardValue (I,REQ) - The value to put on the clipboard.
;  clipLabel         (I,OPT) - The label to show in the toast, clipboard set to <clipLabel> or similar (see ClipboardLib.toastClipboard)
;---------
setClipboardAndToastValue(newClipboardValue, clipLabel := "value") {
	ClipboardLib.set(newClipboardValue)
	toastNewClipboardValue(clipLabel)
}

;---------
; DESCRIPTION:    Set the clipboard to the given value and show an error toast about it.
; PARAMETERS:
;  newClipboardValue (I,REQ) - The value to put on the clipboard.
;  clipLabel         (I,REQ) - The label to show in the toast, clipboard set to <clipLabel> or similar (see ClipboardLib.toastClipboard)
;  problemMessage    (I,REQ) - The problem that occurred.
;  errorMessage      (I,OPT) - What went wrong on a technical level.
;---------
setClipboardAndToastError(newClipboardValue, clipLabel, problemMessage, errorMessage := "") {
	if(clipLabel = "")
		clipLabel := "value"
	
	ClipboardLib.set(newClipboardValue)
	new ErrorToast(problemMessage, errorMessage, "Clipboard set to " clipLabel ":`n" clipboard).showMedium()
}

;---------
; DESCRIPTION:    Show a toast about the clipboard's current state (basically whether it's set or not).
; PARAMETERS:
;  clipLabel (I,REQ) - The label to show in the toast, clipboard set to <clipLabel> or similar (see ClipboardLib.toastClipboard)
;---------
toastNewClipboardState(clipLabel := "value") {
	ClipboardLib.toastClipboard(clipLabel, false)
}
;---------
; DESCRIPTION:    Show a toast about the clipboard's current state (basically whether it's set or not),
;                 also including the actual value.
; PARAMETERS:
;  clipLabel (I,REQ) - The label to show in the toast, clipboard set to <clipLabel> or similar (see ClipboardLib.toastClipboard)
;---------
toastNewClipboardValue(clipLabel := "value") {
	ClipboardLib.toastClipboard(clipLabel, true)
}

;---------
; DESCRIPTION:    Add something to the clipboard history, restoring the original clipboard value.
; PARAMETERS:
;  textToSave (I,REQ) - Text to add to the clipboard history.
;---------
addToClipboardHistory(textToSave) {
	originalClipboard := ClipboardAll
	
	Clipboard := textToSave
	ClipboardLib.saveToManager()
	
	Clipboard := originalClipboard
	ClipboardLib.saveToManager()
}


/* Clipboard-related helper functions.
*/
class ClipboardLib {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Get the currently-selected text using the clipboard. Restores the clipboard
	;                 after we're done as well.
	; RETURNS:        The selected text
	;---------
	getSelectedText() {
		; PuTTY auto-copies the selection to the clipboard, and ^c causes an interrupt, so do nothing.
		if(WinActive("ahk_class PuTTY"))
			return Clipboard
		
		originalClipboard := ClipboardAll ; Back up the clipboard since we're going to use it to get the selected text.
		copyWithHotkey("^c")
		
		textFound := Clipboard
		Clipboard := originalClipboard    ; Restore the original clipboard. Note we're using Clipboard (not ClipboardAll).
		
		return textFound
	}

; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Set the clipboard to the given value, and wait to make sure it applies before returning.
	; PARAMETERS:
	;  value (I,REQ) - Value to set.
	; RETURNS:        The original value of the clipboard.
	;---------
	set(value) {
		origClipboard := ClipboardAll ; Save off everything (images, formatting), not just the text (that's all that's in Clipboard)
		
		Clipboard := "" ; Clear the clipboard so we can wait for it to actually be set
		if(value != "") { ; Don't need to do anything else if we just wanted to blank it out
			Clipboard := value
			ClipWait, 0.5 ; Wait for the minimum time (0.5 seconds) for the clipboard to contain the new info.
		}
		
		return origClipboard
	}
	
	;---------
	; DESCRIPTION:    Send the provided text using the clipboard, restoring the clipboard afterwards.
	; PARAMETERS:
	;  value (I,REQ) - The text to send.
	;---------
	send(value) {
		origClipboard := ClipboardLib.set(value)
		Send, ^v   ; Paste the new value.
		Sleep, 100 ; Needed to make sure clipboard isn't overwritten before we paste it.
		ClipboardLib.set(origClipboard)
	}
	
	;---------
	; DESCRIPTION:    Force the clipboard manager to store the current value, generally useful just
	;                 before you change the clipboard to something else.
	;---------
	saveToManager() {
		if(Ditto) ; If the Ditto class exists we can use it to save to the clipboard with Ditto with no wait time.
			Ditto.saveCurrentClipboard()
		else ; Otherwise, just wait a second for it to register normally.
			Sleep, 1000
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
		
		if(Clipboard = "") {
			new ErrorToast("Failed to get " clipLabel).showMedium()
		} else {
			clipMessage := "Clipboard set to " clipLabel
			if(showClipboardValue)
				clipMessage .= ":`n" Clipboard
			new Toast(clipMessage).showMedium()
		}
	}
}
