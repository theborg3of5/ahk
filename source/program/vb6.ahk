; Hotkeys for VB6 IDE.

; Find popup
#IfWinActive, Find ahk_class #32770
	 ^g::
	^+g::
		WinClose, A ; Close the find window
		HotkeyLib.sendCatchableKeys(A_ThisHotkey) ; Send hotkey again
	return
#IfWinActive

; Main editor
#If Config.isWindowActive("VB6")
	; Back and (sort of - actually jump to definition) forward in history.
	!Left:: Send, ^+{F2}
	!Right::Send,  +{F2}
	
	; Find next/previous.
	 ^g::Send, {F3}
	^+g::
		Send, +{F3}
		
		; If we're getting the "wrap around to the end to continue searching?" popup, always say yes.
		WinWaitActive, % "Microsoft Visual Basic ahk_class #32770", , 0.5
		if(WinActive("Microsoft Visual Basic ahk_class #32770"))
			Send, y ; Yes
	return
	
	; Comment/uncomment
	 ^`;::VB6.clickUsingMode(126, 37, "Client")
	^+`;::VB6.clickUsingMode(150, 39, "Client")
	
	; Delete current line
	^d::VB6.deleteCurrentLine()
	
	; Close current 'window' within VB.
	^w::VB6.closeCurrentFile()
	
	; Redo, not yank.
	 ^y::
	^+z::
		Send, !e
		Sleep, 100
		Send, r
	return
	
	; Make (compile).
	^+b::
		Send, !f
		Sleep, 100
		Send, k
	return
	
	; Remap debug hotkeys.
	 F10::Send,  +{F8} ; Step over
	 F11::Send,   {F8} ; Step into
	+F11::Send, ^+{F8} ; Step out of
	 F12::Send,  ^{F8} ; Run to cursor.
	
	; Epic VB Parse Addin.
	^+p::
		Send, !a
		Sleep, 100
		Send, {Up 2}{Enter}
	return
	
	; Components, References windows.
	$^r::Send, ^t
	^+r::
		Send, !p
		Sleep, 100
		Send, n
	return
	
	; Add contact comments
	 ^8::VB6.addContactComment()
	^+8::VB6.addContactCommentForHeader()
	^!8::VB6.addContactCommentNoDash()
	
	; Triple ' hotkey for procedure header, like ES.
	::'''::
		Send, !a
		Sleep, 100
		Send, {Up}{Enter}
		Send, !p
	return
	
	; Comment and indentation for new lines.
	 ^Enter::VB6.addNewCommentLineWithIndent()   ; Normal line
	^+Enter::VB6.addNewCommentLineWithIndent(15) ; Function headers (lines up with edge of description, etc.)
	
	; Code vs. design swap.
	Pause::VB6.toggleCodeAndDesign()
	
	; Add basic error handler stuff.
	^+e::VB6.addErrorHandlerForCurrentFunction()
#If
