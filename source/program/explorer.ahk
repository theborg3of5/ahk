#If Config.isWindowActive("Explorer")
	; Focus address bar
	^l::Send, !d
		
	; Open "new tab" (to This PC)
	#e::
	^t::
		Run(Explorer.ThisPCFolderUUID)
	return
	
	; Copy current folder/file paths to clipboard
	!c::ClipboardLib.copyFilePathWithHotkey("!c")     ; Current file
	!#c::ClipboardLib.copyFolderPathWithHotkey("^!c") ; Current folder
	
	; Relative shortcut creation
	^+s::Explorer.createRelativeShortcut()
	
	; Hide/show hidden files
	#h::Explorer.toggleHiddenFiles()
	
	; Show TortoiseSVN/TortoiseGit log for current selection (both have an "l" hotkey in the
	; right-click menu, and appear only when the item is in that type of repo)
	!l::
		HotkeyLib.waitForRelease()
		Send, {AppsKey}
		Send, l
	return
#If

class Explorer {
	; #PUBLIC#
	
	static ThisPCFolderUUID := "::{20d04fe0-3aea-1069-a2d8-08002b30309d}"
	
	
	; #INTERNAL#
	
	;---------
	; DESCRIPTION:    Toggle whether hidden files are visible in Explorer or not.
	; NOTES:          Inspired by http://www.autohotkey.com/forum/post-342375.html#342375
	;---------
	toggleHiddenFiles() {
		; Get current state and pick the opposite to use now.
		currentState := RegRead(Explorer.ShowHiddenRegKeyName, Explorer.ShowHiddenRegValueName)
		if(currentState = 2) {
			new Toast("Showing hidden files...").showMedium()
			newValue := 1 ; Visible
		} else {
			new Toast("Hiding hidden files...").showMedium()
			newValue := 2 ; Hidden
		}
		
		; Set registry key for whether to show hidden files and refresh to apply.
		RegWrite, REG_DWORD, % Explorer.ShowHiddenRegKeyName, % Explorer.ShowHiddenRegValueName, % newValue
		Send, {F5}
	}
	
	;---------
	; DESCRIPTION:    Create a relative file or folder shortcut. This must be called twice - once
	;                 when the user has the target file selected, and once when they are in the
	;                 desired folder for the shortcut file.
	; NOTES:          Calls into different logic depending on whether this is the first or second trigger.
	;---------
	createRelativeShortcut() {
		; Initial trigger, sets _relativeTarget
		if(this._relativeTarget = "")
			this.setupRelativeShortcut()
		
		; Second trigger, clears _relativeTarget
		else
			this.finishRelativeShortcut()
	}
	
	
	; #PRIVATE#
	
	static ShowHiddenRegKeyName := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
	static ShowHiddenRegValueName := "Hidden"
	
	; Static state for relative shortcut generation.
	static _relativeTarget := ""
	static _relativeToast  := ""
	
	
	;---------
	; DESCRIPTION:    Set up the relative shortcut functionality - grab the target for our eventual
	;                 shortcut and store it off, and show the user a toast explaining what's going on.
	;---------
	setupRelativeShortcut() {
		path := ClipboardLib.getWithHotkey("!c") ; GDB TODO should we have constants or functions or something for getting the current file/folder so it's easier to use in code here?
		if(path = "") {
			new ErrorToast("Failed to get file path for relative shortcut").showMedium()
			return
		}
		path := FileLib.cleanupPath(path)
		
		this.saveRelative(path)
	}
	
	;---------
	; DESCRIPTION:    Get the target folder (where we want to put the shortcut file) and create a
	;                 relative shortcut.
	;---------
	finishRelativeShortcut() {
		; First try to get the target location of the new shortcut file - if this fails we want to let the user retry.
		targetFolder := ClipboardLib.getWithHotkey("^!c")
		if(targetFolder = "") {
			new ErrorToast("Failed to get source folder path for relative shortcut").showMedium()
			return
		}
		targetFolder := FileLib.cleanupPath(targetFolder).appendIfMissing("\")
		
		; Grab the source path and clean out static bits.
		sourcePath := this._relativeTarget
		this.cleanupRelative()
		
		; Find the overlap (highest common folder) between the source file and target folder ; GDB TODO string overlap should be a function in StringLib
		overlapPath := ""
		Loop, Parse, targetFolder
		{
			if(A_LoopField != sourcePath.charAt(A_Index))
				Break
			overlapPath .= A_LoopField
		}
		
		; If there was partial overlap within a folder name (instead of ending at a slash), trim it back to the containing folder. ; GDB TODO filepath overlap should maybe be a function in FileLib, that uses the StringLib overlap one
		if(overlapPath.charAt(0) != "\") {
			SplitPath(overlapPath, , overlapPath)
			overlapPath := overlapPath.appendIfMissing("\")
		}
		
		; Get the path from the overlap to the source. ; GDB TODO relative path from one file to another (or folder to a file, for this case?) - should it be a function?
		sourceRelative := sourcePath.removeFromStart(overlapPath) ; No backslash here, because we made sure overlap had a backslash on the end
		
		; Get the path from the target to the overlap.
		if(targetFolder = overlapPath) {
			targetRelative := ""
		} else {
			Loop {
				levelsUp := A_Index
				currPath := FileLib.getParentFolder(targetFolder, levelsUp).appendIfMissing("\")
				; Debug.popup("targetFolder",targetFolder, "currPath",currPath, "overlapPath",overlapPath, "levelsUp",levelsUp, "A_Index",A_Index)
				if(currPath = overlapPath)
					Break
			}
			targetRelative := StringLib.duplicate("..\", levelsUp)
		}
		
		relativePath := targetRelative sourceRelative
		
		SplitPath(sourcePath, sourceName)
		shortcutFilePath := targetFolder.appendIfMissing("\") sourceName ".lnk"
		args := "/c start """" ""%CD%\" relativePath """"
		FileCreateShortcut, % A_ComSpec, % shortcutFilePath, , % args
		
		t := new Toast("Created shortcut!").blockingOn().showShort()
	}
	
	;---------
	; DESCRIPTION:    Save off the non-local bits needed for the relative shortcut functionality.
	; PARAMETERS:
	;  path (I,REQ) - The path to our eventual shortcut target.
	;---------
	saveRelative(path) {
		this._relativeTarget := path
		this._relativeToast := new Toast("Ready to create relative shortcut to file:`n" path "`nPress ^+s again to create in that folder, Esc to cancel").show()
		
		; Hotkey to cancel out and not create anything
		boundFunc := ObjBindMethod(this, "cleanupRelative")
		Hotkey, Escape, % boundFunc, On
	}
	
	;---------
	; DESCRIPTION:    Clean up when we no longer need the relative shortcut info.
	;---------
	cleanupRelative() {
		Hotkey, Escape, , Off
		this._relativeTarget := ""
		this._relativeToast.close()
		this._relativeToast  := ""
	}
	; #END#
}
