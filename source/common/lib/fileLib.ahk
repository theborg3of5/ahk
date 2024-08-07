; File and folder utility functions.

class FileLib {
	;region ------------------------------ PUBLIC ------------------------------
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
	; DESCRIPTION:    Check whether a folder exists at the given path.
	;                 Wrapper for folderExists with a more obvious name.
	; PARAMETERS:
	;  folderPath (I,REQ) - The path to check for a folder.
	; RETURNS:        true if it exists, false otherwise.
	;---------
	isFolder(path) {
		return this.folderExists(path)
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
	; DESCRIPTION:    Determine whether a given string is formatted like a file path (Windows or Unix!)
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

		; Unix filepath (starst with a single forward slash)
		if(path.startsWith("/") && !path.startsWith("//"))
			return true
		
		; Unknown
		return false
	}

	;---------
	; DESCRIPTION:    Clean out unwanted garbage strings from paths, map to network drives, map from Unix to Windows paths.
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
		mappedDrives := new TableList("mappedDrives.tl").getTable()
		For _,row in mappedDrives {
			if(path.contains(row["PATH"])) {
				path := path.replaceOne(row["PATH"], row["DRIVE_LETTER"] ":")
				Break ; Just match the first one.
			}
		}
		
		; Try to redirect old paths that have been moved.
		if(!FileExist(path)) {
			movedFolders := new TableList("movedFolders.tl").getTable()
			For _,row in movedFolders {
				if(path.startsWith(row["OLD_FOLDER"])) {
					path := path.replaceOne(row["OLD_FOLDER"], row["NEW_FOLDER"])
					Toast.ShowMedium("Redirected path (" row["NAME"] ")")
					Break
				}
			}
		}

		; Convert Unix paths to Windows (where we have the mappings available)
		path := FileLib.mapUnixPathToWindows(path)
		
		; Debug.popup("path",path, "mappedDrives",mappedDrives, "movedFolders",movedFolders)
		return path
	}

	;---------
	; DESCRIPTION:    Check whether the given path is an (absolute) Unix path (as opposed to a Windows path).
	; PARAMETERS:
	;  path (I,REQ) - The path to check
	; RETURNS:        true/false
	;---------
	isUnixPath(path) {
		return path.startsWith("/")
	}

	;---------
	; DESCRIPTION:    Map a Unix path to its Windows equivalent (where we have the mappings to do so).
	; PARAMETERS:
	;  unixPath (I,REQ) - The full Unix path (starting with /)
	; RETURNS:        A Windows path if we mapped successfully, otherwise the original unixPath.
	;---------
	mapUnixPathToWindows(unixPath) {
		; Must actually be a full Unix path, otherwise change nothing
		if(!FileLib.isUnixPath(unixPath))
			return unixPath

		unixMappings := new TableList("unixFolderMappings.tl").getTable()
		For _,map in unixMappings {
			if(unixPath.startsWith(map["UNIX"])) {
				unixPath := unixPath.replaceOne(map["UNIX"], map["WINDOWS"])
				unixPath := unixPath.replace("/", "\") ; Flip any other slashes
			}
		}

		return unixPath
	}

	;---------
	; DESCRIPTION:    Map a Windows path to its Unix equivalent (where we have the mappings to do so).
	; PARAMETERS:
	;  windowsPath (I,REQ) - The full Windows path
	; RETURNS:        A Unix path if we mapped successfully, otherwise the original windowsPath.
	;---------
	mapWindowsPathToUnix(windowsPath) {
		unixMappings := new TableList("unixFolderMappings.tl").getTable()
		For _,map in unixMappings {
			if(windowsPath.startsWith(map["WINDOWS"])) {
				windowsPath := windowsPath.replaceOne(map["WINDOWS"], map["UNIX"])
				windowsPath := windowsPath.replace("\", "/") ; Flip any other slashes
			}
		}

		return windowsPath
	}
	
	;---------
	; DESCRIPTION:    Find the given config file, by searching the following places for it:
	;                  * The current folder
	;                  * The AHK root config folder
	;                  * The AHK root private folder
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
		
		; Check our config folders
		configPath := Config.path["AHK_CONFIG"] "\" path ; General config folder
		if(FileExist(configPath))
			return configPath
		privatePath := Config.path["AHK_PRIVATE"] "\" path ; Private folder (separately version-controlled)
		if(FileExist(privatePath))
			return privatePath
		
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
		FileAppend, % newContents, % filePath
	}

	;---------
	; DESCRIPTION:    Create the given folder path (and its parents) if it doesn't already exist.
	; PARAMETERS:
	;  folderPath  (I,REQ) - The path of the folder to check/create.
	;  silentForce (I,OPT) - By default we'll prompt the user before creating anything - pass true here to suppress that.
	; RETURNS:        true if the folder (already or newly) exists, false if we couldn't create it or the user declined.
	;---------
	createFolderIfNoExist(folderPath, silentForce := false) {
		; Already exists, nothing to do.
		if(FileLib.folderExists(folderPath))
			return true
		
		; Check if the user wants us to create a folder.
		if(!silentForce && !GuiLib.showConfirmationPopup("This folder does not exist:`n" folderPath "`n`nCreate it?", "Folder does not exist"))
			return false ; User doesn't want us to create
		
		; Create the parent folder (recursively) if it doesn't already exist.
		if(!FileLib.createFolderIfNoExist(FileLib.getParentFolder(folderPath), true))
			return false ; Something went wrong creating the parent.

		; Create the requested folder.
		FileCreateDir, % folderPath
		return (ErrorLevel = 0)
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

	;---------
	; DESCRIPTION:    Replace the oldest temp file (of our circulating set of temp files) with the given text.
	; PARAMETERS:
	;  textToWrite (I,REQ) - The text to use
	; RETURNS:        Path to the temp file we used.
	;---------
	writeToOldestTempFile(textToWrite) {
		earliestPath := this.getOldestTempFile()
		
		this.replaceFileWithString(earliestPath, textToWrite)

		return earliestPath
	}

	;---------
	; DESCRIPTION:    Get the full path of the oldest temp file (or the first one that doesn't exist).
	;                 We're assuming this is the least important of our circulating set of temp files.
	; RETURNS:        Full filepath to the temp file
	;---------
	getOldestTempFile() {
		earliestTime := A_Now
		earliestPath := ""
		Loop, % this.MAX_TEMP_FILES {
			path := this.getTempFile(A_Index)

			; If we haven't hit the max number of temp files yet, just create the next one in line.
			if (!FileExist(path)) {
				earliestPath := path
				Break
			}
			
			; Otherwise, keep track of the oldest one - that's the one we'll replace.
			fileTime := FileGetTime(path)
			if(fileTime < earliestTime) {
				earliestTime := fileTime
				earliestPath := path
			}
		}

		return earliestPath
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	static MAX_TEMP_FILES := 5 ; The maximum number of temp files that we'll generate before reusing them.

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

	;---------
	; DESCRIPTION:    Get the path to a specific temp file (used by getOldestTempFile).
	; PARAMETERS:
	;  num (I,REQ) - Numeric index of the file to use
	; RETURNS:        Full filepath to the temp file with the given index        
	;---------
	getTempFile(num) {
		return A_Temp "\ahkTemp" num ".txt"
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
