class Notepad {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Open a new instance of Notepad and set its content to the provided text.
	; PARAMETERS:
	;  text (I,REQ) - The text to add to the new window.
	;---------
	openNewInstanceWithText(text) {
		Config.runProgram("Notepad")
		newNotepadWindowTitleString := "Untitled - Notepad " Config.windowInfo["Notepad"].titleString
		WinWaitActive, % newNotepadWindowTitleString, , 5 ; 5s timeout
		if(!WinActive(newNotepadWindowTitleString))
			WinActivate, % newNotepadWindowTitleString ; Try to activate it if it ran but didn't activate for some reason
		if(!WinActive(newNotepadWindowTitleString))
			return
		
		ControlSetText, Edit1, % text, A
	}
	; #END#
}
