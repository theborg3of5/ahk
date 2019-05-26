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
	monitorBounds := getMonitorBounds("", titleString)
	window := new VisualWindow(titleString)
	window.resizeMove(monitorBounds["WIDTH"], monitorBounds["HEIGHT"], VisualWindow.X_CENTERED, VisualWindow.Y_CENTERED)
}

isWindowVisible(titleString := "A") {
	return bitFieldHasFlag(WinGet("Style", ""), WS_VISIBLE)
}




getMonitorBounds(monitorNum := "", titleString := "A") {
	monitorsAry := getMonitorBoundsAry()
	
	if(!monitorNum)
		monitorNum := getWindowMonitor(titleString, monitorsAry)
	
	; DEBUG.popup("monitorsAry",monitorsAry, "titleString",titleString, "monitorNum",monitorNum, "monitorsAry[monitorNum]",monitorsAry[monitorNum])
	return monitorsAry[monitorNum]
}
; Returns an array of monitors with LEFT/RIGHT/TOP/BOTTOM/WIDTH/HEIGHT values for their working area (doesn't include taskbar or other toolbars).
getMonitorBoundsAry() {
	monitorsAry := []
	
	numMonitors := SysGet("MonitorCount")
	Loop, %numMonitors%
	{
		; Dimensions of this monitor go in Mon*
		SysGet, Mon, MonitorWorkArea, %A_Index%
		
		mon           := []
		mon["LEFT"]   := MonLeft
		mon["RIGHT"]  := MonRight
		mon["TOP"]    := MonTop
		mon["BOTTOM"] := MonBottom
		mon["WIDTH"]  := MonRight  - MonLeft
		mon["HEIGHT"] := MonBottom - MonTop
		; DEBUG.popup("Monitor " A_Index, mon)
		
		monitorsAry.Push(mon)
	}
	; DEBUG.popup("Monitor List", monitorsAry)
	
	return monitorsAry
}


moveWindowToMonitor(titleString, destMonitor, monitorsAry := "") {
	; If monitorsAry isn't given, make our own.
	if(!IsObject(monitorsAry))
		monitorsAry := getMonitorBoundsAry()
	
	currMonitor := getWindowMonitor(titleString, monitorsAry)
	if(currMonitor = -1) ; Couldn't find what monitor the window is on.
		return
	
	; Window is already on the correct monitor, or we couldn't figure out what monitor this window was on.
	if( (currMonitor = destMonitor) || !currMonitor)
		return
	
	; Move the window to the correct monitor.
	; If the window is maximized, restore it.
	minMaxState := WinGet("MinMax", titleString)
	if(minMaxState = 1)
		WinRestore, %titleString%
	
	; Calculate the new position for the window.
	WinGetPos, winX, winY, , , %titleString%
	oldMon := monitorsAry[currMonitor]
	newMon := monitorsAry[destMonitor]
	newX := winX - oldMon["LEFT"] + newMon["LEFT"]
	newY := winY - oldMon["TOP"]  + newMon["TOP"]
	
	; Move it there.
	WinMove, %titleString%, , newX, newY
	
	; If the window was maximized before, re-maximize it.
	if(minMaxState = 1)
		WinMaximize, %titleString%
}

; Get the index of the monitor nearest the specified window.
getWindowMonitor(titleString := "A", monitorsAry := "") {
	if(!IsObject(monitorsAry))
		monitorsAry := getMonitorBoundsAry()
	; DEBUG.popup("Monitor list",monitorsAry, "Title string",titleString)
	
	workBoundsAry := getWindowMonitorWorkBounds(titleString)
	
	For monitorNum,monitor in monitorsAry
		if(monitor["LEFT"] = workBoundsAry["LEFT"] && monitor["TOP"] = workBoundsAry["TOP"])
			return monitorNum
	
	return -1
}

; Get the work bounds for the monitor closest to the specified window.
; Adapted from https://autohotkey.com/boards/viewtopic.php?p=78862#p78862
getWindowMonitorWorkBounds(titleString := "A") {
	winId := WinExist(titleString) ; Window handle
	
	; Get the monitor nearest to the window with the MonitorFromWindow function ( https://docs.microsoft.com/en-us/windows/desktop/api/winuser/nf-winuser-monitorfromwindow )
	monitorHandle := DllCall("MonitorFromWindow", "Ptr", winId, "UInt", MONITOR_DEFAULTTONEAREST)
	
	; Initialize MONITORINFO structure ( https://docs.microsoft.com/en-us/windows/desktop/api/winuser/ns-winuser-tagmonitorinfo ) for return value from GetMonitorInfo
	monitorInfoStructureSize := 40                        ; MONITORINFO [40] = DWORD cbSize [4] + RECT rcMonitor [16] + RECT rcWork [16] + DWORD dwFlags [4]
	VarSetCapacity(monitorInfo, monitorInfoStructureSize) ; Set the size of the variable holding the MONITORINFO structure
	NumPut(monitorInfoStructureSize, monitorInfo)         ; Set the cbSize member of the MONITORINFO structure
	
	; GetMonitorInfo function ( https://docs.microsoft.com/en-us/windows/desktop/api/winuser/nf-winuser-getmonitorinfoa )
	DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", &monitorInfo)
	
	; monitorInfo is a MONITORINFO structure (https://docs.microsoft.com/en-us/windows/desktop/api/winuser/ns-winuser-tagmonitorinfo )
	; RECT [16] = LONG left [4] + LONG top [4] + LONG right [4] + LONG bottom [4]
	memOffsetLeft   := 20                 ; Start of RECT rcWork (DWORD cbSize [4] + RECT rcMonitor [16])
	memOffsetTop    := memOffsetLeft  + 4 ; Left  + LONG left  [4]
	memOffsetRight  := memOffsetTop   + 4 ; Top   + LONG top   [4]
	memOffsetBottom := memOffsetRight + 4 ; Right + LONG right [4]
	
	workBoundsAry := []
	workBoundsAry["LEFT"]   := NumGet(monitorInfo, memOffsetLeft,   "Int")
	workBoundsAry["TOP"]    := NumGet(monitorInfo, memOffsetTop,    "Int")
	workBoundsAry["RIGHT"]  := NumGet(monitorInfo, memOffsetRight,  "Int")
	workBoundsAry["BOTTOM"] := NumGet(monitorInfo, memOffsetBottom, "Int")
	
	return workBoundsAry
}

