; File and folder utility functions.
class FileLib {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Check whether a folder exists at the given path.
	; PARAMETERS:
	;  folderPath (I,REQ) - The path to check for a folder.
	; RETURNS:        true if it exists, false otherwise.
	;---------
	folderExists(folderPath) {
		return InStr(FileExist(folderPath), "D") ; Exists and is a directory
	}
	
	;---------
	; DESCRIPTION:    Get the parent of the provided path.
	; PARAMETERS:
	;  path     (I,REQ) - The path to start with.
	;  levelsUp (I,OPT) - How many levels to go up (where 1 is the parent of that path). Defaults to 1.
	; RETURNS:        The parent (or higher depending of levelsUp) folder.
	;---------
	getParentFolder(path, levelsUp := 1) {
		outPath := path.removeFromEnd("\") ; Make sure there's no trailing backslash, SplitPath assumes that involves a blank filename.
		
		Loop, % levelsUp {
			SplitPath(outPath, "", parentPath)
			outPath := parentPath
		}
		
		return outPath
	}

	;---------
	; DESCRIPTION:    Clean out unwanted garbage strings from paths and map path to any mapped network drives.
	; PARAMETERS:
	;  path (I,REQ) - The path to clean.
	; RETURNS:        The cleaned-up and mapped path.
	;---------
	cleanupPath(path) {
		path := path.replace("%20", A_Space) ; In case it's a URL'd file path
		path := path.clean(["file:///", """"])
		
		; Convert paths to use mapped drive letters
		table := new TableList("mappedDrives.tl").getTable()
		For _,row in table {
			if(path.contains(row["PATH"])) {
				path := path.replaceOne(row["PATH"], row["DRIVE_LETTER"] ":")
				Break ; Just match the first one.
			}
		}
		
		; Debug.popup("Updated path",path, "Table",table)
		return path
	}
	
	;---------
	; DESCRIPTION:    Find the given config file, by searching the following places for it:
	;                  * The current folder
	;                  * The AHK root config folder
	;                  * The \local\ folder inside the AHK root config folder
	;                  * The \ahkPrivate\ folder inside the AHK root config folder
	; PARAMETERS:
	;  path (I,REQ) - The filename or path to locate.
	; RETURNS:        The absolute filepath, or "" if we couldn't find it.
	;---------
	findConfigFilePath(path) {
		if(!path)
			return ""
		
		; In the current folder, or full path
		if(FileExist(path))
			return path
		
		; Check the overall config folder.
		configFolder := Config.path["AHK_CONFIG"]
		if(FileExist(configFolder "\" path))            ; General config folder
			return configFolder "\" path
		if(FileExist(configFolder "\local\" path))      ; Local folder (not version-controlled) inside of config
			return configFolder "\local\" path
		if(FileExist(configFolder "\ahkPrivate\" path)) ; Private folder (separately version-controlled) inside of config
			return configFolder "\ahkPrivate\" path
		
		return ""
	}

	;---------
	; DESCRIPTION:    Read in a file and return it as an array.
	; PARAMETERS:
	;  fileName (I,REQ) - The path to the file to read in.
	; RETURNS:        The array of file lines.
	;---------
	fileLinesToArray(fileName) {
		lines := Object()
		Loop Read, %fileName% 
		{
			lines[A_Index] := A_LoopReadLine
		}
		return lines
	}
	
	;---------
	; DESCRIPTION:    Replace the given file's contents with the provided string.
	; PARAMETERS:
	;  filePath    (I,REQ) - The path to the file to update.
	;  newContents (I,REQ) - The contents to replace the file's contents with.
	;---------
	replaceFileWithString(filePath, newContents) {
		if(!filePath)
			return
		
		FileDelete, % filePath
		if(newContents)
			FileAppend, % newContents, % filePath
	}
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Send a file or folder path in a particular format.
	; PARAMETERS:
	;  folderName       (I,REQ) - The name of the file/folder in Config's paths or privates.
	;  subPath          (I,OPT) - The additional path to add to the end.
	;  slashChar        (I,OPT) - The slash (forward or back) character to use in between the path
	;                             and additional subPath, and at the end if addTrailingSlash = true.
	;  addTrailingSlash (I,OPT) - Set to true to add a trailing slash to the end of the path.
	; RETURNS:        
	; SIDE EFFECTS:   
	; NOTES:          
	;---------
	sendPath(folderName, subPath := "", slashChar := "\", addTrailingSlash := false) {
		if(folderName = "")
			return
		
		folderPath := Config.path[folderName]
		if(!folderPath)
			return
		
		; Append a further subPath if they gave that to us
		if(subPath) {
			folderPath := folderPath.appendIfMissing(slashChar)
			folderPath .= subPath
		}
		
		if(addTrailingSlash)
			folderPath := folderPath.appendIfMissing(slashChar)
		
		Send, % folderPath
	}
	
}

