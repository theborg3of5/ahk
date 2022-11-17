#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include %A_ScriptDir%\..\common\common.ahk
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)
progToast := new ProgressToast("First-time setup")

; Various paths needed throughout.
ahkRootPath    := FileLib.getParentFolder(A_ScriptDir, 2)
userPath       := EnvGet("HOMEDRIVE") EnvGet("HOMEPATH")
tlSetupPath    := "setup.tls"
startupFolder  := ahkRootPath "\source"
mainAHKPath    := startupFolder "\main.ahk"

; Check for command line arguments - which machine to use, and whether to suppress the "run now?" prompt.
machineChoice := A_Args[1]
useSlimMode   := A_Args[2]

; Settings INI file
machineInfo := new Selector(tlSetupPath).select(machineChoice)
if(!machineInfo)
	ExitApp
progToast.nextStep("Creating settings file")
iniPath := ahkRootPath "\config\settings.ini"
IniWrite(iniPath, "Main", "CONTEXT", machineInfo["NEW_CONTEXT"])
IniWrite(iniPath, "Main", "MACHINE", machineInfo["NEW_MACHINE"])

; Library pointer script
progToast.nextStep("Setting up library pointer script")
pointerContents := "
	( LTrim
		; This acts as a pointer that any file can find, which points to the correct location of the common folder and its scripts.
		#Include " ahkRootPath "\source\common\common.ahk
	)"
pointerContents := pointerContents.replaceTag("AHK_ROOT", ahkRootPath)
FileLib.replaceFileWithString(A_MyDocuments "\AutoHotkey\Lib\includeCommon.ahk", pointerContents)

if(!useSlimMode) {
	; Hide all .git system files and folders, for a cleaner appearance.
	progToast.nextStep("Hiding .git files and folders")
	For _,name in [".git", ".gitignore", ".gitattributes"]] {
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
