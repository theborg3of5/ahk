#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
; #NoTrayIcon
#SingleInstance force
; #Warn All


#Include <autoInclude>

commandLineArg = %1%
if(commandLineArg) {
	differences := gitZipUnzip(commandLineArg)
	if(differences.maxIndex() && (commandLineArg = "s"))
		DEBUG.popup("AHK zipfiles that have changed", differences)
	
	ExitApp
}

^+s::
	differences := gitZipUnzip("s")
	if(differences.maxIndex())
		DEBUG.popup("AHK zipfiles that have changed", differences)
	
	ExitApp
return

^z::
	gitZipUnzip("z")
	ExitApp
return

^u::
	gitZipUnzip("u")
	ExitApp
return

~!+x::ExitApp


; Function to check what's changed against reference versions, and update them as needed.
; zipOrUnzip can be "u", "z", or "s" (unzip, zip, status)
gitZipUnzip(zipOrUnzip) {
	rootPath      := reduceFilepath(A_LineFile, 2) ; Calculate our own root path on the fly as this script gets compiled (can't use the one from borgConfig.ahk).
	localRefPath  := rootPath "zip\LocalReference\"
	remoteZipPath := rootPath "zip\Remote\"
	iniFile       := "zipReferences.ini" ; In this directory.
	runNow        := true
	actions       := Object()
	fileNames     := Object()
	copyFromFiles := Object()
	copyToFiles   := Object()
	copyFromZips  := Object()
	copyToZips    := Object()
	; DEBUG.popup("Root", rootPath, "Local Ref", localRefPath, "Remote zip", remoteZipPath)
	
	fileList := TableList.parseFile(iniFile)
	; DEBUG.popup("TableList", fileList)
	
	; Status will act as zip, but not actually zip, instead compile results.
	if(zipOrUnzip = "s") {
		zipOrUnzip := "z"
		runNow := false
	}
	
	For i,f in fileList {
		if(zipOrUnzip = "z") {
			operation := "zip"
			curr      := rootPath      f["FILE"]
			currZip   := remoteZipPath f["ZIP"]
			ref       := localRefPath  f["REF_FILE"]
			refZip    := localRefPath  f["REF_ZIP"]
		} else if(zipOrUnzip = "u") {
			operation := "unzip"
			curr      := remoteZipPath f["ZIP"]
			currZip   := rootPath      f["FILE"]
			ref       := localRefPath  f["REF_ZIP"]
			refZip    := localRefPath  f["REF_FILE"]
		}
		
		; DEBUG.popup("Name", f["NAME"], "Current", curr, "Reference", ref, "Zip", currZip, "Reference Zip", refZip, "Different", compareFiles(curr, ref), "Full f array", f)
		
		if(compareFiles(curr, ref)) {
			; Record name.
			SplitPath, curr, fileName
			fileNames.Push(fileName)
			
			; Zip/unzip action.
			if(zipOrUnzip = "z")
				runString := """C:\Program Files\7-Zip\7z.exe"" u " currZip " " curr " -p"
			else if(zipOrUnzip = "u")
				runString := """C:\Program Files\7-Zip\7z.exe"" e " curr " -o" reduceFilepath(currZip, 1) " -aoa -p"
			actions.Push(runString)
			
			; Update reference version.
			copyFromFiles.Push(curr)
			copyToFiles.Push(ref)
			
			; Update reference version of the zip.
			copyFromZips.Push(currZip)
			copyToZips.Push(refZip)
		}
	}
	
	; DEBUG.popup("Run now", runNow, "Actions", actions, "Copy from files", copyFromFiles, "Copy to files", copyToFiles, "Copy from zips", copyFromZips, "Copy to zips", copyToZips)
	
	if(runNow && actions.MaxIndex()) {
		; Get password to use to open archives.
		prompt := "Enter password to use to " operation " these archives: `n`n"
		For i,f in fileNames {
			prompt .= f "`n"
		}
		
		height := 160 + (fileNames.MaxIndex() * 17)
		InputBox, pass, Password for archives, %prompt%, HIDE, , height
		
		if(pass && (ERRORLEVEL != 1)) {
			; Zip/unzip things.
			For i,a in actions {
				RunWait, % a pass
			}
			
			; Do filecopies as needed - update the file and zip ref versions.
			For i,f in copyFromFiles {
				toFile := copyToFiles[i]
				FileCopy, %f%, %toFile%, 1
			}
			For i,f in copyFromZips {
				toFile := copyToZips[i]
				FileCopy, %f%, %toFile%, 1
			}
		}
	}
	
	return fileNames
}