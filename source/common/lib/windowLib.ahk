; Library of helpful functions for examining and manipulating a window.

class WindowLib {
	;region ------------------------------ PUBLIC ------------------------------
	;region Conditions
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
	; DESCRIPTION:    Determine whether a window is disabled.
	; PARAMETERS:
	;  titleString (I,OPT) - Title string that identifies your chosen window.
	;                        Defaults to the active window ("A").
	; RETURNS:        true/false, whether the window is disabled.
	;---------
	isDisabled(titleString := "A") {
		return this.hasStyle(MicrosoftLib.Style_Disabled, titleString)
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
	; DESCRIPTION:    Check whether the given window is one that we shouldn't try to move or resize.
	; PARAMETERS:
	;  titleString (I,REQ) - Title string identifying the window in question.
	; RETURNS:        true if the window should be excluded, false otherwise.
	;---------
	isNoMoveSizeWindow(titleString) {
		if(Config.windowMatchesInfo(titleString, "Windows Taskbar"))
			return true
		if(Config.windowMatchesInfo(titleString, "Windows Taskbar Secondary"))
			return true
		if(Config.windowMatchesInfo(titleString, "Windows Alt Tab"))
			return true
		if(Config.windowMatchesInfo(titleString, "Zoom Default Meeting"))
			return true
		
		return false
	}
	;endregion Conditions
	
	;region Actions/setters
	;---------
	; DESCRIPTION:    Make a window visible.
	; PARAMETERS:
	;  titleString (I,OPT) - Title string that identifies your chosen window.
	;                        Defaults to the active window ("A").
	;---------
	makeVisible(titleString := "A") {
		this.addStyle(MicrosoftLib.Style_Visible, titleString)
	}
	
	;---------
	; DESCRIPTION:    Add a style to the given window.
	; PARAMETERS:
	;  style       (I,REQ) - The style to add.
	;  titleString (I,OPT) - Title string that identifies your chosen window.
	;                        Defaults to the active window ("A").
	;---------
	addStyle(style, titleString := "A") {
		WinSet, Style, % "+" style, % titleString
	}
	
	;---------
	; DESCRIPTION:    Remove a style from the given window.
	; PARAMETERS:
	;  style       (I,REQ) - The style to remove.
	;  titleString (I,OPT) - Title string that identifies your chosen window.
	;                        Defaults to the active window ("A").
	;---------
	removeStyle(style, titleString := "A") {
		WinSet, Style, % "-" style, % titleString
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
	;endregion Actions/setters
	
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
			outStr := outStr.appendPiece(" ", winTitle) ; Title has to go first since it doesn't have an "ahk_" identifier to go with it.
		if(exeName)
			outStr := outStr.appendPiece(" ", "ahk_exe " exeName)
		if(winClass)
			outStr := outStr.appendPiece(" ", "ahk_class " winClass)
		
		return outStr
	}
	
	;---------
	; DESCRIPTION:    Wait until the specified control is active.
	; PARAMETERS:
	;  waitControlId (I,REQ) - The ID (classNN) of the control to wait on.
	;  titleString   (I,OPT) - Title string that identifies your chosen window.
	;                          Defaults to the active window ("A").
	;  timeout       (I,OPT) - Milliseconds to wait before timing out. Defaults to 1000ms.
	; RETURNS:        true if the control became active, false if we timed out.
	;---------
	waitControlActive(waitControlId, titleString := "A", timeout := 1000) {
		startTime := A_TickCount
		
		Loop {
			Sleep, 100
			timeWaited := A_TickCount - startTime
			controlId := ControlGetFocus(titleString)
		} Until ( (controlId = waitControlId) || (timeWaited > timeout) )
		
		return (controlId = waitControlId)
	}
	
	;---------
	; DESCRIPTION:    Wait on any of a number of windows to become active.
	; PARAMETERS:
	;  titleStrings (I,REQ) - An array of titleStrings that describe the various windows to wait on.
	;  timeout      (I,OPT) - The timeout to give up after.
	; RETURNS:        true if one of the windows became active, false if we timed out.
	;---------
	waitAnyOfWindowsActive(titleStrings, timeout := "") {
		this.waitGroupIndex += 1
		groupName := "WaitGroup" this.waitGroupIndex
		
		For _,titleString in titleStrings
			GroupAdd, % groupName, % titleString
		
		WinWaitActive, % "ahk_group " groupName, , timeout
		
		return (ErrorLevel = 0) ; ErrorLevel = 1 if we timed out
	}

	;---------
	; DESCRIPTION:    Count the number of windows matching the given title string.
	; PARAMETERS:
	;  titleString (I,REQ) - The title string to match against.
	;  matchMode   (I,OPT) - An override TitleMatchMode to use for matching.
	; RETURNS:        The number of windows matching the given title string.
	;---------
	countMatchingWindows(titleString, matchMode := "") {
		if (matchMode)
			settings := new TempSettings().titleMatchMode(matchMode)
		
		count := WinGet("Count", titleString)
		
		if (settings)
			settings.restore()
		
		return count
	}
	
	;---------
	; DESCRIPTION:    Grab the tooltip(s) shown onscreen. Based on
	;                 http://www.autohotkey.com/board/topic/53672-get-the-text-content-of-a-tool-tip-window/?p=336440
	; RETURNS:        Tooltip text
	;---------
	getTooltipText() {
		outText := ""
		
		; Allow partial matching on ahk_class. (tooltips_class32, WindowsForms10.tooltips_class32.app.0.2bf8098_r13_ad1 so far)
		settings := new TempSettings().titleMatchMode(TitleMatchMode.RegEx)
		WinGet, winIDs, LIST, ahk_class tooltips_class32
		settings.restore()
		
		Loop, %winIDs% {
			currID := winIDs%A_Index%
			tooltipText := ControlGetText( , "ahk_id " currID)
			if(tooltipText != "")
				outText := outText.appendLine(tooltipText)
		}
		
		return outText
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	waitGroupIndex := 0 ; Counter to give us a unique group name for waitAnyOfWindowsActive each time (since we can't delete a group or remove window "rules" from them)
	;endregion ------------------------------ PRIVATE ------------------------------
}
