

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
	
	if(folderPath && FileExist(folderPath))
		Run, % folderPath
}

sendFolderPath(folderName = "", subPath = "") {
	folderPath := selectFolder(folderName)
	
	if(!folderPath)
		return
	
	; Add a trailing backslash if there's not one already.
	if(SubStr(folderPath, 0) != "\")
		folderPath .= "\"
	
	; Append a further subPath if they gave that to us
	if(subPath) {
		folderPath .= subPath "\"
		if(SubStr(folderPath, 0) != "\") ; Trailing backslash on the end of the subPath, too.
			folderPath .= "\"
	}
	
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
