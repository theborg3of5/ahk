#IfWinActive, ahk_class PuTTY
	; Insert arbitrary text, inserting needed spaces to overwrite.
	^i::
		insertArbitraryText() {
			; Popup to get the text.
			textIn := InputBox("Insert text (without overwriting)", , , 500, 100)
			if(textIn = "")
				return
			
			; Get the length of the string we're going to add.
			inputLength := StrLen(textIn)
			
			; Insert that many spaces.
			Send, {Insert %inputLength%}
			
			; Actually send our input text.
			SendRaw, % textIn
		}
	
	; Normal paste, without all the inserting of spaces.
	^v::Send, +{Insert}
	
	; Disable breaking behavior for easy-to-hit-accidentally ^c, PuTTY already has a ^+c hotkey that works too.
	^c::return
	
	; Screen wipe
	^l::
		Send, !{Space}
		Send, t
		Send, {Enter}
	return
	^+l::
		Send, !{Space}
		Send, l
	return
	
	; Allow reverse field navigation.
	+Tab::
		Send, {Left}
	return
	
	; Open up settings window.
	!o::
		openPuttySettingsWindow()
	return
	
	; Open up the current log file.
	^+o::
		openCurrentLogFile() {
			logFilePath := GetPuttyLogFile()
			if(logFilePath)
				Run(logFilePath)
		}
	
	; Make page up/down actually move a page up/down (each Shift+Up/Down does a half a page).
	^PgUp::
		Send, +{PgUp 2}
	return
	^PgDn::
		Send, +{PgDn 2}
	return
	
	{ ; Various commands.
		^z::
			SendRaw, d ^`%ZeW
			Send, {Enter}
		return
		
		^e::
			Send, e{Space}
		return
		
		; $!e::
			; SendRaw, d ^EPIC
			; Send, {Enter}
		; return
		
		!e::
			SendRaw, d ^HB
			Send, {Enter}
			Send, ={Enter}
			Send, 4{Enter}
			Send, 1{Enter}
			Send, 1{Enter}
		return
		
		^+e::
			SendRaw, d ^EAVIEWID
			Send, {Enter}
		return
		
		; ^!e::
			; SendRaw, d ^`%ZeEPIC
			; Send, {Enter}
		; return
			
		^a::
			SendRaw, d ^`%ZeADMIN
			Send, {Enter}
		return
		
		^+d::
			SendRaw, d ^`%ZdTOOLS
			Send, {Enter}
		return
		
		^m::
			SendRaw, d ^EZMENU
			Send, {Enter}
		return
		
		^o::
			SendRaw, d ^EDTop
			Send, {Enter}
		return
		
		^h::
			SendRaw, d ^HB
			Send, {Enter}
		return
		
		!h::
			SendRaw, d ^HB
			Send, {Enter}
			Send, ={Enter}
			Send, 4{Enter}
			Send, 2{Enter}
		return
		
		^p::
			SendRaw, d ^PB
			Send, {Enter}
		return
		
		; Department edit hotkey.
		!d::
			SendRaw, d ^EPIC
			Send, {Enter 2}
			Send, 1{Enter}
			Send, 5{Enter}
		return
		
		; HSD edit hotkey.
		^+h::
			SendRaw, d ^HB
			Send, {Enter 2}
			Send, 4{Enter}
			Send, 2{Enter}
		return
		
		^+s::
			SendRaw, d ^KECR
			Send, {Enter}
			Send, 1{Enter}
		return
		
		::.lock::
			SendRaw, w $$zlock(" ; Extra comment/quote here to fix syntax highlighting. "
		return
		
		::.unlock::
			SendRaw, w $$zunlock(" ; Extra comment/quote here to fix syntax highlighting. "
		return
		
		:C1R:^XITEMSET::^XSETITEM
	}
#IfWinActive


; Opens the Change Settings menu for putty. 0x112 is WM_SYSCOMMAND, and
; 0x50 is IDM_RECONF, the change settings option. It's found in putty's
; source code in window.c:
; https://github.com/codexns/putty/blob/master/windows/window.c
openPuttySettingsWindow() {
	PostMessage, 0x112, 0x50, 0
}

; Modified from http://wiki.epic.com/main/PuTTY#AutoHotKey_for_PuTTY_Macros
getPuttyLogFile() {
	if(!WinActive("ahk_class PuTTY"))
		return ""
	
	openPuttySettingsWindow()
	
	; need to wait a bit for the popup to show up
	Sleep, 50 ; GDB TODO - replace this with a WinWait?
	
	Send, !g ; Category pane
	Send, l  ; Logging tree node
	Send, !f ; Log file name field
	
	logFile := getSelectedText()
	
	Send, !c ; Cancel
	return logFile
}
