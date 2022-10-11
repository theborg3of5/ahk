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
			Toast.ShowMedium("Showing hidden files...")
			newValue := 1 ; Visible
		} else {
			Toast.ShowMedium("Hiding hidden files...")
			newValue := 2 ; Hidden
		}
		
		; Set registry key for whether to show hidden files and refresh to apply.
		RegWrite, REG_DWORD, % REG_KEY_NAME, % REG_VALUE_NAME, % newValue
		Send, {F5}
	}
	
	;---------
	; DESCRIPTION:    Copy the current path (selected file, or folder if no file selected).
	;---------
	copySelectedPath() {
		path := this.getSelectedPath(pathType)
		ClipboardLib.setAndToast(path, pathType)
	}
	
	;---------
	; DESCRIPTION:    Copy the current source-relative (relative to DLG-* or App * folder) path (selected file, or folder
	;                 if no file selected).
	;---------
	copySelectedPathRelativeToSource() {
		path := this.getSelectedPath(pathType)
		relativePath := EpicLib.convertToSourceRelativePath(path)
		ClipboardLib.setAndToast(relativePath, "relative " pathType)
	}
	
	;---------
	; DESCRIPTION:    Get an EMC2 object using the selected file's/current folder's path rather than the title.
	; RETURNS:        A new ActionObjectEMC2 instance, or "" if it's not a special folder that links to an EMC2 object.
	;---------
	getEMC2ObjectFromSelectedFolder() {
		path := this.getSelectedPath()
		if(path = "") {
			Toast.ShowError("Could not get EMC2 object for selected folder", "Could not get selected folder path")
			return
		}
		
		record := EpicLib.selectEMC2RecordFromText(path)
		if(!record)
			return ""
		
		return new ActionObjectEMC2(record.id, record.ini)
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
			targetPath := this.getSelectedPath()
			if(targetPath = "") {
				Toast.ShowError("Failed to get path for relative shortcut")
				return
			}
			
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
	
	;---------
	; DESCRIPTION:    Create an (absolute) shortcut to one of a predefined set of HSWeb solutions.
	;---------
	selectSolutionShortcut() {
		; Get current folder (absolute root)
		currentFolder := FileLib.cleanupPath(ClipboardLib.getWithHotkey(this.Hotkey_CopyCurrentFolder))
		if(currentFolder = "") {
			Toast.ShowError("Failed to get current folder path")
			return
		}
		solutionsFolder := currentFolder "\" Config.private["EPIC_HSWEB_SOLUTIONS"]
		
		; Prompt user for which solution they want
		data := new Selector("solutionShortcuts.tls").selectGui()
		if(!data)
			return
		name               := data["NAME"]
		relativeTargetPath := data["PATH_IN_SOLUTIONS_FOLDER"]
		
		; Special case: open solutions folder
		if(relativeTargetPath = "OPEN_FOLDER") {
			Run(solutionsFolder)
			return
		}
		
		; Create shortcut
		targetPath := solutionsFolder "\" relativeTargetPath
		FileCreateShortcut, % targetPath, % currentFolder "\" name ".lnk", % currentFolder
		Toast.ShowMedium("Created shortcut to " name " solution in current folder")
	}
	
	; #PRIVATE#
	
	; Hotkeys (configured in QTTabBar)
	static Hotkey_CopyCurrentFile   := "!c"
	static Hotkey_CopyCurrentFolder := "^!c"
	
	; Static state for relative shortcut generation.
	static _relativeTarget := ""
	static _relativeToast  := ""
	
	
	;---------
	; DESCRIPTION:    Get the path to the selected file, or the current folder if no file is selected.
	; PARAMETERS:
	;  pathType (O,OPT) - A name for the type of path ("file path" or "folder path") for display to the user.
	; RETURNS:        Current absolute file path.
	;---------
	getSelectedPath(ByRef pathType := "") {
		pathType := ""
		
		path := ClipboardLib.getWithHotkey(this.Hotkey_CopyCurrentFile)
		if(path != "") {
			pathType := "file path"
			return FileLib.cleanupPath(path)
		}
		
		; If we didn't get anything, there probably wasn't a file selected - get the current folder instead.
		path := ClipboardLib.getWithHotkey(this.Hotkey_CopyCurrentFolder)
		if(path != "") {
			pathType := "folder path"
			return FileLib.cleanupPath(path)
		}
		
		; We couldn't find anything at all, no type.
		return ""
	}
	
	; [[Relative shortcuts]] =--
	;---------
	; DESCRIPTION:    Get the relative source folder from the current folder in Explorer.
	; RETURNS:        The current folder (cleaned up and with a trailing backslash)
	;                 "" (and show an error toast) if we couldn't get it
	;---------
	getRelativeSourceFolder() {
		path := ClipboardLib.getWithHotkey(Explorer.Hotkey_CopyCurrentFolder)
		if(path = "") {
			Toast.ShowError("Failed to get source folder path for relative shortcut")
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
		
		; Create the shortcut and let the user know.
		this.createRelativeShortcut(sourceFolder, relativePath)
		Toast.ShowShort("Created shortcuts!")
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
	; --=
	
	; #END#
}
