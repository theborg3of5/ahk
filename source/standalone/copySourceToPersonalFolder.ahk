#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.

#Include <includeCommon>
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)
progToast := new ProgressToast("Copy source to personal folder").blockingOn()

; { sourcePath, destinationPath }
folders := {}
folders[Config.path["AHK_ROOT"]]    := Config.path["EPIC_PERSONAL"] "\ahk"
folders[Config.path["AHK_PRIVATE"]] := Config.path["EPIC_PERSONAL"] "\ahkPrivate"
folders[Config.path["AHK_TEST"]]    := Config.path["EPIC_PERSONAL"] "\ahkTest"

main        := Config.path["AHK_ROOT"]
private     := Config.path["AHK_PRIVATE"]
test        := Config.path["AHK_TEST"]

destMain    := Config.path["EPIC_PERSONAL"] "\ahk"
destPrivate := Config.path["EPIC_PERSONAL"] "\ahkPrivate"
destTest    := Config.path["EPIC_PERSONAL"] "\ahkTest"

foldersDisplay := ""
For source, destination in folders
	foldersDisplay := foldersDisplay.appendLine(source " => " destination)
confirmationMessage := "
	( LTrim
		Are you sure you want to replace the contents of these folders?

		" foldersDisplay "
	)"
if(!GuiLib.showConfirmationPopup(confirmationMessage, "Delete and replace"))
	ExitApp

; Delete existing contents of destination folder
progToast.nextStep("Removing existing folders and files from destination")
For _, destination in folders {
	Loop, Files, %destination%\*, F ; Files
		FileDelete, % A_LoopFilePath
	Loop, Files, %destination%\*, D ; Directories
		FileRemoveDir, % A_LoopFilePath, 1 ; 1-Delete recursively
}

; Copy over everything from source except git-related stuff.
progToast.nextStep("Copying files from source to destination")
gitNames := [".git", ".gitignore", ".gitattributes"]
For source, destination in folders {
	SetWorkingDir, % source ; Set working directory and use a relative file pattern so that A_LoopFilePath has only the folders at the start for FileCopy.
	Loop, Files, *, FDR ; All files and folder, recursing into folders
	{
		; Don't copy over git-related files/folders.
		if(A_LoopFilePath.containsAnyOf(gitNames)) ; Check for names in full path so we catch files under ignored folders
			Continue
		
		; Create folders and copy over files
		destinationPath := destination "\" A_LoopFilePath
		if(FileLib.folderExists(A_LoopFilePath))
			FileCreateDir, % destinationPath
		else
			FileCopy, % A_LoopFilePath, % destinationPath
	}
}

progToast.finish()
ExitApp
