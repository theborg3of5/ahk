; Script used to update the includes needed for some of the scripts in this directory.

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, force
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Include <includeCommon>
scriptHotkeyType := HOTKEY_TYPE_Standalone

rootPath         := reduceFilepath(A_ScriptDir, 1)
commonFolder     := rootPath "source\common\"
includesFileName := "_NeededIncludes"

Loop, Files, %includesFileName%, R ; Recurse, only look for files (not folders)
{
	; Pull out where this file is.
	includesListFile := A_LoopFileFullPath
	copyToFolder     := A_LoopFileDir "\"
	; DEBUG.popup("Includes file", includesListFile, "Includes folder", copyToFolder)
	
	; Read the file and build the list of common files we need to copy in.
	fileNames := []
	Loop, Read, %includesListFile%
	{
		fileName = %A_LoopReadLine% ; Using = (not :=) because trimming leading/trailing space.
		if(!fileName) ; Empty line, move on to next line.
			Continue
		
		fileNames.Push(fileName)
	}
	; DEBUG.popup("List of filepaths to copy", fileNames)
	
	; Loop over those files and copy them in.
	fileErrors := []
	For i,f in fileNames {
		; If fileName is actually a full path, only add the filename to destinationFile (since it already adds a preceding path.
		if(stringContains(f, "\"))
			SplitPath, f, file
		else
			file := f
		
		sourceFile      := commonFolder f
		destinationFile := copyToFolder file
		
		; Does the source file exist?
		if(!FileExist(sourceFile)) {
			fileErrors.Push("Source file not found", f)
			Continue
		}
		
		; Delete the file if it already exists in the destination folder.
		if(FileExist(destinationFile)) {
			FileDelete, %destinationFile%
			if(ErrorLevel) {
				fileErrors.Push("Could not delete destination file to replace", destinationFile)
				Continue
			}
		}
		
		; Try to copy it into the folder.
		FileCopy, %sourceFile%, %copyToFolder%, 0
		if(ErrorLevel) {
			fileErrors.Push("Could not copy file to destination", ["Source file", sourceFile, "Destination file", destinationFile])
			Continue
		}
		
		; DEBUG.popup("Successfully copied source file", sourceFile, "To destination folder", copyToFolder)
	}
	
	; Show the user any errors that we found.
	if(fileErrors.length())
		DEBUG.popup("Errors while trying to copy files", "", fileErrors*)
}


ExitApp

; Universal suspend, reload, and exit hotkeys.
#Include <commonHotkeys>
