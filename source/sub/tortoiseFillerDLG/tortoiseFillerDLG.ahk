#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
trayInfo := new ScriptTrayInfo("AHK: TortoiseSVN DLG ID Filler", "turtle.ico", "turtleRed.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Sub, trayInfo)

SetTitleMatchMode, RegEx
global tortoiseTitleRegEx := "O)^C:\\EpicSource\\\d\.\d\\DLG-(\w+)[-\\].* - Commit - TortoiseSVN" ; O option to get match object instead of pseudo-array
global dlgFieldId     := "Edit2"
global messageFieldId := "Scintilla1"

SetTimer, MainLoop, -100 ; Run once, timer toggled by commonHotkeys' suspend hotkey.

MainLoop:
	WinWaitActive, % tortoiseTitleRegEx
	if(A_IsSuspended)
		return
	
	addDLGToCommitWindow()
	
	WinWaitNotActive, % tortoiseTitleRegEx ; Don't do it again until we leave and return to the window.
	if(A_IsSuspended)
		return
	
	SetTimer, MainLoop, -100 ; Run again
return

addDLGToCommitWindow() {
	if(ControlGetText(dlgFieldId) != "") ; If there's already something in the field, leave it be.
		return
		
	RegExMatch(WinGetActiveTitle(), tortoiseTitleRegEx, matchObj)
	rawDLGId := matchObj.value(1) ; First subpattern should be DLG ID that we're interested in.
	if(rawDLGId = "")
		return
	
	; Capitalize any letters in the DLG ID
	dlgId := ""
	Loop, Parse, rawDLGId
		dlgId .= StringUpper(A_LoopField)
	; DEBUG.popup("rawDLGId",rawDLGId, "dlgId",dlgId)
	
	ControlSetText, % dlgFieldId, % dlgId, A ; Plug in the DLG ID
	ControlFocus, % messageFieldId, A ; Focus the message field
}
