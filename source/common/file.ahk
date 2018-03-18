
saveClipboardToFile(filePath = "") {
	; If no path was given, prompt the user with a popup.
	if(!filePath)
		filePath := FileSelectFile("S", A_ScriptDir "\clips\*.clip", "What file should the clipboard be saved to?", "*.clip")
	if(!filePath)
		return
	
	FileAppend, %ClipboardAll%, %filePath%
}

sendFileWithClipboard(filePath = "") {
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
readFileToClipboard(filePath = "") {
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

; Reduces a given filepath down by the number of levels given, from right to left.
; Path will not end with a trailing backslash.
reduceFilepath(path, levelsDown) {
	outPath := ""
	splitPath := StrSplit(path, "\") ; Start with this exact file (file.ahk).
	pathSize := splitPath.MaxIndex()
	For i,p in splitPath {
		if(i = (pathSize - levelsDown + 1))
			Break
		
		if(outPath)
			outPath .= "\"
		outPath .= p
	}
	; DEBUG.popup("Split Path", splitPath, "Size", pathSize, "Final path", outPath)
	
	return outPath
}

; Select a folder based on input (or prompt if no input) and open it.
openFolder(folderName = "") {
	folderPath := selectFolder(folderName)
	; DEBUG.popup("Folder name",folderName, "Path",folderPath)
	
	if(folderPath && FileExist(folderPath))
		Run, % folderPath
}

sendFilePath(folderName = "", subPath = "") {
	sendFolderPath(folderName, subPath, false)
}
sendUnixFolderPath(folderName = "", subPath = "") {
	sendFolderPath(folderName, subPath, , true)
}
sendFolderPath(folderName = "", subPath = "", trailingSlash = true, isUnixPath = false) {
	folderPath := selectFolder(folderName)
	if(!folderPath)
		return
	
	if(isUnixPath)
		slashChar := "/"
	else
		slashChar := "\"
	
	; Append a further subPath if they gave that to us
	if(subPath) {
		folderPath := appendCharIfMissing(folderPath, slashChar)
		folderPath .= subPath
	}
	
	if(trailingSlash)
		folderPath := appendCharIfMissing(folderPath, slashChar)
	
	Send, % folderPath
}

selectFolder(folderName = "") {
	filter := MainConfig.getMachineTableListFilter()
	s := new Selector("folders.tl", "", filter)
	
	if(folderName)
		folderPath := s.selectChoice(folderName)
	else
		folderPath := s.selectGui()
	
	return MainConfig.replacePathTags(folderPath)
}

searchWithGrepWin(pathToSearch, textToSearch = "") {
	runPath := MainConfig.getProgram("grepWin", "PATH") " /regex:no"
	
	convertedPath := MainConfig.replacePathTags(pathToSearch)
	runPath .= " /searchpath:""" convertedPath " """ ; Extra space after path, otherwise trailing backslash escapes ending double quote
	
	if(textToSearch)
		runPath .= "/searchfor:""" textToSearch """ /execute" ; Run it immediately if we got what to search for
	
	; DEBUG.popup("Path to search",pathToSearch, "Converted path",convertedPath, "To search",textToSearch, "Run path",runPath)
	Run, % runPath
}

searchWithEverything(textToSearch) {
	runPath := MainConfig.getProgram("Everything", "PATH")
	
	if(textToSearch)
		runPath .= " -search " textToSearch
	
	Run, % runPath
}
	
findTLFilePath(path) {
	if(!path)
		return ""
	
	; In the current folder, or full path
	if(FileExist(path))
		return path
	
	; If there's an Includes folder in the same directory, check in there as well.
	if(FileExist("Includes\" path))
		return "Includes\" path
	
	; Default folder for selector INIs
	if(FileExist(MainConfig.getFolder("AHK_ROOT") "\config\" path))
		return MainConfig.getFolder("AHK_ROOT") "\config\" path
	
	this.errPop("File doesn't exist", path)
	return ""
}
