#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include %A_ScriptDir%\..\source\common\_includeCommon.ahk
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)

; Various paths needed throughout.
ahkRootPath    := FileUtils.getParentFolder(A_ScriptDir)
userPath       := EnvGet("HOMEDRIVE") EnvGet("HOMEPATH")
tlSetupPath    := "setup.tls"
startupFolder  := ahkRootPath "\source"
mainAHKPath    := startupFolder "\main.ahk"

copyPaths := {}
copyPaths["includeCommon.ahk.master"] := userPath "\Documents\AutoHotkey\Lib\includeCommon.ahk"
copyPaths["settings.ini.master"]      := ahkRootPath "\config\local\settings.ini"

gitNames := []
gitNames.Push(".git")
gitNames.Push(".gitignore")
gitNames.Push(".gitattributes")

; Check for command line arguments - which machine to use, and whether to suppress the "run now?" prompt.
machineChoice := A_Args[1]
useSlimMode   := A_Args[2]

; Get info for the machine that we're setting up for (will drive specific values in settings.ini)
machineInfo := new Selector(tlSetupPath).select(machineChoice)
if(!machineInfo)
	ExitApp
; DEBUG.popup("Machine Info Selected", machineInfo)

t := new Toast()
t.show()

; Pull the needed values from our selection.
t.setText("Reading values from selection...")
tagsToReplace := {}
tagsToReplace["ROOT"]            := ahkRootPath
tagsToReplace["CONTEXT"]         := machineInfo["NEW_CONTEXT"]
tagsToReplace["MACHINE"]         := machineInfo["NEW_MACHINE"]
tagsToReplace["MEDIA_PLAYER"]    := machineInfo["MEDIA_PLAYER"]
; DEBUG.popup("Finished tags to replace",tagsToReplace)

; Loop over files we need to process and put places.
t.setText("Processing files...")
For fromPath,toPath in copyPaths {
	; Read it in.
	fileContents := FileRead(fromPath)
	
	; Replace any placeholder tags in the file contents.
	; DEBUG.popup("fromPath", fromPath, "toPath", toPath, "Starting contents", fileContents)
	fileContents := fileContents.replaceTags(tagsToReplace)
	; DEBUG.popup("fromPath",fromPath, "toPath",toPath, "Finished contents",fileContents)
	
	; Generate the folder path if needed.
	containingFolder := FileUtils.getParentFolder(toPath)
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
