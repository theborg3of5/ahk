; Allow keyboard control of mouse.

SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance force  ; Ensures that if this script is running, running it again replaces the first instance.
#Include <includeCommon>
scriptHotkeyType := HOTKEY_TYPE_Standalone

; Setup.
keyboardControl := false

#If !keyboardControl
	^+!Space::
		keyboardControl := true
	return
#If

#If keyboardControl
	^+!Space::
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

#Include <commonHotkeys>
