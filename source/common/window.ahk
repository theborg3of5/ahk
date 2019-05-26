; Functions for identifying and interacting with windows.

; Puts together a string that can be used with the likes of WinActivate, etc.
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

getIdTitleStringForWindow(titleString := "A") {
	WinGet, winId, ID, % titleString
	return "ahk_id " winId
}

; Centers a window on the screen.
centerWindow(titleString := "A") {
	window := new VisualWindow(titleString)
	window.move(VisualWindow.X_CENTERED, VisualWindow.Y_CENTERED)
}

fakeMaximizeWindow(titleString := "A") {
	monitorBounds := getWindowMonitorBounds(titleString)
	window := new VisualWindow(titleString)
	window.resizeMove(monitorBounds["WIDTH"], monitorBounds["HEIGHT"], VisualWindow.X_CENTERED, VisualWindow.Y_CENTERED)
}

isWindowVisible(titleString := "A") {
	return bitFieldHasFlag(WinGet("Style", ""), WS_VISIBLE)
}


getWindowMonitorBounds(titleString := "A") {
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
