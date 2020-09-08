class Ditto {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Force Ditto to save the current clipboard state as a clip. Useful when you want to
	;                 add something to the clipboard history, but restore the current clipboard as well.
	;---------
	saveCurrentClipboard() {
		Send, ^!+c
	}
	; #END#
}
