; Allow keyboard control of mouse.

#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)

; Setup.
keyboardControl := false

#If !keyboardControl
	^!+Space::
		keyboardControl := true
	return
#If

#If keyboardControl
	^!+Space::
		keyboardControl := false
	return
	
	Space::LButton
	Left::
		MouseMove, -5, 0, , R
	return
	Right::
		MouseMove, 5, 0, , R
	return
	Up::
		MouseMove, 0, -5, , R
	return
	Down::
		MouseMove, 0, 5, , R
	return
	
	^a::
		Send, {Click Down}
	return
	^+a::
		Send, {Click Up}
	return
#If
