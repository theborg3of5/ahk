class Notepad {
	; #INTERNAL#
	
	;---------
	; DESCRIPTION:    Open a new instance of Notepad and set its content to the provided text.
	; PARAMETERS:
	;  text (I,REQ) - The text to add to the new window.
	;---------
	openNewInstanceWithText(text) {
		Config.runProgram("Notepad")
		
		titleString := "Untitled - Notepad " Config.windowInfo["Notepad"].titleString ; For a brand-new instance of notepad
		WinWaitActive, % titleString, , 5 ; 5s timeout
		if(!WinActive(titleString))
			WinActivate, % titleString ; Try to activate it if it ran but didn't activate for some reason
		if(!WinActive(titleString))
			return
		
		ControlSetText, Edit1, % text, A
	}
	; #END#
}
