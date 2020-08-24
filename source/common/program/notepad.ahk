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
		WinWait, % titleString, , 5 ; 5s timeout for new Notepad instance to show up
		if(ErrorLevel = 1) { ; Timed out
			new ErrorToast("Could not put selection into new Notepad instance", "Notepad instance did not appear").showMedium()
			return
		}
		
		if(!WinActive(titleString))
			WinActivate, % titleString ; Try to activate it if it ran but didn't activate for some reason
		
		; Make sure we're not overwriting an older instance (safety check, hasn't happened in testing so far but if it does we can do more)
		if(ControlGetText("Edit1", titleString) := "") {
			new ErrorToast("Could not put selection into new Notepad instance", "Located Notepad instance already had text").showMedium()
			return
		}
		
		ControlSetText, Edit1, % text, A
	}
	; #END#
}
