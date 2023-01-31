#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include %A_ScriptDir%\common\common.ahk
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)
progToast := new ProgressToast("First-time setup")

; Various paths needed throughout.
ahkRootPath    := FileLib.getParentFolder(A_ScriptDir, 1)
userPath       := EnvGet("HOMEDRIVE") EnvGet("HOMEPATH")
startupFolder  := ahkRootPath "\source"
mainAHKPath    := startupFolder "\main.ahk"

; Check for command line arguments - which machine to use, and whether to suppress the "run now?" prompt.
machineChoice := A_Args[1]
useSlimMode   := A_Args[2]

; Settings INI file
progToast.nextStep("Settings file")
machineInfo := selectSettings(machineChoice)
if(!machineInfo)
	ExitApp
iniPath := ahkRootPath "\config\settings.ini"
IniWrite(iniPath, "Main", "CONTEXT", machineInfo["NEW_CONTEXT"])
IniWrite(iniPath, "Main", "MACHINE", machineInfo["NEW_MACHINE"])

; Library pointer script
progToast.nextStep("Library pointer script")
pointerContents := "
	( LTrim
		; This acts as a pointer that any file can find, which points to the correct location of the common folder and its scripts.
		#Include " ahkRootPath "\source\common\common.ahk
	)"
includeLibFolder := A_MyDocuments "\AutoHotkey\Lib"
if(!FileLib.createFolderIfNoExist(includeLibFolder, true)) {
	Toast.ShowError("AHK documents lib folder doesn't exist and we couldn't create it.")
	ExitApp
}
FileLib.replaceFileWithString(includeLibFolder "\includeCommon.ahk", pointerContents)

if(!useSlimMode) {
	; Hide all .git system files and folders, for a cleaner appearance.
	progToast.nextStep("Hiding .git files and folders")
	For _,name in [".git", ".gitignore", ".gitattributes"] {
		Loop, Files, %ahkRootPath%\*%name%, RDF
		{
			FileSetAttrib, +H, %A_LoopFileFullPath%
		}
	}
}

progToast.finish()

; In slim mode, make sure any old instances are closed before running new ones.
if(useSlimMode) {
	; From https://www.autohotkey.com/board/topic/77272-close-all-ahk-scripts-except-one/
	For process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where name = 'Autohotkey.exe' and not CommandLine like '%" "firstSetup.ahk" "%' ")
		Process, Close, % process.ProcessId
}

if(useSlimMode || GuiLib.showConfirmationPopup("Run now?"))
	Run(mainAHKPath, startupFolder)

ExitApp

; Use a Selector to key into the settings we need.
selectSettings(machineChoice) {
	s := new Selector().setTitle("Select Machine to set up:")
	s.addChoice(new SelectorChoice({ NAME:"Home Desktop" , ABBREV:["desk", "HOME_DESKTOP"], NEW_CONTEXT:"HOME", NEW_MACHINE:"HOME_DESKTOP" }))
	s.addChoice(new SelectorChoice({ NAME:"Home Laptop"  , ABBREV:["hlap", "HOME_LAPTOP" ], NEW_CONTEXT:"HOME", NEW_MACHINE:"HOME_DESKTOP" }))
	s.addChoice(new SelectorChoice({ NAME:"Work Desktop" , ABBREV:["work", "WORK_DESKTOP"], NEW_CONTEXT:"WORK", NEW_MACHINE:"WORK_DESKTOP" }))
	s.addChoice(new SelectorChoice({ NAME:"Work VDI"     , ABBREV:["vdi" , "WORK_VDI"    ], NEW_CONTEXT:"WORK", NEW_MACHINE:"WORK_VDI"     }))
	return s.select(machineChoice)
}