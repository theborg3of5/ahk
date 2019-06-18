
replaceFileWithString(filePath, newContents) {
	if(!filePath)
		return
	
	FileDelete, % filePath
	if(newContents)
		FileAppend, % newContents, % filePath
}

saveClipboardToFile(filePath := "") {
	; If no path was given, prompt the user with a popup.
	if(!filePath)
		filePath := FileSelectFile("S", A_ScriptDir "\clips\*.clip", "What file should the clipboard be saved to?", "*.clip")
	if(!filePath)
		return
	
	FileAppend, %ClipboardAll%, %filePath%
}

sendFileWithClipboard(filePath := "") {
	; If no path was given, prompt the user with a popup.
	if(!filePath)
		filePath := FileSelectFile("S", A_ScriptDir "\clips\*.clip", "What file should be sent?")
	if(!filePath)
		return
	
	; Save off the current clipboard and blank it out so we can wait for it to be filled from the file.
	tempClip := ClipboardAll
	Clipboard := 
	
	readFileToClipboard(filePath)
	
	Send, ^v
	
	Sleep, 500 ; If this isn't delayed, it overwrites the clipboard before the paste actually happens.
	Clipboard := tempClip
}

; Read a file (which we assume is in clipboard format, saved from the clipboard) and put it on the clipboard.
readFileToClipboard(filePath := "") {
	; If no path was given, prompt the user with a popup.
	if(!filePath)
		filePath := FileSelectFile("S", , "What file should be placed on the clipboard?", "*.clip")
	if(!filePath)
		return
	
	clipboard := FileRead("*c " filePath) ; *c = clipboard-format file
	ClipWait, 5, 1
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

; Open a folder from config-defined tags.
openFolder(folderName) {
	folderPath := MainConfig.path[folderName]
	; DEBUG.popup("Folder name",folderName, "Path",folderPath)
	
	if(folderExists(folderPath))
		Run(folderPath)
}

sendFilePath(folderName := "", subPath := "") {
	sendFolderPath(folderName, subPath, , false)
}
sendUnixFolderPath(folderName := "", subPath := "") {
	sendFolderPath(folderName, subPath, "/")
}
sendFolderPath(folderName := "", subPath := "", slashChar := "\", trailingSlash := true) {
	folderPath := MainConfig.path[folderName]
	if(!folderPath)
		return
	
	; Append a further subPath if they gave that to us
	if(subPath) {
		folderPath := appendCharIfMissing(folderPath, slashChar)
		folderPath .= subPath
	}
	
	if(trailingSlash)
		folderPath := appendCharIfMissing(folderPath, slashChar)
	
	Send, % folderPath
}

selectFolder(folderName := "") {
	s := new Selector("folders.tls", MainConfig.machineSelectorFilter)
	path := s.select(folderName, "PATH")
	
	; DEBUG.popup("Path",path, "Replaced",MainConfig.replacePathTags(path))
	return MainConfig.replacePathTags(path)
}

; textToSearch should not have its quotes escaped yet (especially not by doubling or tripling them)
searchWithGrepWin(pathToSearch, textToSearch := "") {
	runPath := MainConfig.programInfo["GrepWin"].path " /regex:no"
	
	convertedPath := MainConfig.replacePathTags(pathToSearch)
	runPath .= " /searchpath:""" convertedPath " """ ; Extra space after path, otherwise trailing backslash escapes ending double quote
	
	if(textToSearch)
		runPath .= " /searchfor:""" escapeCharUsingChar(textToSearch, DOUBLE_QUOTE) """ /execute" ; Run it immediately if we got what to search for
	
	; DEBUG.popup("Path to search",pathToSearch, "Converted path",convertedPath, "To search",textToSearch, "Run path",runPath)
	Run(runPath)
}

searchWithEverything(textToSearch) {
	runPath := MainConfig.programInfo["Everything"].path
	
	if(textToSearch)
		runPath .= " -search " textToSearch
	
	Run(runPath)
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
	configFolder := MainConfig.path["AHK_CONFIG"]
	if(FileExist(configFolder "\local\" path))      ; Local folder (not version-controlled) inside of config
		return configFolder "\local\" path
	if(FileExist(configFolder "\ahkPrivate\" path)) ; Private folder (separately version-controlled) inside of config
		return configFolder "\ahkPrivate\" path
	if(FileExist(configFolder "\" path))            ; General config folder
		return configFolder "\" path
	
	return ""
}

; Clean out unwanted garbage strings from paths
cleanupPath(path) {
	path := StrReplace(path, "%20", A_Space) ; In case it's a URL'd file path
	return cleanupText(path, ["file:///", """"])
}

mapPath(path) {	
	; Convert paths to use mapped drive letters
	tl := new TableList(findConfigFilePath("mappedDrives.tl"))
	table := tl.getFilteredTable("MACHINE", MainConfig.machine)
	For i,row in table {
		if(stringContains(path, row["PATH"])) {
			path := StrReplace(path, row["PATH"], row["DRIVE_LETTER"] ":", , 1)
			Break ; Just match the first one.
		}
	}
	
	; DEBUG.popup("Updated path",path, "Table",table)
	return path
}

folderExists(folderPath) {
	return InStr(FileExist(folderPath), "D") ; Exists and is a directory
}

getParentFolder(path, levelsUp := 1) {
	outPath := removeStringFromEnd(path, "\") ; Make sure there's no trailing backslash, SplitPath assumes that involves a blank filename.
	
	Loop, % levelsUp {
		SplitPath(outPath, "", parentPath)
		outPath := parentPath
	}
	
	return outPath
}
