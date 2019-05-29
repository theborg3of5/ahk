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
		outStr := appendPieceToString(outStr, " ", winTitle) ; Title has to go first since it doesn't have an "ahk_" identifier to go with it.
	if(exeName)
		outStr := appendPieceToString(outStr, " ", "ahk_exe " exeName)
	if(winClass)
		outStr := appendPieceToString(outStr, " ", "ahk_class " winClass)
	
	return outStr
}

;---------
; DESCRIPTION:    For the window identified by the given title string, generate a title string
;                 that's guaranteed to match only that window (based on its window ID).
; PARAMETERS:
;  titleString (I,REQ) - Title string that identifies your chosen window.
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
;  titleString (I,REQ) - Title string that identifies your chosen window.
;                        Defaults to the active window ("A").
;---------
centerWindow(titleString := "A") {
	window := new VisualWindow(titleString)
	window.move(VisualWindow.X_CENTERED, VisualWindow.Y_CENTERED)
}

;---------
; DESCRIPTION:    Resize a window to take up the full size of the monitor, without actually
;                 maximizing that window.
; PARAMETERS:
;  titleString (I,REQ) - Title string that identifies your chosen window.
;                        Defaults to the active window ("A").
;---------
fakeMaximizeWindow(titleString := "A") {
	monitorBounds := getWindowMonitorWorkArea(titleString)
	window := new VisualWindow(titleString)
	window.resizeMove(monitorBounds["WIDTH"], monitorBounds["HEIGHT"], VisualWindow.X_CENTERED, VisualWindow.Y_CENTERED)
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
; DESCRIPTION:    Get the dimensions of the work area of the monitor "closest" (according to
;                 Windows) to the given window.
; PARAMETERS:
;  titleString (I,REQ) - Title string that identifies your chosen window.
;                        Defaults to the active window ("A").
; RETURNS:        Array of position/size information for the working area of the monitor that the
;                 window is "closest" to. Format:
;                    boundsAry["LEFT"]   = X coordinate of monitor's (working area's) left bound
;                             ["RIGHT"]  = X coordinate of monitor's (working area's) right bound
;                             ["TOP"]    = Y coordinate of monitor's (working area's) top bound
;                             ["BOTTOM"] = Y coordinate of monitor's (working area's) bottom bound
;                             ["WIDTH"]  = width of the monitor's work area
;                             ["HEIGHT"] = height of the monitor's work area
; NOTES:          This working area excludes things like the taskbar - it's the full space that a
;                 window can occupy.
;---------
getWindowMonitorWorkArea(titleString := "A") {
	winId := WinExist(titleString) ; Window handle
	
	; Get the monitor nearest to the window with the MonitorFromWindow function (https://docs.microsoft.com/en-us/windows/desktop/api/winuser/nf-winuser-monitorfromwindow )
	monitorHandle := DllCall("MonitorFromWindow", "Ptr", winId, "UInt", MONITOR_DEFAULTTONEAREST)
	
	; Initialize MONITORINFO structure (https://docs.microsoft.com/en-us/windows/desktop/api/winuser/ns-winuser-tagmonitorinfo ) for return value from GetMonitorInfo
	monitorInfoStructSize := 40                        ; MONITORINFO [40] = DWORD cbSize [4] + RECT rcMonitor [16] + RECT rcWork [16] + DWORD dwFlags [4]
	VarSetCapacity(monitorInfo, monitorInfoStructSize) ; Set the size of the variable holding the MONITORINFO structure
	NumPut(monitorInfoStructSize, monitorInfo)         ; Set the cbSize member of the MONITORINFO structure
	
	; GetMonitorInfo function (https://docs.microsoft.com/en-us/windows/desktop/api/winuser/nf-winuser-getmonitorinfoa )
	DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", &monitorInfo)
	
	; monitorInfo is a MONITORINFO structure (https://docs.microsoft.com/en-us/windows/desktop/api/winuser/ns-winuser-tagmonitorinfo )
	; RECT [16] = LONG left [4] + LONG top [4] + LONG right [4] + LONG bottom [4]
	memOffsetLeft   := 20                 ; Start of RECT rcWork (DWORD cbSize [4] + RECT rcMonitor [16])
	memOffsetTop    := memOffsetLeft  + 4 ; Left  + LONG left  [4]
	memOffsetRight  := memOffsetTop   + 4 ; Top   + LONG top   [4]
	memOffsetBottom := memOffsetRight + 4 ; Right + LONG right [4]
	
	boundsAry := []
	boundsAry["LEFT"]   := NumGet(monitorInfo, memOffsetLeft,   "Int")
	boundsAry["TOP"]    := NumGet(monitorInfo, memOffsetTop,    "Int")
	boundsAry["RIGHT"]  := NumGet(monitorInfo, memOffsetRight,  "Int")
	boundsAry["BOTTOM"] := NumGet(monitorInfo, memOffsetBottom, "Int")
	boundsAry["WIDTH"]  := boundsAry["RIGHT"]  - boundsAry["LEFT"]
	boundsAry["HEIGHT"] := boundsAry["BOTTOM"] - boundsAry["TOP"]
	
	return boundsAry
}
