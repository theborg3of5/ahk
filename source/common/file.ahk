

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
	
	; Replace any special tags with real paths.
	folderPath := replaceTags(folderPath, {"AHK_ROOT":ahkRootPath, "USER_ROOT":userPath})
	
	if(folderPath && FileExist(folderPath))
		Run, % folderPath
}

searchWithGrepWin(pathToSearch, textToSearch = "") {
	runPath := MainConfig.getProgram("grepWin", "PATH") " /regex:no"
	
	; runPath := replaceTags
	runPath .= " /searchpath:""" pathToSearch " """ ; Extra space after path, otherwise trailing backslash escapes ending double quote
	
	if(textToSearch)
		runPath .= "/searchfor:""" textToSearch """ /execute" ; Run it immediately if we got what to search for
	
	Run, % runPath
}

replacePathTags(path) {
	global configFolder
	newPath := path
	
	settings["CHARS"] := []
	settings["CHARS", "IGNORE"] := ["=", "#", "+"]
	tl := new TableList(configFolder "\folders.tl", settings)
	filteredTable := tl.getFilteredTable("MACHINE", MainConfig.getMachine())
	
	; GDB TODO some sort of pre-processing ot get calculated paths (<USER_ROOT>, <AHK_ROOT>) replaced
	
	For i,folder in filteredTable {
		newPath := replaceTags(newPath, {folder["TAG"]:}) ; GDB todo figure out how associative arrays work with variable indices
	}
}
