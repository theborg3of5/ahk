; Hyperspace hotkeys.

#If Hyperspace.isAnyVersionActive()
	$F5::+F5 ; Make F5 work everywhere by mapping it to shift + F5.
	
	; Login hotkeys.
	^+t::Hyperspace.login(MainConfig.private["WORK_ID"], MainConfig.private["WORK_PASSWORD"])
	^!t::Hyperspace.login(MainConfig.private["WORK_ID"], MainConfig.private["WORK_PASSWORD"], false) ; Don't use last department (=)
	
	^!c::Hyperspace.openCurrentDisplayHTML() ; Open the current display's HTML in IE.
#If

class Hyperspace {

; ==============================
; == Public ====================
; ==============================
	;---------
	; DESCRIPTION:    Determine whether any version of Hyperspace is active.
	; RETURNS:        true if a Hyperspace is active, False otherwise.
	; NOTES:          We can't use the MainConfig.isWindowActive() here because the EXE is version-
	;                 specific and we want to support any version.
	;---------
	isAnyVersionActive() {
		if(MainConfig.isWindowActive("EMC2")) ; Don't count EMC2 towards this.
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
		releaseAllModifierKeys()
		
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
		filePath := MainConfig.private["LOCAL_HTML_DEBUG_OUTPUT"]
		FileDelete, %filePath%
		FileAppend, %html%, %filePath%
		MainConfig.runProgram("Internet Explorer", filePath)
	}
	
	
; ==============================
; == Private ===================
; ==============================
	;---------
	; DESCRIPTION:    Get the HTML from the current display in Hyperspace.
	; RETURNS:        The HTML from the current display in Hyperspace.
	;---------
	getCurrentDisplayHTML() {
		; Save off the clipboard to restore and wipe it for our own use.
		ClipSaved := ClipboardAll
		Clipboard := ""
		
		; Grab the HTML with HTMLGrabber hotkey.
		SendPlay, , ^+!c
		Sleep, 100
		
		; Get it off of the clipboard and restore the clipboard.
		textFound := clipboard
		Clipboard := ClipSaved
		ClipSaved = ; Free memory
		
		return textFound
	}
}