; File and folder utility functions.

folderExists(folderPath) {
	return InStr(FileExist(folderPath), "D") ; Exists and is a directory
}

getParentFolder(path, levelsUp := 1) {
	outPath := path.removeFromEnd("\") ; Make sure there's no trailing backslash, SplitPath assumes that involves a blank filename.
	
	Loop, % levelsUp {
		SplitPath(outPath, "", parentPath)
		outPath := parentPath
	}
	
	return outPath
}
	
findConfigFilePath(path) {
	if(!path)
		return ""
	
	; In the current folder, or full path
	if(FileExist(path))
		return path
	
	; If there's an Includes folder in the same directory, check in there as well.
	if(FileExist("Includes\" path))
		return "Includes\" path
	
	; Check the overall config folder.
	configFolder := Config.path["AHK_CONFIG"]
	if(FileExist(configFolder "\local\" path))      ; Local folder (not version-controlled) inside of config
		return configFolder "\local\" path
	if(FileExist(configFolder "\ahkPrivate\" path)) ; Private folder (separately version-controlled) inside of config
		return configFolder "\ahkPrivate\" path
	if(FileExist(configFolder "\" path))            ; General config folder
		return configFolder "\" path
	
	return ""
}

; Clean out unwanted garbage strings from paths and map them to any map drives.
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
	
	; DEBUG.popup("Updated path",path, "Table",table)
	return path
}

; Open a folder from config-defined tags.
openFolder(folderName) {
	folderPath := Config.path[folderName]
	; DEBUG.popup("Folder name",folderName, "Path",folderPath)
	
	if(folderExists(folderPath))
		Run(folderPath)
}

; Read in a file and return it as an array.
fileLinesToArray(fileName) {
	lines := Object()
	
	Loop Read, %fileName% 
	{
		lines[A_Index] := A_LoopReadLine
	}
	
	return lines
}

replaceFileWithString(filePath, newContents) {
	if(!filePath)
		return
	
	FileDelete, % filePath
	if(newContents)
		FileAppend, % newContents, % filePath
}


class FileUtils {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Send a file or folder path in a particular format.
	; PARAMETERS:
	;  folderName (I,REQ) - The name of the folder in Config's paths or privates.
	;  subPath    (I,OPT) - The additional path to add to the end
	; NOTES:          The folder options here always include a trailing slash.
	;---------
	sendFilePath(folderName, subPath := "") {
		FileUtils.sendPath(folderName, subPath)
	}
	sendFolderPath(folderName, subPath := "") {
		FileUtils.sendPath(folderName, subPath, "/", true)
	}
	sendUnixFolderPath(folderName, subPath := "") {
		FileUtils.sendPath(folderName, subPath, "/", true)
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

