class VisualStudio {
	; #INTERNAL#
	
	;---------
	; DESCRIPTION:    Copy the current full code location (filepath::function()) to the clipboard.
	;---------
	copyCodeLocationWithPath() {
		path := ClipboardLib.getWithHotkey(this.Hotkey_CopyCurrentFile)
		if(path = "") {
			new ErrorToast("Failed to copy full code location", "Failed to get current file path").showMedium()
			return ""
		}
		path := FileLib.cleanupPath(path)
		
		; Function name will come from selected text
		functionName := SelectLib.getText()
		if(functionName != "" && !functionName.contains("`n")) ; If there's a newline then nothing was selected, we just copied the whole line.
			path .= "::" functionName "()"
		
		ClipboardLib.setAndToast(path, "full code location")
	}
	
	;---------
	; DESCRIPTION:    Opens the parent folder for the current file.
	; NOTES:          This is preferable to the built-in open-containing-folder hotkey because the latter locks up Visual
	;                 Studio and then claims that it fails (at least with QTTabBar in place).
	;---------
	openParentFolder() {
		path := ClipboardLib.getWithHotkey(this.Hotkey_CopyCurrentFile)
		if(path = "") {
			new ErrorToast("Failed to open parent folder", "Failed to get current file path").showMedium()
			return ""
		}
		path := FileLib.cleanupPath(path)
		
		parentFolder := FileLib.getParentFolder(path) ; Actually get the folder instead of the file
		Run(parentFolder)
	}
	
	; #PRIVATE#
	
	; Hotkeys
	static Hotkey_CopyCurrentFile := "^+c"
	; #END#
}
