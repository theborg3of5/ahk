#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include %A_ScriptDir%\..\source\common\common.ahk
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)
progToast := new ProgressToast("First-time setup")

; Various paths needed throughout.
ahkRootPath    := FileLib.getParentFolder(A_ScriptDir)
userPath       := EnvGet("HOMEDRIVE") EnvGet("HOMEPATH")
tlSetupPath    := "setup.tls"
startupFolder  := ahkRootPath "\source"
mainAHKPath    := startupFolder "\main.ahk"

copyPaths := {}
copyPaths["..\template\includeCommon.ahk"] := A_MyDocuments "\AutoHotkey\Lib\includeCommon.ahk"
copyPaths["..\template\settings.ini"]      := ahkRootPath "\config\settings.ini"

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
; Debug.popup("Machine Info Selected", machineInfo)

; Pull the needed values from our selection.
progToast.nextStep("Reading values from selection")
tagsToReplace := {}
tagsToReplace["AHK_ROOT"]     := ahkRootPath
tagsToReplace["CONTEXT"]      := machineInfo["NEW_CONTEXT"]
tagsToReplace["MACHINE"]      := machineInfo["NEW_MACHINE"]
; Debug.popup("Finished tags to replace",tagsToReplace)

; Loop over files we need to process and put places.
progToast.nextStep("Processing files")
For fromPath,toPath in copyPaths {
	; Read it in.
	fileContents := FileRead(fromPath)
	
	; Replace any placeholder tags in the file contents.
	; Debug.popup("fromPath", fromPath, "toPath", toPath, "Starting contents", fileContents)
	fileContents := fileContents.replaceTags(tagsToReplace)
	; Debug.popup("fromPath",fromPath, "toPath",toPath, "Finished contents",fileContents)
	
	; Generate the folder path if needed.
	containingFolder := FileLib.getParentFolder(toPath)
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
	progToast.nextStep("Hiding .git files and folders")
	For _,name in gitNames {
		Loop, Files, %ahkRootPath%\*%name%, RDF
		{
			FileSetAttrib, +H, %A_LoopFileFullPath%
		}
	}
}

progToast.finish()

if(useSlimMode || GuiLib.showConfirmationPopup("Run now?"))
	Run(mainAHKPath, startupFolder)

ExitApp
