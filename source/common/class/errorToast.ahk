/* Extension of Toast with specific overrides for styles and text format. --=
	
	Usage:
;		new ErrorToast("<problem>", "<why>", "<any mitigation we did>").showMedium()
	
	Example:
;		; Couldn't send the built text to the specified window because it doesn't exist, so we put it on the clipboard instead.
;		new ErrorToast("Could not send text to window", "Window does not exist: " windowName, "Put built text on the clipboard instead: " clipboard).showMedium()
	
*/ ; =--

class ErrorToast extends Toast {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Create a new ErrorToast object.
	; PARAMETERS:
	;  problemMessage    (I,REQ) - Text about what the problem is (what happened or weren't we able to do?)
	;  errorMessage      (I,OPT) - Technical error text (what happened code-wise?)
	;  mitigationMessage (I,OPT) - What we did instead (what did we do to make the failure less impactful?)
	;---------
	__New(problemMessage, errorMessage := "", mitigationMessage := "") {
		toastText := this.buildErrorText(problemMessage, errorMessage, mitigationMessage)
		overrides := this.getStyleOverrides()
		
		this.initialize(toastText, overrides)
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Build the toast text to show for the error based on which bits of info we got.
	; PARAMETERS:
	;  problemMessage    (I,REQ) - Text about what the problem is (what happened or weren't we able to do?)
	;  errorMessage      (I,OPT) - Technical error text (what happened code-wise?)
	;  mitigationMessage (I,OPT) - What we did instead (what did we do to make the failure less impactful?)
	; RETURNS:        A single string including whatever was populated. Format:
	;                   problemMessage:
	;                   errorMessage
	;                   
	;                   mitigationMessage
	; NOTES:          If any of the bits are missing, their respective line will not be included (for
	;                 mitigationMessage, that includes the extra newline too).
	;---------
	buildErrorText(problemMessage, errorMessage, mitigationMessage) {
		text := problemMessage
		text := text.appendPiece(errorMessage,      ":`n")
		text := text.appendPiece(mitigationMessage, "`n`n")
		
		return text
	}
	
	;---------
	; DESCRIPTION:    Get the style overrides for the toast so that it looks more severe (since
	;                 this is an error).
	; RETURNS:        Array of style overrides to pass to Toast.buildGui
	;---------
	getStyleOverrides() {
		overrides := {}
		overrides["BACKGROUND_COLOR"] := "000000" ; Black
		overrides["FONT_COLOR"]       := "CC9900" ; Dark yellow/gold
		overrides["FONT_SIZE"]        := 22
		overrides["MARGIN_X"]         := 6
		overrides["MARGIN_Y"]         := 1
		overrides["TEXT_ALIGN"]       := "Right"
		
		return overrides
	}
	; #END#
}
