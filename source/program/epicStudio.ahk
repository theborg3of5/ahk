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
	
	; Duplicate Line.
	; ^d::
		; Send, {End}{Shift Down}{Home}{Shift Up}
		; ; Send, ^c
		; ; Sleep, 100
		; line := getSelectedText()
		
		; Send, {End}{Enter}
		; SendRaw, %line%
		; Send, {Up}{End}
	; return
	
	; ; Debug, auto-search for workstation ID.
	$F5::
		esRunDebug("ws:" epicComputerName)
	return
	
	; Debug, auto-search for workstation ID and Reflection exe.
	F6::
		esRunDebug("ws:" epicComputerName) ; " exe:" epicReflectionExe)
	return
	
	; Debug, auto-search for workstation ID and EpicD exe (aka Hyperspace).
	F7::
		esRunDebug("ws:" epicComputerName) ; " exe:" epicHyperspaceExeStart)
	return
	
	; Debug, auto-search for workstation ID and VB exe.
	F8::
		esRunDebug("ws:" epicComputerName) ; " exe:" epicVBExe)
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
					
					Send, % searchString
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
		
		states := ["active"]
		titles := ["", "[Debug]"]
		texts := [epicReflectionExe, epicHyperspaceExeStart, epicVBExe]
		
		return isWindowInStates(states, titles, texts, 2, "Slow")
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

	; GUI input for Chronicles Data Operation GENERATE code.
	:*:`;cdo::
		Gui, Add, Text, , Type: 
		Gui, Add, Text, , Tag: 
		Gui, Add, Text, , INI: 
		Gui, Add, Text, , Lookback: 
		Gui, Add, Text, , Global: 
		Gui, Add, Text, , Items: 
		
		Gui, Add, Edit, vType x100 ym, Load
		Gui, Add, Edit, vTag,
		Gui, Add, Edit, vINI,
		Gui, Add, Edit, vLookback,
		Gui, Add, Edit, vGlobal,
		Gui, Add, Edit, vItems,
		
		;Gui, Font,, Courier New
		Gui, Add, Button, Default, Generate
		Gui, Show,, Generate CDO Comment
	return

	ButtonGenerate:
		Gui, Submit
		
		; Make sure we're on a clean line.
		Send, {Down}{Up}{End}{Backspace}
		SendRaw, % ";;#GENERATE#"
		Send, {Enter}
		
		Send, {Space} ; Indent the following lines by one space.
		
		SendRaw, % "Type: " Type
		Send, {Enter}
		SendRaw, % "Tag: " Tag
		Send, {Enter}
		SendRaw, % "INI: " INI
		Send, {Enter}
		if(Lookback) {
			SendRaw, % "Lookback: " Lookback
			Send, {Enter}
		}
		if(Global) {
			SendRaw, % "Global: " Global
			Send, {Enter}
		}
		SendRaw, % "Items:"
		Send, {Enter}
		SendRaw, % Items
		Send, {Enter}
		
		Send, {Backspace} ; Get rid of the indent for the final line.
		
		SendRaw, % ";#ENDGEN#"
		
		Gui, Destroy
	return
#IfWinActive
