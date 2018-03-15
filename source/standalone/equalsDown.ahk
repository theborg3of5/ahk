#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#Include <includeCommon>
scriptHotkeyType := HOTKEY_TYPE_Standalone

; Set mouseover text for icon
Menu, Tray, Tip, 
(LTrim
	Equals+Down Sender
	Ctrl+R to prompt for how many Equals+Down keystrokes to send.
	
	Emergency Exit: Ctrl+Shift+Alt+Win+R
)

^r::
	InputBox, numToSend, Send Equals+Down Keystrokes, Enter how many times to send Equals+Down:
	if(!numToSend || ErrorLevel)
		return
	
	; Sanity checks
	if(!isNum(numToSend)) {
		MsgBox, Error: given value was not a number.
		return
	}
	if(numToSend < 1) {
		MsgBox, Error: given number is smaller than 1.
		return
	}
	
	; Confirmation if it's a really big number
	if(numToSend > 100) {
		MsgBox, 4, Delete page?, Are you sure you want to send Equals+Down %numToSend% times?
		IfMsgBox, No
			return
		else IfMsgBox, Cancel
			return
		else IfMsgBox, Timeout
			return
	}
	
	; Send the keystrokes
	Loop, % numToSend {
		Send, ={Down}
	}
return

#Include <commonHotkeys>
