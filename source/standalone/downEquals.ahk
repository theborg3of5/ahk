#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#Include <autoInclude>

; State flag and icons
global suspended := 0
; setUpTrayIconsSimple("suspended", "hash.ico", "redHash.ico")

; Set mouseover text for icon
Menu, Tray, Tip, 
(LTrim
	Down+Equals Sender
	Ctrl+R to prompt for how many down+equals keystrokes to send.
	
	Emergency Exit: Ctrl+Shift+Alt+Win+R
)

^r::
	InputBox, numToSend, Send Down+Equals Keystrokes, Enter how many times to send Down+Equals:
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
		MsgBox, 4, Delete page?, Are you sure you want to send Down+Equals %numToSend% times?
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

~!+x::ExitApp
