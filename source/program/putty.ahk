#IfWinActive, ahk_class PuTTY
	; Insert arbitrary text, inserting needed spaces to overwrite.
	^i::
		insertArbitraryText() {
			; Block and buffer input until {ENTER} is pressed.
			textIn := Input(, "{Enter}")
			
			; Get the length of the string we're going to add.
			inputLength := StrLen(textIn)
			
			; Insert that many spaces.
			Send, {Insert %inputLength%}
			
			; Actually send our input text.
			SendRaw, % textIn
		}
	
	; Normal paste, without all the inserting of spaces.
	^v::Send, +{Insert}
	
	; Disable breaking behavior for ^c, replace with a harder-to-accidentally-press hotkey.
	^c::return
	^+c::Send, ^c
	
	; ; Paste clipboard, insering spaces to overwrite first.
	; $!v::
		; ; Get the length of the string we're going to add.
		; inputLength := StrLen(clipboard)
		
		; ; Insert that many spaces.
		; Send, {Insert %inputLength%}
		
		; ; Actually send our input text.
		; SendRaw, % clipboard
	; return
	
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
	
	; Open up settings window.
	!o::
		openPuttySettingsWindow()
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
		
		:*:.lock::
			SendRaw, w $$zlock(" ; Extra comment/quote here to fix syntax highlighting. "
		return
		
		:*:.unlock::
			SendRaw, w $$zunlock(" ; Extra comment/quote here to fix syntax highlighting. "
		return
		
		:C1R*:^XITEMSET::^XSETITEM
	}
	
	{ ; Pasting ZR/ZLs.
		:*:.zrv::
			SendRaw, `;zcode
			Send, {Enter}
			Send, 0{Enter}
		return
		:*:.zrr::
			SendRaw, `;zrun searchCode("","","",$c(16))
			Send, {Enter}
			Send, q{Enter}
		return
	}
	
	; Allow reverse field navigation.
	+Tab::
		Send, {Left}
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
	
	^!p::attachAllPuttyWindowsToMTPutty()
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

attachAllPuttyWindowsToMTPutty() {
	activateProgram("MTPutty")
	titleString := getProgramTitleString("MTPutty")
	if(!WinActive(titleString))
		WinActivate, % titleString
	
	Sleep, 500
	Send, ^t
	
	WinWaitActive, Attach ahk_class TfrmAttach
	Send, {Tab 2}{Down} ; Focus list of sessions and select the first one
	
	SendMessage, % LVM_GETITEMCOUNT, 1, 0, TListView1, A ; gives the no. of rows
	numRows := ErrorLevel
	; DEBUG.popup("Number of rows",numRows)
	
	numRows-- ; Subtract 1 since the first row is already selected.
	Send, {Shift Down}{Down %numRows%}{Shift Up} ; Select all orphaned sessions
	Send, {Enter} ; Accept
}
