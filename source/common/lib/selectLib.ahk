; Helper functions for dealing with selected text

class SelectLib {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Get the selected text using the clipboard.
	; RETURNS:        The selected text.
	;---------
	getText() {
		return ClipboardLib.getWithHotkey("^c")
	}
	
	;---------
	; DESCRIPTION:    Get the first line of the selected text.
	; RETURNS:        The portion of the selected text before the first newline.
	;---------
	getFirstLine() {
		return ClipboardLib.getWithHotkey("^c").firstLine()
	}
	
	;---------
	; DESCRIPTION:    Get the first line of the selected text, cleaned.
	; RETURNS:        The cleaned first line of the selected text.
	;---------
	getCleanFirstLine() {
		return ClipboardLib.getWithHotkey("^c").firstLine().clean()
	}
	
	;---------
	; DESCRIPTION:    Select the current line of text.
	;---------
	selectCurrentLine() {
		; Start with End as in some places, Home can put us in an inconsistent place relative to any
		; indentation (i.e. hitting home when you're at the start of the line jumps to the start/end
		; of the indentation).
		Send, {End}{Shift Down}{Home}{Shift Up}
	}
	
	;---------
	; DESCRIPTION:    Select the given text, within the currently selected block of text.
	; PARAMETERS:
	;  needle (I,REQ) - The text to select.
	;---------
	selectTextWithinSelection(needle) {
		if(needle = "")
			return
		
		selectedText := SelectLib.getText()
		if(selectedText = "")
			return
		
		; Determine where in the string our needle is
		needleStartPos := selectedText.contains(needle)
		if(!needleStartPos)
			return
		
		; Debug.popup("io.selectTextWithinSelection","Finished processing", "Selection",selectedText, "Needle",needle, "Needle start position",needleStartPos, "Number of times to go right",numRight)
		Send, {Left} ; Get to start of selection.
		numRight := needleStartPos - 1
		Send, {Right %numRight%} ; Get to start of needle.
		Send, {Shift Down}
		needleLen := needle.length()
		Send, {Right %needleLen%} ; Select to end of needle.
		Send, {Shift Up}
	}

	;---------
	; DESCRIPTION:    Link the selected text with the given URL/path.
	; PARAMETERS:
	;  path         (I,REQ) - URL or file path to link to.
	;  errorMessage (O,OPT) - Error message about what went wrong if we return False.
	; RETURNS:        True if successful, False if something went wrong.
	;---------
	linkSelectedText(path, ByRef errorMessage := "") {
		if(!path) {
			errorMessage := "Path to link was blank"
			return false
		}
		
		path := FileLib.cleanupPath(path)
		windowName := Config.findWindowName("A")
		
		; Special handling
		if (Config.isWindowActive("OneNote")) ; OneNote can't handle double quotes in URLs for some reason, so encode them.
			path := path.replace("""", "%22")
		
		selectedText := SelectLib.getText()
		ClipboardLib.sendHyperlink(selectedText, path)
		return true
	}
	;endregion ------------------------------ PUBLIC ------------------------------
}
