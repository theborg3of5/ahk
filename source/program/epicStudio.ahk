; EpicStudio hotkeys and helpers.
#IfWinActive, ahk_exe EpicStudio.exe
	; TLG Hotkey.
	^t::Send, %epicID%

	; Better access to INTermediate code.
	!i::ControlSend, , ^+v

	; Reopen recently closed file.
	^+t::Send, !ffr{Enter}
	
	; Make copy line location !c.
	!c::Send, ^!{Numpad9}
	
	; ; Debug, auto-search for workstation ID.
	~F5::
		if(isESDebugging())
			return
		
		WinWait, Attach to Process, , 5
		if(ErrorLevel)
			return
		
		ControlGet, currFilter, Line, 1, Edit1, A
		if(currFilter) {
			ControlFocus, Edit1, A
			return ; There's already something plugged into the field, so just put the focus there in case they want to change it.
		}
		
		; Pick the radio button for "Other existing process:" and pick it.
		otherProcessRadioButtonClass := WindowsForms10.BUTTON.app.0.2bf8098_r9_ad11
		ControlFocus, %otherProcessRadioButtonClass%, A
		ControlSend, %otherProcessRadioButtonClass%, {Space}, A
		
		; Focus the filter field and send what we want to send.
		ControlFocus, Edit1, A
		Send, % "ws:" epicComputerName
		Send, {Enter}{Down}
	return
	
	; Run EpicStudio in debug mode, given a particular string to search for.
	esRunDebug(searchString) {
		; Always send F5, even in debug mode - continue.
		Send, {F5}
		
		; Don't try and debug again if ES is already doing so.
		if(!isESDebugging()) {
			WinWait, Attach to Process, , 5
			if(!ErrorLevel) {
				ControlGet, currFilter, Line, 1, Edit1, A
				if(!currFilter) {
					ControlFocus, WindowsForms10.BUTTON.app.0.141b42a_r12_ad11, A
					ControlSend, WindowsForms10.BUTTON.app.0.141b42a_r12_ad11, {Space}, A
					ControlFocus, Edit1, A
					
					Send, % "ws:" epicComputerName
					Send, {Enter}{Down}
				}
			} else {
				; DEBUG.popup("ES Debug WinWait ErrorLevel", ErrorLevel)
			}
		
		}
	}
	
	; Checks if ES is already in debug mode or not.
	isESDebugging() {
		global epicReflectionExe, epicHyperspaceExeStart, epicVBExe
		texts := [epicReflectionExe, epicHyperspaceExeStart, epicVBExe]
		
		return isWindowInState("active", "", texts, 2, "Slow")
	}
	
	; Link routine to currently open (in object explorer tab) DLG.
	^+l::
		WinGetText, text
		; DEBUG.popup("Window Text", text)
		
		Loop, Parse, text, `n
		{
			if(SubStr(A_LoopField, 1, 4) = "DLG ") {
				objectName := A_LoopField
				dlgNum := SubStr(objectName, 4)
				; DEBUG.popup(A_Index, "On line", objectName, "Found object", dlgNum, "With DLG number")
				break
			}
		}
		
		if(!objectName)
			return
		
		Send, ^l
		WinWaitActive, Link DLG, , 5
		Send, % dlgNum
		Send, {Enter}
	return
	
	; Get routine name from title to clipboard.
	^+c::
		WinGetTitle, title
		; MsgBox, % title
		
		StringSplit, splitTitle, title, (, %A_Space%
		; MsgBox, % splitTitle1
		
		clipboard := splitTitle1
	return
	
	
	:*:.forloop::
		Send, {Shift Down}{Left}{Shift Up}
		if(getSelectedText() = ";")
			Send, {Backspace} ; Start with no semicolon in front.
		else
			Send, {End}
		
		doMForLoop()
	return
#IfWinActive
