SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance force  ; Ensures that if this script is running, running it again replaces the first instance.

#Include %A_ScriptDir%\..\source\common\_includeCommon.ahk
setCommonHotkeysType(HOTKEY_TYPE_Standalone)

; Various paths needed throughout.
ahkRootPath    := getParentFolder(A_ScriptDir)
userPath       := getParentFolder(A_Desktop)
tlSetupPath    := "setup.tls"
startupFolder  := ahkRootPath "\source"
mainAHKPath    := startupFolder "\main.ahk"

tagsToReplace := []
tagsToReplace["ROOT"]            := ahkRootPath
tagsToReplace["WHICH_MACHINE"]   := ""
tagsToReplace["MENU_KEY_ACTION"] := ""
tagsToReplace["MEDIA_PLAYER"]    := ""

copyPaths := []
copyPaths["includeCommon.ahk.master"] := userPath "\Documents\AutoHotkey\Lib\includeCommon.ahk"
copyPaths["commonHotkeys.ahk.master"] := userPath "\Documents\AutoHotkey\Lib\commonHotkeys.ahk"
copyPaths["settings.ini.master"]      := ahkRootPath "\config\local\settings.ini"

gitNames := []
gitNames.Push(".git")
gitNames.Push(".gitignore")
gitNames.Push(".gitattributes")

; Check for command line arguments - which machine to use, and whether to suppress the "run now?" prompt.
machineChoice := A_Args[1]
useSlimMode   := A_Args[2]

; Get info for the machine that we're setting up for (will drive specific values in settings.ini)
s := new Selector(tlSetupPath)
machineInfo := s.select(machineChoice)

if(!machineInfo)
	ExitApp
; DEBUG.popup("Machine Info Selected", machineInfo)

t := new Toast()
t.showPersistent()

; Pull the needed values from our selection.
t.setText("Reading values from selection...")
For tag,_ in tagsToReplace {
	machineValue := machineInfo[tag]
	if(machineValue != "")
		tagsToReplace[tag] := machineValue
}
; DEBUG.popup("Finished tags to replace",tagsToReplace)

; Loop over files we need to process and put places.
t.setText("Processing files...")
For fromPath,toPath in copyPaths {
	; Read it in.
	fileContents := FileRead(fromPath)
	
	; Replace any placeholder tags in the file contents.
	; DEBUG.popup("fromPath", fromPath, "toPath", toPath, "Starting contents", fileContents)
	for tag,value in tagsToReplace
		StringReplace, fileContents, fileContents, <%tag%>, %value%, A
	; DEBUG.popup("fromPath",fromPath, "toPath",toPath, "Finished contents",fileContents)
	
	; Generate the folder path if needed.
	containingFolder := getParentFolder(toPath)
	if(!FileExist(containingFolder))
		FileCreateDir, %containingFolder%
	
	; Delete the file if it already exists.
	if(FileExist(toPath))
		FileDelete, %toPath%
	
	; Put the file where it's supposed to be.
	FileAppend, %fileContents%, %toPath%
}

if(!useSlimMode) {
	; Hide all .git system files and folders, for a cleaner appearance.
	t.setText("Hiding .git files and folders...")
	For _,name in gitNames {
		Loop, Files, %ahkRootPath%\*%name%, RDF
		{
			FileSetAttrib, +H, %A_LoopFileFullPath%
		}
	}
}

t.close()

if(useSlimMode) {
	shouldRun := true
} else {
	MsgBox, 4, , Run now?
	IfMsgBox Yes
		shouldRun := true
}
if(shouldRun)
	Run(mainAHKPath, startupFolder)

ExitApp

; Universal suspend, reload, and exit hotkeys.
#Include %A_ScriptDir%\..\source\common\_commonHotkeys.ahk