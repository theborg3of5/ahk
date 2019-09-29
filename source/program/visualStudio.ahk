; Visual Studio hotkeys.
#If Config.isWindowActive("Visual Studio")
	Pause::+Pause ; For CodeMaid switch between related files
	
	^+t::Send, !fj1 ; Open last-closed project

	; Copy current file/folder paths to clipboard
	!c::VisualStudio.copyFilePath()              ; Current file
	!#c::VisualStudio.copyContainingFolderPath() ; Current file's folder
#If

class VisualStudio {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Copy current file path to clipboard and let user know with a toast.
	;---------
	copyFilePath() {
		copyFilePathWithHotkey("^+c")
	}
	
	;---------
	; DESCRIPTION:    Copy current file's containing folder to clipboard and let user know with a toast.
	;---------
	copyContainingFolderPath() {
		copyWithHotkey("^+c") ; Copy current FILE path
		
		path := clipboard
		if(path) {
			path := cleanupPath(path)
			path := mapPath(path)
			parentFolder := getParentFolder(path) ; Actually get the folder instead of the file
			parentFolder := parentFolder.appendIfMissing("\") ; Add the trailing backslash since it's a folder
		}
		
		setClipboardAndToastValue(parentFolder, "folder path")
	}
}
