class Explorer {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    This is the UUID for the "This PC" folder that shows all drives.
	;---------
	static ThisPCFolderUUID := "::{20d04fe0-3aea-1069-a2d8-08002b30309d}"
	
	
	; #INTERNAL#
	
	;---------
	; DESCRIPTION:    Toggle whether hidden files are visible in Explorer or not.
	; NOTES:          Inspired by http://www.autohotkey.com/forum/post-342375.html#342375
	;---------
	toggleHiddenFiles() {
		REG_KEY_NAME   := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
		REG_VALUE_NAME := "Hidden"
		
		; Get current state and pick the opposite to use now.
		currentState := RegRead(REG_KEY_NAME, REG_VALUE_NAME)
		if(currentState = 2) {
			new Toast("Showing hidden files...").showMedium()
			newValue := 1 ; Visible
		} else {
			new Toast("Hiding hidden files...").showMedium()
			newValue := 2 ; Hidden
		}
		
		; Set registry key for whether to show hidden files and refresh to apply.
		RegWrite, REG_DWORD, % REG_KEY_NAME, % REG_VALUE_NAME, % newValue
		Send, {F5}
	}
	
	;---------
	; DESCRIPTION:    Create a relative file or folder shortcut. This must be called twice - once
	;                 when the user has the target file selected, and once when they are in the
	;                 desired folder for the shortcut file.
	; NOTES:          Calls into different logic depending on whether this is the first or second trigger.
	;---------
	createRelativeShortcutToFile() {
		; Initial trigger
		if(this._relativeTarget = "") {
			targetPath := this.getRelativeShortcutTarget()
			if(targetPath = "")
				return
			
			this.saveRelative(targetPath) ; Sets _relativeTarget
			
		; Second trigger
		} else {
			sourceFolder := this.getRelativeSourceFolder()
			if(sourceFolder = "")
				return
			
			targetPath := this._relativeTarget
			this.cleanupRelative() ; Clears _relativeTarget
				
			this.createRelative(sourceFolder, targetPath)
		}
	}
	
	
	; #PRIVATE#
	
	; Hotkeys (configured in QTTabBar) to copy the current file/folder path to the clipboard.
	static Hotkey_CopyCurrentFile   := "!c"
	static Hotkey_CopyCurrentFolder := "^!c"
	
	; Static state for relative shortcut generation.
	static _relativeTarget := ""
	static _relativeToast  := ""
	
	
	;---------
	; DESCRIPTION:    Get the relative shortcut target using the current file in Explorer.
	; RETURNS:        The path to the current file (cleaned up).
	;                 "" (and show an error toast) if we couldn't get it.
	;---------
	getRelativeShortcutTarget() {
		path := ClipboardLib.getWithHotkey(Explorer.Hotkey_CopyCurrentFile)
		if(path = "") {
			new ErrorToast("Failed to get file path for relative shortcut").showMedium()
			return ""
		}
		
		return FileLib.cleanupPath(path)
	}
	
	;---------
	; DESCRIPTION:    Get the relative source folder from the current folder in Explorer.
	; RETURNS:        The current folder (cleaned up and with a trailing backslash)
	;                 "" (and show an error toast) if we couldn't get it
	;---------
	getRelativeSourceFolder() {
		path := ClipboardLib.getWithHotkey(Explorer.Hotkey_CopyCurrentFolder)
		if(path = "") {
			new ErrorToast("Failed to get source folder path for relative shortcut").showMedium()
			return ""
		}
		
		return FileLib.cleanupPath(path).appendIfMissing("\")
	}
	
	;---------
	; DESCRIPTION:    Save off the non-local bits needed for the relative shortcut functionality.
	; PARAMETERS:
	;  path (I,REQ) - The path to our eventual shortcut target.
	;---------
	saveRelative(path) {
		this._relativeTarget := path
		this._relativeToast := new Toast("Ready to create relative shortcut to file:`n" path "`nPress ^+s again to create in that folder, Esc to cancel").show()
		boundFunc := ObjBindMethod(this, "cleanupRelative")
		Hotkey, Escape, % boundFunc, On ; Hotkey to cancel out and not create anything
	}
	
	;---------
	; DESCRIPTION:    Clean up when we no longer need the relative shortcut info.
	;---------
	cleanupRelative() {
		this._relativeTarget := ""
		this._relativeToast.close()
		this._relativeToast  := ""
		Hotkey, Escape, , Off
	}
	
	;---------
	; DESCRIPTION:    Create a relative shortcut using some cmd.exe shenanigans.
	; PARAMETERS:
	;  sourceFolder (I,REQ) - The folder where the new shortcut should live (with trailing backslash)
	;  targetPath   (I,REQ) - The file the shortcut should point to
	;---------
	createRelative(sourceFolder, targetPath) {
		; Find the relative path from source folder to target.
		relativePath := this.getRelativePath(sourceFolder, targetPath)
		
		; Create the shortcut
		this.createRelativeShortcut(sourceFolder, relativePath)
		
		; Optionally create shortcut to parent folder as well
		if(GuiLib.showConfirmationPopup("Also create shortcut to target parent?")) {
			parentPath := FileLib.getParentFolder(relativePath)
			SplitPath(parentPath, parentName)
			
			this.createRelativeShortcut(sourceFolder, parentPath, parentName " Folder")
		}
		
		t := new Toast("Created shortcuts!").showShort()
	}
	
	;---------
	; DESCRIPTION:    Create a relative shortcut.
	; PARAMETERS:
	;  shortcutParentFolder (I,REQ) - The folder where the new shortcut should live (with trailing backslash)
	;  relativePath         (I,REQ) - The relative path to the target (no leading backslash), from the shortcut parent folder
	;  shortcutName         (I,OPT) - The name the shortcut file should have 
	;---------
	createRelativeShortcut(shortcutParentFolder, relativePath, shortcutName := "") {
		if(shortcutName = "")
			SplitPath(relativePath, shortcutName)
		
		shortcutFilePath := shortcutParentFolder shortcutName ".lnk"
		args := "/c start """" ""%CD%\" relativePath """" ; %CD% is current directory
		FileCreateShortcut, % A_ComSpec, % shortcutFilePath, , % args
	}
	
	;---------
	; DESCRIPTION:    Get the relative path between a source folder and target path.
	; PARAMETERS:
	;  sourceFolder (I,REQ) - The folder to start from
	;  targetPath   (I,REQ) - The file the path should point to
	; RETURNS:        A relative path, with no leading backslash.
	;---------
	getRelativePath(sourceFolder, targetPath) {
		; Find the overlap (deepest common folder) between the source file and target folder
		commonFolder := FileLib.findCommonFolder(sourceFolder, targetPath)
		
		; Get the path from the target to the overlap.
		sourceRelative := ""
		currPath := sourceFolder
		Loop {
			if(currPath = commonFolder)
				Break
			
			currPath := FileLib.getParentFolder(currPath) "\"
			sourceRelative .= "..\"
		}
		
		; Get the path from the overlap to the source.
		targetRelative := targetPath.removeFromStart(commonFolder) ; No leading backslash here, because commonFolder has a backslash on the end
		
		return sourceRelative targetRelative
	}
	; #END#
}
