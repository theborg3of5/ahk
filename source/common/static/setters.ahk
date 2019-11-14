; A group of wrappers for built-in setter functions that return the original value.

class Setters {
	; #PUBLIC#
	
	; new should be a value from TitleMatchMode enum.
	titleMatchMode(new) { ; Only returns the actual mode - if you want the original match mode speed value, use Setters.titleMatchSpeed() instead.
		old := A_TitleMatchMode
		SetTitleMatchMode, % new
		return old
	}
	
	titleMatchSpeed(new) {
		old := A_TitleMatchModeSpeed
		SetTitleMatchMode, % new
		return old
	}
	detectHiddenWindows(new) {
		old := A_DetectHiddenWindows
		DetectHiddenWindows, % new
		return old
	}
	workingDirectory(new) {
		old := A_WorkingDir
		SetWorkingDir, % new
		return old
	}
	
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
	sendLevel(new) {
		old := A_SendLevel
		SendLevel, % new
		return old
	}
	; #END#
}
