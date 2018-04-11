SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance force  ; Ensures that if this script is running, running it again replaces the first instance.

#Include %A_ScriptDir%\..\source\common
#Include commandFunctions.ahk
#Include io.ahk
#Include data.ahk
#Include debug.ahk
#Include epic.ahk
#Include file.ahk
#Include gui.ahk
#Include HTTPRequest.ahk
#Include runCommands.ahk
#Include selector.ahk
#Include selectorRow.ahk
#Include string.ahk
#Include tableList.ahk
#Include tableListMod.ahk
#Include tray.ahk
#Include window.ahk
setCommonHotkeysType(HOTKEY_TYPE_Standalone)

; Various paths needed throughout.
ahkRootPath    := reduceFilepath(A_ScriptDir, 1)
userPath       := reduceFilepath(A_Desktop, 1)
tlSetupPath    := "setup.tl"
startupFolder  := ahkRootPath "\source"
mainAHKPath    := startupFolder "\main.ahk"

tagsToReplace := []
tagsToReplace["ROOT"]            := ahkRootPath
tagsToReplace["WHICH_MACHINE"]   := ""
tagsToReplace["MENU_KEY_ACTION"] := ""

copyPaths := []
copyPaths["includeCommon.ahk.master"] := userPath "\Documents\AutoHotkey\Lib\includeCommon.ahk"
copyPaths["commonHotkeys.ahk.master"] := userPath "\Documents\AutoHotkey\Lib\commonHotkeys.ahk"
copyPaths["settings.ini.master"]      := ahkRootPath "\config\local\settings.ini"
copyPaths["test.ahk.master"]          := ahkRootPath "\test\test.ahk"

gitNames := []
gitNames.Push(".git")
gitNames.Push(".gitignore")
gitNames.Push(".gitattributes")


; Prompt the user for which computer this is.
machineInfo := doSelect(tlSetupPath)
if(!machineInfo) {
	MsgBox, No machine given, exiting setup...
	ExitApp
}
; DEBUG.popup("Machine Info Selected", machineInfo)

; Pull the needed values from our selection.
For tag,v in tagsToReplace {
	machineValue := machineInfo[tag]
	if(machineValue)
		tagsToReplace[tag] := machineValue
}
; DEBUG.popup("Finished tags to replace",tagsToReplace)

; Loop over files we need to process and put places.
For from,to in copyPaths {
	; Read it in.
	FileRead, fileContents, %from%
	
	; Replace any palceholder tags in the file contents.
	; DEBUG.popup("From", from, "To", to, "Starting contents", fileContents)
	For tag,value in tagsToReplace {
		if(IsObject(value))
			value := arrayJoin(value)
		StringReplace, fileContents, fileContents, <%tag%>, %value%, A
	}
	; DEBUG.popup("From",from, "To",to, "Finished contents",fileContents)
	
	; Generate the folder path if needed.
	containingFolder := reduceFilepath(to, 1)
	if(!FileExist(containingFolder))
		FileCreateDir, %containingFolder%
	
	; Delete the file if it already exists.
	if(FileExist(to))
		FileDelete, %to%
	
	; Put the file where it's supposed to be.
	FileAppend, %fileContents%, %to%
}

; Hide all .git system files and folders, for a cleaner appearance.
For i,n in gitNames {
	Loop, Files, %ahkRootPath%*%n%, RDF
	{
		FileSetAttrib, +H, %A_LoopFileFullPath%
	}
}

MsgBox, 4, , Run now?
IfMsgBox Yes
	Run(%mainAHKPath%, %startupFolder%)

ExitApp

; Universal suspend, reload, and exit hotkeys.
#Include _commonHotkeys.ahk
