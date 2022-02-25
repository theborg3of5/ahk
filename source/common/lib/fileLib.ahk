; File and folder utility functions.

class FileLib {
	; #PUBLIC#
	
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
	; DESCRIPTION:    Determine whether a given string is formatted like a file path.
	; PARAMETERS:
	;  path (I,REQ) - The string to check.
	; RETURNS:        true/false - is the string a filepath?
	;---------
	isFilePath(path) {
		; URL-formatted file path, Windows network path
		if(path.startsWithAnyOf(["file://", "\\"]))
			return true
		
		; Filepath starting with a drive letter
		if(path.sub(2, 2) = ":\")
			return true
		
		; Unknown
		return false
	}

	;---------
	; DESCRIPTION:    Clean out unwanted garbage strings from paths and map path to any mapped network drives.
	; PARAMETERS:
	;  path (I,REQ) - The path to clean.
	; RETURNS:        The cleaned-up and mapped path.
	;---------
	cleanupPath(path) {
		; Return non-file URLs as-is, no cleaning.
		if(StringLib.isURL(path))
			return path
		
		; Clean + drop any leading/trailing quotes
		path := path.clean([""""])
		
		; Fix any strange formattings that could come from being a URL'd filepath (like from a wiki)
		if(path.matchesRegEx("file:\/+", protocol)) {
			path := path.removeFromStart(protocol)
			if(protocol = "file://") ; 2 slashes means it's a path with a hostname (that should start with two backslashes)
				path := "\\" path
			
			path := StringLib.decodeFromURL(path) ; Decode any encoded characters (like %20 for space)
			path := path.replace("/", "\")        ; Flip slashes
		}
		
		; Convert paths to use mapped drive letters
		table := new TableList("mappedDrives.tl").getTable()
		For _,row in table {
			if(path.contains(row["PATH"])) {
				path := path.replaceOne(row["PATH"], row["DRIVE_LETTER"] ":")
				Break ; Just match the first one.
			}
		}
		
		; Redirect old paths that have been moved.
		dbcDesignFolder := Config.path["EPIC_DBC_DESIGN"] "\" ; Add trailing backslash
		if(path.startsWith(dbcDesignFolder)) { ; Old design documents
			childFolder := path.firstBetweenStrings(dbcDesignFolder, "\")
			folderYear := childFolder.sub(1, 4)
			
			; If the folder doesn't start with a year, check if it ends with one (i.e. August 2018).
			if(!folderYear.isNum())
				folderYear := childFolder.sub(-3) ; Last 4 characters
			
			if(folderYear.isNum() && folderYear < 2020) { ; Year folders
				path := path.replace(dbcDesignFolder, dbcDesignFolder "Old Design Documents\") ; Moved to subfolder
				Toast.ShowMedium("Redirected path (old design document)")
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
	;  fileName       (I,REQ) - The path to the file to read in.
	;  dropWhitespace (I,OPT) - Set this to true to drop leading/trailing whitespace from every line in the file.
	; RETURNS:        The array of file lines, indexed so that ary[1] := line 1.
	;---------
	fileLinesToArray(fileName, dropWhitespace := false) {
		lines := []
		Loop, Read, % fileName
		{
			if(dropWhitespace)
				lines.insertAt(A_Index, A_LoopReadLine.withoutWhitespace())
			else
				lines.insertAt(A_Index, A_LoopReadLine)
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
	
	;---------
	; DESCRIPTION:    Send a file or folder path in a particular format.
	; PARAMETERS:
	;  folderName       (I,REQ) - The name of the file/folder in Config's paths or privates.
	;  subPath          (I,OPT) - The additional path to add to the end.
	;  slashChar        (I,OPT) - The slash (forward or back) character to use in between the path
	;                             and additional subPath, and at the end if addTrailingSlash = true.
	;  addTrailingSlash (I,OPT) - Set to true to add a trailing slash to the end of the path.
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
	
	
	;---------
	; DESCRIPTION:    Find the deepest common folder for the two given paths - that is, the lowest
	;                 common denominator of their parent folders.
	; PARAMETERS:
	;  path1 (I,REQ) - The first path to compare
	;  path2 (I,REQ) - The second path to compare
	; RETURNS:        The deepest parent folder (never a file, even if it's the same path twice)
	;                 that both paths have in common, with a trailing backslash.
	; NOTES:          This assumes that the paths are already cleaned up - they can't have quotes
	;                 or odd characters, and they should both be either mapped to drives or not.
	;---------
	findCommonFolder(path1, path2) {
		; First, reduce both paths to their deepest folders (themselves if they're already a folder).
		; Note that this should leave both of them with a trailing backslash (important later).
		folder1 := FileLib.reduceToFolder(path1)
		folder2 := FileLib.reduceToFolder(path2)
		
		; If that yeilds the same folder already, we're done.
		if(folder1 = folder2)
			return folder1
		
		; Start with the string overlap - that gets us pretty close.
		overlapPath := StringLib.findStringOverlapFromStart(path1, path2)
		
		; If the last character is a backslash, then both paths contained this folder and we're done.
		if(overlapPath.endsWith("\"))
			return overlapPath
		
		; Otherwise, the last bit of the path is a partial folder name (for at least one of the paths),
		; so the parent of that is our actual common folder.
		return FileLib.getParentFolder(overlapPath).appendIfMissing("\")
	}
	; #PRIVATE#
	
	
	;---------
	; DESCRIPTION:    Reduce the given path to a folder.
	; PARAMETERS:
	;  path (I,REQ) - The path to reduce.
	; RETURNS:        The same path (if it was a valid folder) or its parent, with a trailing backslash.
	; NOTES:          Assumes that the path is valid (that is, at least the folders involved exist).
	;---------
	reduceToFolder(path) {
		if(FileLib.folderExists(path)) ; If it's already a folder, we're done.
			folder := path
		else
			folder := FileLib.getParentFolder(path)
		
		return folder.appendIfMissing("\")
	}
	; #END#
}

