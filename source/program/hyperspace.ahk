; Hyperspace main window
#If Hyperspace.isAnyVersionActive()
	$F5::+F5 ; Make F5 work everywhere by mapping it to shift + F5.
	
	; Login hotkeys.
	^+t::Hyperspace.login(Config.private["WORK_ID"], Config.private["WORK_PASSWORD"])
	^!t::Hyperspace.login(Config.private["WORK_ID"], Config.private["WORK_PASSWORD"], false) ; Don't use last department (=)
	
	^!c::Hyperspace.openCurrentDisplayHTML() ; Open the current display's HTML in IE.
#If

; HSWeb debugging - Hyperspace main window or IE
#If Hyperspace.isAnyVersionActive() || WinActive("Hyperspace ahk_exe IEXPLORE.EXE") || WinActive("Hyperspace ahk_exe chrome.exe")
	^!d::Send, % Config.private["EPIC_HSWEB_CONSOLE_HOTKEY"]
#If

; HSWeb Debug Console
#If WinActive(Config.private["EPIC_HSWEB_CONSOLE_TITLESTRING"])
	::.trace::
		Send, % Config.private["EPIC_HSWEB_FORCE_TRACE_COMMAND"]
		Send, {Left 2} ; Get inside parens and quotes
	return
#If

class Hyperspace {
	; #INTERNAL#
	
	;---------
	; DESCRIPTION:    Determine whether any version of Hyperspace is active.
	; RETURNS:        true if a Hyperspace is active, False otherwise.
	; NOTES:          We can't use the Config.isWindowActive() here because the EXE is version-
	;                 specific and we want to support any version.
	;---------
	isAnyVersionActive() {
		if(Config.isWindowActive("EMC2")) ; Don't count EMC2 towards this.
			return false
		
		if(WinActive("ahk_class ThunderRT6FormDC"))
			return true
		if(WinActive("ahk_class ThunderFormDC"))
			return true
		if(WinActive("ahk_class ThunderRT6MDIForm"))
			return true
		if(WinActive("ahk_class ThunderMDIForm"))
			return true
		
		return false
	}
	
	;---------
	; DESCRIPTION:    Log into Hyperspace with the provided username and password.
	; PARAMETERS:
	;  username          (I,REQ) - Username to log in with
	;  password          (I,REQ) - Password to log in with
	;  useLastDepartment (I,OPT) - Set to false to not use the last department when logging in (so stop at that screen)
	;---------
	login(username, password, useLastDepartment := true) {
		Send, %username%{Tab}
		Send, %password%{Enter}
		HotkeyLib.releaseAllModifiers()
		
		if(!useLastDepartment)
			return
		
		Send, ={Enter}
		Send, {Space}
	}
	
	;---------
	; DESCRIPTION:    Grab the HTML from the current display in Hyperspace, save it off to a file
	;                 and open it in IE for debugging.
	; SIDE EFFECTS:   Modifies the local HTML debug output file.
	;---------
	openCurrentDisplayHTML() {
		html := Hyperspace.getCurrentDisplayHTML()
		filePath := Config.private["LOCAL_HTML_DEBUG_OUTPUT"]
		FileDelete, %filePath%
		FileAppend, %html%, %filePath%
		Config.runProgram("Internet Explorer", filePath)
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Get the HTML from the current display in Hyperspace.
	; RETURNS:        The HTML from the current display in Hyperspace.
	;---------
	getCurrentDisplayHTML() {
		copyHTMLFunction := ObjBindMethod(Hyperspace, "copyDisplayHTML")
		return ClipboardLib.getWithFunction(copyHTMLFunction)
	}
	
	;---------
	; DESCRIPTION:    Copy the current display's HTML to the clipboard.
	;---------
	copyDisplayHTML() {
		; Grab the HTML with HTMLGrabber hotkey.
		SendPlay, , ^!+c
	}
	; #END#
}
