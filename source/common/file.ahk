

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


