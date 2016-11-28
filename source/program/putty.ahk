#IfWinActive, ahk_class PuTTY
	; Insert arbitrary text, inserting needed spaces to overwrite.
	^i::
		; Block and buffer input until {ENTER} is pressed.
		Input, textIn, , {Enter}
		
		; Get the length of the string we're going to add.
		inputLength := StrLen(textIn)
		
		; Insert that many spaces.
		Send, {Insert %inputLength%}
		
		; Actually send our input text.
		SendRaw, % textIn
	return
	
	; Normal paste, without all the inserting of spaces.
	^v::
		Send, +{Insert}
	return
	
	; Paste clipboard, insering spaces to overwrite first.
	$!v::
		; Get the length of the string we're going to add.
		inputLength := StrLen(clipboard)
		
		; Insert that many spaces.
		Send, {Insert %inputLength%}
		
		; Actually send our input text.
		SendRaw, % clipboard
	return
	
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
	
	{ ; Various commands.
		^z::
			SendRaw, d ^`%ZeW
			Send, {Enter}
		return
		
		^e::
			SendRaw, d ^e
			Send, {Enter}
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
		
		:*:.lock::
			SendRaw, w $$zlock^elibEALIB1(" ; Extra comment/quote here to fix syntax highlighting. "
		return
		
		:*:.unlock::
			SendRaw, w $$zunlock^elibEALIB1(" ; Extra comment/quote here to fix syntax highlighting. "
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
	
	; Fast Forward macro (Home + F9).
	F1::
		Send, {Home}
		Send, {F9}
		Sleep, 100
		Send, t{Enter}
	return
	
	; Allow reverse field navigation.
	+Tab::
		Send, {Left}
	return
#IfWinActive
