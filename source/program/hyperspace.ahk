; Hyperspace hotkeys.

#If WinActive("ahk_class ThunderRT6FormDC") || WinActive("ahk_class ThunderFormDC") || WinActive("ahk_class ThunderRT6MDIForm") || WinActive("ahk_class ThunderMDIForm")
	; Make F5 work everywhere by mapping it to shift + F5.
	$F5::+F5
	
	; TLG Hotkey.
	^t::
		Send, %epicID%
	return
	
	; Allow my ^s save reflex to live on. Return to the field we were in when we finish.
	^s::
		ControlSend_Return("", "!s")
	return
	
	; Login hotkeys.
	^+t::
		Send, %epicID%{Tab}
		Send, %epicHyperspacePass%{Enter}
		Send, ={Enter}
	return
	^!t::
		Send, %epicID%{Tab}
		Send, %epicHyperspacePass%{Enter}
	return
	
	{ ; HTML things.
		; Grab the html, stuff it in a file, and show it in IE for dev tools.
		^!c::
			html := getHyperspaceHTML()
			FileDelete, %localDevHTMLOutputFilePath%
			FileAppend, %html%, %localDevHTMLOutputFilePath%
			Run, C:\Program Files\Internet Explorer\iexplore.exe %localDevHTMLOutputFilePath%
		return
		
		; With XML debug on - grabs the path to the tempdata folder from the bottom of the screen, opens it.
		^!o::
			Send, ^a
			text := getSelectedText()
			Loop, Parse, text, `n, `r
			{
				; DEBUG.popup(A_LoopField)
				if(isPath(A_LoopField)) {
					filePath := A_LoopField
					break
				}
			}
			
			; DEBUG.popup("Found path", filePath)
			if(filePath)
				Run, % filePath
		return
	}
#If

; Epic environment list window - title contains "Connection Status", and EXE is one of Snapper, Hyperspace (partial EXE name match), VB, or Citrix.
#If isEpicEnvironmentListWindow()
	; Shows a list to the user, who can decide which environment they want to launch, then it will find and focus that one in the environment list window.
	^f::
		data := Selector.select("epic_environments.tl", "RET_DATA")
		pickEnvironment(data["ENV_TITLE"], data["ENV_GROUP"])
	return
#If


isEpicEnvironmentListWindow() {
	; Title always contains "Connection Status".
	if(!isWindowInState("active", "Connection Status", , 2))
		return false
	
	; Executable matches one of the following
	if(exeActive("Snapper.exe")) ; Snapper
		return true
	if(exeActive("EpicD", true)) ; Any version of Hyperspace (second parameter is partial name matching)
		return true
	if(exeActive("VB6.EXE"))     ; VB6
		return true
	if(exeActive("WFICA32.exe")) ; Citrix
		return true
	if(exeActive("mstsc.exe"))   ; Remote desktop
	
	return false
}

getHyperspaceHTML() {
	; Save off the clipboard to restore and wipe it for our own use.
	ClipSaved := ClipboardAll
	Clipboard := 
	
	; Grab the HTML with HTMLGrabber hotkey.
	SendPlay, , ^+!c
	Sleep, 100
	
	; Get it off of the clipboard and restore the clipboard.
	textFound := clipboard
	Clipboard := ClipSaved
	ClipSaved = ; Free memory
	
	return textFound
}

hyperspaceNotLoadedYet() {
	if(WinActive("Hyperspace - Test") ; Hyperspace 2012, FNDEX.
		|| WinActive("Hyperspace - Training") ; PTC Hyperspace Project Dev.
		|| WinActive("Hyperspace - Foundations Lab QA") ; PTC Hyperspace Project QA.
		|| WinActive("Development Training Lab - TRNTRACK") ; EMC2 SteamTrainTrack.
	|| 0) {
		return true
	}
	
	return false
}
