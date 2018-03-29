; Hyperspace hotkeys.

#If WinActive("ahk_class ThunderRT6FormDC") || WinActive("ahk_class ThunderFormDC") || WinActive("ahk_class ThunderRT6MDIForm") || WinActive("ahk_class ThunderMDIForm")
	; Make F5 work everywhere by mapping it to shift + F5.
	$F5::+F5
	
	; Login hotkeys.
	^+t::hyperspaceLogin(MainConfig.getPrivate("WORK_ID"), MainConfig.getPrivate("WORK_PASSWORD"))
	^!t::hyperspaceLogin(MainConfig.getPrivate("WORK_ID"), MainConfig.getPrivate("WORK_PASSWORD"), false)
	hyperspaceLogin(username, password, useLastDepartment = true) {
		Send, %username%{Tab}
		Send, %password%{Enter}
		if(useLastDepartment)
			Send, ={Enter}
	}
	
	{ ; HTML things.
		; Grab the html, stuff it in a file, and show it in IE for dev tools.
		^!c::
			openHyperspaceHTML() {
				html := getHyperspaceHTML()
				filePath := MainConfig.getPrivate("LOCAL_HTML_DEBUG_OUTPUT")
				FileDelete, %filePath%
				FileAppend, %html%, %filePath%
				Run("C:\Program Files\Internet Explorer\iexplore.exe " filePath)
			}
		return
	}
#If

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
