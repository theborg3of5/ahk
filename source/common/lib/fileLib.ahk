; File and folder utility functions.

class FileLib {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Check whether a folder exists at the given path.
	; PARAMETERS:
	;  folderPath (I,REQ) - The path to check for a folder.
	; RETURNS:        true if it exists, false otherwise.
	;---------
	static folderExists(folderPath) {
		return InStr(FileExist(folderPath), "D") ; Exists and is a directory
	}
	;---------
	; DESCRIPTION:    Check whether a folder exists at the given path.
	;                 Wrapper for folderExists with a more obvious name.
	; PARAMETERS:
	;  folderPath (I,REQ) - The path to check for a folder.
	; RETURNS:        true if it exists, false otherwise.
	;---------
	static isFolder(path) {
		return this.folderExists(path)
	}
	
	;---------
	; DESCRIPTION:    Get the parent of the provided path.
	; PARAMETERS:
	;  path     (I,REQ) - The path to start with.
	;  levelsUp (I,OPT) - How many levels to go up (where 1 is the parent of that path). Defaults to 1.
	; RETURNS:        The parent (or higher depending of levelsUp) folder.
	;---------
	static getParentFolder(path, levelsUp := 1) {
		outPath := path.removeFromEnd("\")

		Loop levelsUp {
			SplitPath(outPath, , &parentPath)
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
	static isFilePath(path) {
		if path.startsWithAnyOf(["file://", "\\"])
			return true

		if path.sub(2, 2) = ":\"
			return true

		if path.startsWith("/") && !path.startsWith("//")
			return true

		return false
	}

	;---------
	; DESCRIPTION:    Clean out unwanted garbage strings from paths, map to network drives, map from Unix to Windows paths.
	; PARAMETERS:
	;  path (I,REQ) - The path to clean.
	; RETURNS:        The cleaned-up and mapped path.
	;---------
	static cleanupPath(path) {
		if StringLib.isURL(path)
			return path

		path := path.clean(['"'])

		if path.matchesRegEx("file:\/+", &protocolMatch) {
			protocol := protocolMatch[]
			path := path.removeFromStart(protocol)
			if protocol = "file://"
				path := "\\" path

			path := StringLib.decodeFromURL(path)
			path := path.replace("/", "\")
		}

		mappedDrives := TableList("mappedDrives.tl").getTable()
		for _, row in mappedDrives {
			if path.contains(row["PATH"]) {
				path := path.replaceOne(row["PATH"], row["DRIVE_LETTER"] ":")
				break
			}
		}

		if !FileExist(path) {
			movedFolders := TableList("movedFolders.tl").getTable()
			for _, row in movedFolders {
				if path.startsWith(row["OLD_FOLDER"]) {
					path := path.replaceOne(row["OLD_FOLDER"], row["NEW_FOLDER"])
					Toast.ShowMedium("Redirected path (" row["NAME"] ")")
					break
				}
			}
		}

		path := FileLib.mapUnixPathToWindows(path)

		return path
	}

	;---------
	; DESCRIPTION:    Check whether the given path is an (absolute) Unix path (as opposed to a Windows path).
	; PARAMETERS:
	;  path (I,REQ) - The path to check
	; RETURNS:        true/false
	;---------
	static isUnixPath(path) {
		return path.startsWith("/")
	}

	;---------
	; DESCRIPTION:    Map a Unix path to its Windows equivalent (where we have the mappings to do so).
	; PARAMETERS:
	;  unixPath (I,REQ) - The full Unix path (starting with /)
	; RETURNS:        A Windows path if we mapped successfully, otherwise the original unixPath.
	;---------
	static mapUnixPathToWindows(unixPath) {
		if !FileLib.isUnixPath(unixPath)
			return unixPath

		unixMappings := TableList("unixFolderMappings.tl").getTable()
		for _, unixMap in unixMappings {
			if unixPath.startsWith(unixMap["UNIX"]) {
				unixPath := unixPath.replaceOne(unixMap["UNIX"], unixMap["WINDOWS"])
				unixPath := unixPath.replace("/", "\")
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
	static mapWindowsPathToUnix(windowsPath) {
		unixMappings := TableList("unixFolderMappings.tl").getTable()
		for _, unixMap in unixMappings {
			if windowsPath.startsWith(unixMap["WINDOWS"]) {
				windowsPath := windowsPath.replaceOne(unixMap["WINDOWS"], unixMap["UNIX"])
				windowsPath := windowsPath.replace("\", "/")
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
	static findConfigFilePath(path) {
		if !path
			return ""

		if FileExist(path)
			return path

		configPath := Config.path["AHK_CONFIG"] "\" path
		if FileExist(configPath)
			return configPath
		privatePath := Config.path["AHK_PRIVATE"] "\" path
		if FileExist(privatePath)
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
	static fileLinesToArray(fileName, dropWhitespace := false) {
		lines := []
		Loop Read, fileName {
			if dropWhitespace
				lines.InsertAt(A_Index, A_LoopReadLine.withoutWhitespace())
			else
				lines.InsertAt(A_Index, A_LoopReadLine)
		}
		return lines
	}
	
	;---------
	; DESCRIPTION:    Replace the given file's contents with the provided string.
	; PARAMETERS:
	;  filePath    (I,REQ) - The path to the file to update.
	;  newContents (I,REQ) - The contents to replace the file's contents with.
	;---------
	static replaceFileWithString(filePath, newContents) {
		if !filePath
			return

		try FileDelete(filePath)
		FileAppend(newContents, filePath)
	}

	;---------
	; DESCRIPTION:    Create the given folder path (and its parents) if it doesn't already exist.
	; PARAMETERS:
	;  folderPath  (I,REQ) - The path of the folder to check/create.
	;  silentForce (I,OPT) - By default we'll prompt the user before creating anything - pass true here to suppress that.
	; RETURNS:        true if the folder (already or newly) exists, false if we couldn't create it or the user declined.
	;---------
	static createFolderIfNoExist(folderPath, silentForce := false) {
		if FileLib.folderExists(folderPath)
			return true

		if !silentForce && !GuiLib.showConfirmationPopup("This folder does not exist:`n" folderPath "`n`nCreate it?", "Folder does not exist")
			return false

		if !FileLib.createFolderIfNoExist(FileLib.getParentFolder(folderPath), true)
			return false

		try {
			DirCreate(folderPath)
			return true
		}
		return false
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
	static sendPath(folderName, subPath := "", slashChar := "\", addTrailingSlash := false) {
		if folderName = ""
			return

		folderPath := Config.path[folderName]
		if !folderPath
			return

		if subPath {
			folderPath := folderPath.appendIfMissing(slashChar)
			folderPath .= subPath
		}

		if addTrailingSlash
			folderPath := folderPath.appendIfMissing(slashChar)

		Send(folderPath)
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
	static findCommonFolder(path1, path2) {
		folder1 := FileLib.reduceToFolder(path1)
		folder2 := FileLib.reduceToFolder(path2)

		if folder1 = folder2
			return folder1
		
		overlapPath := StringLib.findStringOverlapFromStart(path1, path2)

		if overlapPath.endsWith("\")
			return overlapPath
		
		return FileLib.getParentFolder(overlapPath).appendIfMissing("\")
	}

	;---------
	; DESCRIPTION:    Replace the oldest temp file (of our circulating set of temp files) with the given text.
	; PARAMETERS:
	;  textToWrite (I,REQ) - The text to use
	; RETURNS:        Path to the temp file we used.
	;---------
	static writeToOldestTempFile(textToWrite) {
		earliestPath := this.getOldestTempFile()
		
		this.replaceFileWithString(earliestPath, textToWrite)

		return earliestPath
	}

	;---------
	; DESCRIPTION:    Get the full path of the oldest temp file (or the first one that doesn't exist).
	;                 We're assuming this is the least important of our circulating set of temp files.
	; RETURNS:        Full filepath to the temp file
	;---------
	static getOldestTempFile() {
		earliestTime := A_Now
		earliestPath := ""
		Loop this.MAX_TEMP_FILES {
			path := this.getTempFile(A_Index)

			if !FileExist(path) {
				earliestPath := path
				break
			}

			fileTime := FileGetTime(path)
			if fileTime < earliestTime {
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
	static reduceToFolder(path) {
		if FileLib.folderExists(path)
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
	static getTempFile(num) {
		return A_Temp "\ahkTemp" num ".txt"
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
