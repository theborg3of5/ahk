; Library of helpful functions for examining and manipulating a window.

class WindowLib {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Determine whether a window is maximized.
	; PARAMETERS:
	;  titleString (I,OPT) - Title string that identifies your chosen window.
	;                        Defaults to the active window ("A").
	; RETURNS:        true if the window is maximized, false otherwise.
	;---------
	isMaximized(titleString := "A") {
		return (WinGet("MinMax", titleString) = 1)
	}
	
	;---------
	; DESCRIPTION:    Determine whether a window is minimized.
	; PARAMETERS:
	;  titleString (I,OPT) - Title string that identifies your chosen window.
	;                        Defaults to the active window ("A").
	; RETURNS:        true if the window is minimized, false otherwise.
	;---------
	isMinimized(titleString := "A") {
		return (WinGet("MinMax", titleString) = -1)
	}
	
	;---------
	; DESCRIPTION:    Determine whether a window is visible, based on its style.
	; PARAMETERS:
	;  titleString (I,OPT) - Title string that identifies your chosen window.
	;                        Defaults to the active window ("A").
	; RETURNS:        true/false, whether the window is visible.
	;---------
	isVisible(titleString := "A") {
		return this.hasStyle(MicrosoftLib.Style_Visible, titleString)
	}
	
	;---------
	; DESCRIPTION:    Determine whether a window is set to be always on top.
	; PARAMETERS:
	;  titleString (I,OPT) - Title string that identifies your chosen window.
	;                        Defaults to the active window ("A").
	; RETURNS:        true/false, whether the window is always on top.
	;---------
	isAlwaysOnTop(titleString := "A") {
		return this.hasExStyle(MicrosoftLib.ExStyle_AlwaysOnTop, titleString)
	}
	
	;---------
	; DESCRIPTION:    Determine whether a window has the "caption" style (with a title bar and borders).
	; PARAMETERS:
	;  titleString (I,OPT) - Title string that identifies your chosen window.
	;                        Defaults to the active window ("A").
	; RETURNS:        true/false, whether the window has the caption style.
	;---------
	hasCaption(titleString := "A") { ; Window with no caption style (no titlebar or borders)
		return this.hasStyle(MicrosoftLib.Style_Caption, titleString)
	}
	
	;---------
	; DESCRIPTION:    Determine whether a window is resizable.
	; PARAMETERS:
	;  titleString (I,OPT) - Title string that identifies your chosen window.
	;                        Defaults to the active window ("A").
	; RETURNS:        true/false, whether the window is resizable.
	;---------
	isSizable(titleString := "A") {
		return this.hasStyle(MicrosoftLib.Style_Sizable, titleString)
	}
	
	;---------
	; DESCRIPTION:    Check whether a window has a particular style.
	; PARAMETERS:
	;  style       (I,REQ) - The style to check for.
	;  titleString (I,OPT) - Title string that identifies your chosen window.
	;                        Defaults to the active window ("A").
	; RETURNS:        true/false
	;---------
	hasStyle(style, titleString := "A") {
		return DataLib.bitFieldHasFlag(WinGet("Style", titleString), style)
	}
	;---------
	; DESCRIPTION:    Check whether a window has a particular extended style.
	; PARAMETERS:
	;  extendedStyle (I,REQ) - The extended style to check for.
	;  titleString   (I,OPT) - Title string that identifies your chosen window.
	;                          Defaults to the active window ("A").
	; RETURNS:        true/false
	;---------
	hasExStyle(extendedStyle, titleString := "A") {
		return DataLib.bitFieldHasFlag(WinGet("ExStyle", titleString), extendedStyle)
	}
	
	;---------
	; DESCRIPTION:    Build a title string that can be used to identify a window based on the given
	;                 parts, for use with WinActivate and the like.
	; PARAMETERS:
	;  exeName  (I,OPT) - Executable name, will be paired with ahk_exe
	;  winClass (I,OPT) - Window class, will be paired with ahk_class
	;  winTitle (I,OPT) - Text that's part of the window title
	; RETURNS:        Title string including all of the given criteria
	;---------
	buildTitleString(exeName := "", winClass := "", winTitle := "") {
		outStr := ""
		
		if(winTitle) 
			outStr := outStr.appendPiece(winTitle, " ") ; Title has to go first since it doesn't have an "ahk_" identifier to go with it.
		if(exeName)
			outStr := outStr.appendPiece("ahk_exe " exeName, " ")
		if(winClass)
			outStr := outStr.appendPiece("ahk_class " winClass, " ")
		
		return outStr
	}
	
	;---------
	; DESCRIPTION:    Get an ID-based title string to identify the window under the mouse with.
	; RETURNS:        title string (that uses ahk_id) identifying the window under the mouse.
	;---------
	getIdTitleStringUnderMouse() {
		MouseGetPos( , , winId)
		return "ahk_id " winId
	}
	
	;---------
	; DESCRIPTION:    For the window identified by the given title string, generate a title string
	;                 that's guaranteed to match only that window (based on its window ID).
	; PARAMETERS:
	;  titleString (I,OPT) - Title string that identifies your chosen window.
	;                        Defaults to the active window ("A").
	; RETURNS:        A title string that uniquely (using ahk_id) identifies only your chosen window.
	;---------
	getIdTitleString(titleString := "A") {
		return "ahk_id " WinGet("ID", titleString)
	}
	
	;---------
	; DESCRIPTION:    Visually center the given window on its current monitor.
	; PARAMETERS:
	;  titleString (I,OPT) - Title string that identifies your chosen window.
	;                        Defaults to the active window ("A").
	;---------
	center(titleString := "A") {
		new VisualWindow(titleString).move(VisualWindow.X_Centered, VisualWindow.Y_Centered)
	}
	; #END#
}
