

; Read in a file and return it as an array.
fileLinesToArray(fileName) {
	lines := Object()
	
	Loop Read, %fileName% 
	{
		lines[A_Index] := A_LoopReadLine
	}
	
	return lines
}

; Compares two files.
compareFiles(file1, file2) {
	compared := runAndReturnOutput("fc " file1 " " file2)
	; MsgBox, % file1 "`n" file2 "`n" compared
	if(inStr(compared, "FC: no differences encountered")) {
		return false
	} else {
		return true
	}
}

; Reduces a given filepath down by the number of levels given, from right to left.
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

; Query this machine's folders TL file (prompt the user if nothing given) and open it.
openFolder(folderName = "") {
	global configFolder
	
	filter := MainConfig.getMachineTableListFilter()
	s := new Selector("folders.tl", "", filter)
	
	if(folderName)
		folderPath := s.selectChoice(folderName)
	else
		folderPath := s.selectGui()
	
	folderPath := replaceSystemTags(folderPath)
	
	if(folderPath && FileExist(folderPath))
		Run, % folderPath
}

replacePathTags(path) { ; GDB TODO move to MainConfig.
	global configFolder
	
	tl := new TableList(configFolder "\folders.tl")
	folderTable := tl.getFilteredTable("MACHINE", MainConfig.getMachine())
	
	; Build tag-indexed array of paths.
	folderPaths := []
	For i,folder in folderTable {
		tag := folder["TAG"]
		if(!tag) ; We only care about folders with defined tags. Also filters out headers and Selector settings.
			Continue
		
		folderPaths[tag] := replaceSystemTags(folder["PATH"])
	}
	
	; Replace tags in the input path
	return replaceTags(path, folderPaths)
}

replaceSystemTags(path) { ; GDB TODO move to MainConfig?
	global ahkRootPath,userPath
	
	; Tags pre-defined by MainConfig
	replaceAry := []
	replaceAry["AHK_ROOT"]  := ahkRootPath
	replaceAry["USER_ROOT"] := userPath
	
	; Replace any special tags with real paths.
	return replaceTags(path, replaceAry)
}

searchWithGrepWin(pathToSearch, textToSearch = "") {
	runPath := MainConfig.getProgram("grepWin", "PATH") " /regex:no"
	
	convertedPath := replacePathTags(pathToSearch)
	runPath .= " /searchpath:""" convertedPath " """ ; Extra space after path, otherwise trailing backslash escapes ending double quote
	
	if(textToSearch)
		runPath .= "/searchfor:""" textToSearch """ /execute" ; Run it immediately if we got what to search for
	
	; DEBUG.popup("Path to search",pathToSearch, "Converted path",convertedPath, "To search",textToSearch, "Run path",runPath)
	Run, % runPath
}
