; Functions for identifying and interacting with windows.

; Puts together a string that can be used with the likes of WinActivate, etc.

;---------
; DESCRIPTION:    Build a title string that can be used to identify a window based on the given
;                 parts, for use with WinActivate and the like.
; PARAMETERS:
;  exeName  (I,OPT) - Executable name, will be paired with ahk_exe
;  winClass (I,OPT) - Window class, will be paired with ahk_class
;  winTitle (I,OPT) - Text that's part of the window title
; RETURNS:        Title string including all of the given criteria
;---------
buildWindowTitleString(exeName := "", winClass := "", winTitle := "") {
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
; DESCRIPTION:    For the window identified by the given title string, generate a title string
;                 that's guaranteed to match only that window (based on its window ID).
; PARAMETERS:
;  titleString (I,OPT) - Title string that identifies your chosen window.
;                        Defaults to the active window ("A").
; RETURNS:        A title string that uniquely (using ahk_id) identifies only your chosen window.
;---------
getIdTitleStringForWindow(titleString := "A") {
	WinGet, winId, ID, % titleString
	return "ahk_id " winId
}

;---------
; DESCRIPTION:    Visually center the given window on its current monitor.
; PARAMETERS:
;  titleString (I,OPT) - Title string that identifies your chosen window.
;                        Defaults to the active window ("A").
;---------
centerWindow(titleString := "A") {
	new VisualWindow(titleString).move(VisualWindow.X_Centered, VisualWindow.Y_Centered)
}

;---------
; DESCRIPTION:    Resize a window to take up the full size of the monitor, without actually
;                 maximizing that window.
; PARAMETERS:
;  titleString (I,OPT) - Title string that identifies your chosen window.
;                        Defaults to the active window ("A").
;---------
fakeMaximizeWindow(titleString := "A") {
	monitorBounds := getWindowMonitorWorkArea(titleString)
	new VisualWindow(titleString).resizeMove(monitorBounds["WIDTH"], monitorBounds["HEIGHT"], VisualWindow.X_Centered, VisualWindow.Y_Centered)
}

;---------
; DESCRIPTION:    Determine whether a window is visible, based on its style.
; PARAMETERS:
;  titleString (I,REQ) - Title string that identifies your chosen window.
;                        Defaults to the active window ("A").
; RETURNS:        True if the window is visible, False otherwise.
;---------
isWindowVisible(titleString := "A") {
	return bitFieldHasFlag(WinGet("Style", ""), WS_VISIBLE)
}

;---------
; DESCRIPTION:    Determine whether a window is maximized.
; PARAMETERS:
;  titleString (I,OPT) - Title string that identifies your chosen window.
;                        Defaults to the active window ("A").
; RETURNS:        true if the window is maximized, false otherwise.
;---------
isWindowMaximized(titleString := "A") {
	return (WinGet("MinMax", titleString) = 1)
}

;---------
; DESCRIPTION:    Determine whether a window is minimized.
; PARAMETERS:
;  titleString (I,OPT) - Title string that identifies your chosen window.
;                        Defaults to the active window ("A").
; RETURNS:        true if the window is minimized, false otherwise.
;---------
isWindowMinimized(titleString := "A") {
	return (WinGet("MinMax", titleString) = -1)
}

;---------
; DESCRIPTION:    Get the dimensions of the work area of the monitor "closest" (according to
;                 Windows) to the given window.
; PARAMETERS:
;  titleString (I,OPT) - Title string that identifies your chosen window.
;                        Defaults to the active window ("A").
; RETURNS:        Associative array of position/size information for the working area of the
;                 monitor that the window is "closest" to. Format:
;                    bounds["LEFT"]   = X coordinate of monitor's (working area's) left bound
;                          ["RIGHT"]  = X coordinate of monitor's (working area's) right bound
;                          ["TOP"]    = Y coordinate of monitor's (working area's) top bound
;                          ["BOTTOM"] = Y coordinate of monitor's (working area's) bottom bound
;                          ["WIDTH"]  = width of the monitor's work area
;                          ["HEIGHT"] = height of the monitor's work area
; NOTES:          This working area excludes things like the taskbar - it's the full space that a
;                 window can occupy.
;---------
getWindowMonitorWorkArea(titleString := "A") {
	winId := WinExist(titleString) ; Window handle
	
	; Get the monitor nearest to the window with the MonitorFromWindow function (https://docs.microsoft.com/en-us/windows/desktop/api/winuser/nf-winuser-monitorfromwindow )
	monitorHandle := DllCall("MonitorFromWindow", "Ptr", winId, "UInt", MONITOR_DEFAULTTONEAREST)
	
	; Initialize MONITORINFO structure (https://docs.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-monitorinfo ) for return value from GetMonitorInfo
	monitorInfoStructSize := 40                        ; MONITORINFO [40] = DWORD cbSize [4] + RECT rcMonitor [16] + RECT rcWork [16] + DWORD dwFlags [4]
	VarSetCapacity(monitorInfo, monitorInfoStructSize) ; Set the size of the variable holding the MONITORINFO structure
	NumPut(monitorInfoStructSize, monitorInfo)         ; Set the cbSize member of the MONITORINFO structure
	
	; GetMonitorInfo function (https://docs.microsoft.com/en-us/windows/desktop/api/winuser/nf-winuser-getmonitorinfoa )
	DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", &monitorInfo)
	
	; MONITORINFO structure: RECT [16] = LONG left [4] + LONG top [4] + LONG right [4] + LONG bottom [4]
	memOffsetLeft   := 20                 ; Start of RECT rcWork (DWORD cbSize [4] + RECT rcMonitor [16])
	memOffsetTop    := memOffsetLeft  + 4 ; Left  + LONG left  [4]
	memOffsetRight  := memOffsetTop   + 4 ; Top   + LONG top   [4]
	memOffsetBottom := memOffsetRight + 4 ; Right + LONG right [4]
	
	bounds := {}
	bounds["LEFT"]   := NumGet(monitorInfo, memOffsetLeft,   "Int")
	bounds["TOP"]    := NumGet(monitorInfo, memOffsetTop,    "Int")
	bounds["RIGHT"]  := NumGet(monitorInfo, memOffsetRight,  "Int")
	bounds["BOTTOM"] := NumGet(monitorInfo, memOffsetBottom, "Int")
	bounds["WIDTH"]  := bounds["RIGHT"]  - bounds["LEFT"]
	bounds["HEIGHT"] := bounds["BOTTOM"] - bounds["TOP"]
	
	return bounds
}

;---------
; DESCRIPTION:    Find the monitor that the mouse is on and return its bounds.
; RETURNS:        The bounds of the monitor that the mouse is on.
; NOTES:          If the mouse is on the border between monitors, we will return the bottom-right most monitor.
;---------
getMouseMonitorBounds() {
	origMouseCoordMode := setCoordMode("Mouse", "Screen")
	MouseGetPos(mouseX, mouseY)
	setCoordMode("Mouse", origMouseCoordMode)
	
	partialMatches := []
	
	; Initial search - mouse must be within a monitor (not directly on an edge)
	Loop, % SysGet("MonitorCount") {
		bounds := SysGet("Monitor", A_Index)
		; DEBUG.popup("Testing",, "mouseX",mouseX, "mouseY",mouseY, "bounds",bounds)
		
		if(mouseX < bounds["LEFT"])
			Continue
		if(mouseX > bounds["RIGHT"])
			Continue
		if(mouseY < bounds["TOP"])
			Continue
		if(mouseY > bounds["BOTTOM"])
			Continue
		
		; Along a monitor edge - could be shared with another monitor, so don't quit yet.
		if(mouseX = bounds["LEFT"] || mouseX = bounds["RIGHT"] || mouseY = bounds["TOP"] || mouseY = bounds["BOTTOM"]) {
			; DEBUG.popup("Partial match",, "mouseX",mouseX, "mouseY",mouseY, "bounds",bounds)
			partialMatches.push(bounds)
			Continue
		}
		
		foundBounds := bounds
		Break
	}
	
	; If we found an exact match, we're finished.
	if(foundBounds)
		return foundBounds
	
	; DEBUG.popup("No exact match",, "mouseX",mouseX, "mouseY",mouseY, "partialMatches",partialMatches)
	
	; If we only matched a single monitor partially, we're just along one of the outer edges of that monitor.
	if(partialMatches.count() = 1)
		return partialMatches[1]
	
	; If there were multiple, pick the lower-right-most monitor.
	foundBounds := ""
	For _,bounds in partialMatches {
		if(isSecondMonitorMoreLowerRight(foundBounds, bounds))
			foundBounds := bounds
	}
	
	return foundBounds
}
;---------
; DESCRIPTION:    Determine which of the two bounds objects is the further lower and right.
; PARAMETERS:
;  firstBounds  (I,REQ) - The first bounds object. Important subscripts are "RIGHT" and "BOTTOM".
;  secondBounds (I,REQ) - The second bounds object. Important subscripts are "RIGHT" and "BOTTOM".
; RETURNS:        true if the second bounds object is further right or bottom, false otherwise.
;---------
isSecondMonitorMoreLowerRight(firstBounds, secondBounds) {
	if(firstBounds = "")
		return true
	
	if(secondBounds["RIGHT"] > firstBounds["RIGHT"])
		return true
	
	if(secondBounds["BOTTOM"] > firstBounds["BOTTOM"])
		return true
	
	return false
}
