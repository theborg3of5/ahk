; A group of wrappers for built-in setter functions that return the original value.

class Setters {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Set the title match mode (see TitleMatchMode "enum" for values).
	; PARAMETERS:
	;  new (I,REQ) - The new title match mode.
	; RETURNS:        The original title match mode.
	;---------
	titleMatchMode(new) { ; Only returns the actual mode - if you want the original match mode speed value, use Setters.titleMatchSpeed() instead.
		old := A_TitleMatchMode
		SetTitleMatchMode, % new
		return old
	}
	
	;---------
	; DESCRIPTION:    Set the title match speed (Slow/Fast).
	; PARAMETERS:
	;  new (I,REQ) - The new title match speed.
	; RETURNS:        The original title match speed.
	;---------
	titleMatchSpeed(new) {
		old := A_TitleMatchModeSpeed
		SetTitleMatchMode, % new
		return old
	}
	
	;---------
	; DESCRIPTION:    Set whether we should detect hidden windows (On/Off).
	; PARAMETERS:
	;  new (I,REQ) - The new setting.
	; RETURNS:        The original value.
	;---------
	detectHiddenWindows(new) {
		old := A_DetectHiddenWindows
		DetectHiddenWindows, % new
		return old
	}
	
	;---------
	; DESCRIPTION:    Set the current working directory.
	; PARAMETERS:
	;  new (I,REQ) - The new working directory.
	; RETURNS:        The original working directory.
	;---------
	workingDirectory(new) {
		old := A_WorkingDir
		SetWorkingDir, % new
		return old
	}
	
	;---------
	; DESCRIPTION:    Set the CoordMode (Screen/Relative/Window/Client) for a particular target type
	;                 (ToolTip/Pixel/Mouse/Caret/Menu).
	; PARAMETERS:
	;  new (I,REQ) - The new CoordMode.
	; RETURNS:        The original CoordMode.
	;---------
	coordMode(targetType, relativeTo := "") {
		if(targetType = "ToolTip")
			old := A_CoordModeToolTip
		if(targetType = "Pixel")
			old := A_CoordModePixel
		if(targetType = "Mouse")
			old := A_CoordModeMouse
		if(targetType = "Caret")
			old := A_CoordModeCaret
		if(targetType = "Menu")
			old := A_CoordModeMenu
		
		CoordMode, % targetType, % relativeTo
		
		return old
	}
	
	;---------
	; DESCRIPTION:    Set the SendLevel (0-100) for the script.
	; PARAMETERS:
	;  new (I,REQ) - The new SendLevel.
	; RETURNS:        The original SendLevel.
	;---------
	sendLevel(new) {
		old := A_SendLevel
		SendLevel, % new
		return old
	}
	; #END#
}
