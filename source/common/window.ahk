
global WINPOS_X_Left   := "LEFT"   ; Against left edge of screen
global WINPOS_X_Right  := "RIGHT"  ; Against right edge of screen
global WINPOS_X_Center := "CENTER" ; Horizontally centered
global WINPOS_Y_Top    := "TOP"    ; Against top edge of screen
global WINPOS_Y_Bottom := "BOTTOM" ; Against bottom edge of screen
global WINPOS_Y_Center := "CENTER" ; Vertically centered


; Puts together a string that can be used with the likes of WinActivate, etc.
buildWindowTitleString(exeName := "", winClass := "", winTitle := "") {
	outStr := ""
	
	if(winTitle) 
		outStr := appendPieceToString(outStr, winTitle, " ") ; Title has to go first since it doesn't have an "ahk_" identifier to go with it.
	
	if(exeName)
		outStr := appendPieceToString(outStr, "ahk_exe " exeName, " ")
	
	if(winClass)
		outStr := appendPieceToString(outStr, "ahk_class " winClass, " ")
	
	return outStr
}

; Returns true if the current window's title contains any of a given array of strings.
titleContainsAnyOf(haystack) {
	title := WinGetActiveTitle()
	return stringMatchesAnyOf(title, haystack)
}

; See if a window exists or is active with a given TitleMatchMode.
isWindowInState(states := "", titles := "", texts := "", matchMode := 1, matchSpeed := "Fast", findHidden := "Off") {
	; Make sure these are arrays so we can loop on them below.
	states := forceArray(states)
	titles := forceArray(titles)
	texts  := forceArray(texts)
	; DEBUG.popup("Window states to check", states, "Window titles to match", titles, "Window texts to match", texts, "Title match mode", matchMode)
	
	; Plug in the new match settings.
	origMatchSettings := setMatchSettings(matchMode, matchSpeed, findHidden)
	
	windowMatch := false
	For i,state in states {
		For j,title in titles {
			For k,text in texts {
				if(state = "active")
					windowMatch := WinActive(title, text)
				else if(stringContains(state, "exist")) ; Allow "exist" and "exists" both
					windowMatch := WinExist(title, text)
				
				if(windowMatch)
					break 3 ; Break out of outermost loop
			}
		}
	}
	
	; Restore defaults when done.
	restoreMatchSettings(origMatchSettings)
	
	return windowMatch
}
waitUntilWindowState(state, title := "", text := "", matchMode := 1, matchSpeed := "Fast") {
	; Plug in the new match settings.
	origMatchSettings := setMatchSettings(matchMode, matchSpeed)
	
	; DEBUG.popup("Window state to wait on",state, "Window title to match",title, "Window text to match",text, "Title match mode",matchMode, "Title match speed",matchSpeed)
	
	if(state = "active")
		WinWaitActive, %title%, %text%
	else if(stringContains(state, "exist"))
		WinWait, %title%, %text%
	
	; Restore defaults when done.
	restoreMatchSettings(origMatchSettings)
}

; Get/set/restore various matching behavior states all at once.
setMatchSettings(mode := "", speed := "", detectHidden := "") {
	; Save off the previous settings - nice if we want to restore later.
	prevSettings := getMatchSettings()
	
	if(mode)
		SetTitleMatchMode, % mode
	if(speed)
		SetTitleMatchMode, % speed
	if(detectHidden)
		DetectHiddenWindows, % detectHidden
	
	return prevSettings ; Return the previous settings (to be used with restoreMatchSettings() if desired).
}
getMatchSettings() {
	settings := Object()
	settings["MODE"]          := A_TitleMatchMode
	settings["SPEED"]         := A_TitleMatchModeSpeed
	settings["DETECT_HIDDEN"] := A_DetectHiddenWindows
	
	return settings
}
restoreMatchSettings(settings) {
	if(!settings)
		return
	
	SetTitleMatchMode,   % settings["MODE"]
	SetTitleMatchMode,   % settings["SPEED"]
	DetectHiddenWindows, % settings["DETECT_HIDDEN"]
}

; Centers a window on the screen.
centerWindow(titleString := "A") {
	moveWindow(WINPOS_X_Center, WINPOS_Y_Center, titleString)
}

moveWindow(x, y, titleString := "A") {
	positions := convertRelativeWinPositions(x, y, titleString)
	WinMove, %titleString%, , positions["X"], positions["Y"]
}

	; Given coordinates (if numeric) are assumed to be relative to the relevant monitor (and sans offsets - so for visual size of window)
convertRelativeWinPositions(relX, relY, titleString := "A") {
	windowOffsets := getWindowOffsets(titleString)
	windowSizes   := getVisualWindowSize(titleString, windowOffsets)
	monitorBounds := getMonitorBounds("", titleString)
	; DEBUG.popup("relX",relX, "relY",relY, "titleString",titleString, "windowOffsets",windowOffsets, "windowSizes",windowSizes, "monitorBounds",monitorBounds)
	
	if(!isNum(relX))
		relX := convertSpecialWinPositionToRelX(relX, windowSizes, monitorBounds)
	if(!isNum(relY))
		relY := convertSpecialWinPositionToRelY(relY, windowSizes, monitorBounds)
	
	; True coordinates (taking offsets into account)
	x := monitorBounds["LEFT"] + relX - windowOffsets["LEFT"]
	y := monitorBounds["TOP"]  + relY - windowOffsets["TOP"]
	
	; DEBUG.popup("x",x, "y",y)
	return {"X":x, "Y":y}
}

getVisualWindowSize(titleString := "A", windowOffsets := "") {
	; Simple window size
	WinGetPos, , , winWidth, winHeight, %titleString%
	; DEBUG.popup("titleString",titleString,"winWidth",winWidth, "winHeight",winHeight)
	
	; Some windows are wider/taller than they look - take that into account.
	if(!windowOffsets)
		windowOffsets := getWindowOffsets(titleString)
	winWidth  -= (windowOffsets["LEFT"]   + windowOffsets["RIGHT"])
	winHeight -= (windowOffsets["BOTTOM"] + windowOffsets["TOP"]  )
	
	return {"WIDTH":winWidth, "HEIGHT":winHeight}
}

convertSpecialWinPositionToRelX(relX, windowSizes, monitorBounds) {
	if(relX = WINPOS_X_Left)
		return 0
	
	monitorWindowDiff := monitorBounds["WIDTH"] - windowSizes["WIDTH"]
	if(relX = WINPOS_X_Right)
		return monitorWindowDiff
	if(relX = WINPOS_X_Center)
		return monitorWindowDiff / 2
	
	return ""
}

convertSpecialWinPositionToRelY(relY, windowSizes, monitorBounds) {
	if(relY = WINPOS_Y_Top)
		return 0
	
	monitorWindowDiff := monitorBounds["HEIGHT"] - windowSizes["HEIGHT"]
	if(relY = WINPOS_Y_Bottom)
		return monitorWindowDiff
	if(relY = WINPOS_Y_Center)
		return monitorWindowDiff / 2
	
	return ""
}

fakeMaximizeWindow(titleString := "A") {
	monitorBounds := getMonitorBounds("", titleString)
	width     := monitorBounds["WIDTH"]
	height    := monitorBounds["HEIGHT"]
	
	; DEBUG.popup("Bounds",monitorBounds, "New width",width, "New height",height)
	resizeWindow(width, height, titleString)
	centerWindow()
}

; Originally from http://www.howtogeek.com/howto/28663/create-a-hotkey-to-resize-windows-to-a-specific-size-with-autohotkey/ ,
; with my own additions for window edge offsets and centering.
resizeWindow(width := "", height := "", titleString := "A") {
	; Get the current window size/position, to default in width/height if not given
	windowSizes := getVisualWindowSize(titleString, windowOffsets)
	if(!width)
		width  := windowSizes["WIDTH"]
	if(!height)
		height := windowSizes["HEIGHT"]
	
	; Take window edge offsets into account
	windowOffsets := getWindowOffsets(titleString)
	width  += windowOffsets["LEFT"] + windowOffsets["RIGHT"]
	height += windowOffsets["TOP"]  + windowOffsets["BOTTOM"]
	
	; Resize and center the window
	WinMove, A, , , , %width%, %height%
	; DEBUG.toast("width",width, "height",height, "origWidth",origWidth, "origHeight",origHeight, "windowOffsets",windowOffsets, "titleString",titleString)
}


getWindowOffsets(titleString := "A") {
	windowOffsets := []
	
	if(MainConfig.findWindowInfo(titleString).edgeType = WINDOW_EDGE_STYLE_NoPadding) { ; Specific window has no padding
		windowOffsets["LEFT"]   := 0
		windowOffsets["RIGHT"]  := 0
		windowOffsets["TOP"]    := 0
		windowOffsets["BOTTOM"] := 0
	} else { ; Calculate the default padding.
		maximizedWidth    := SysGet(SM_CXMAXIMIZED) ; For non-3D windows (which should be most), the width of the border on the left and right.
		maximizedHeight   := SysGet(SM_CYMAXIMIZED) ; For non-3D windows (which should be most), the width of the border on the top and bottom.
		borderWidthX      := SysGet(SM_CXBORDER)    ; Width of a maximized window on the primary monitor. Includes any weird offsets.
		borderWidthY      := SysGet(SM_CYBORDER)    ; Height of a maximized window on the primary monitor. Includes any weird offsets.
		
		primaryMonitorNum := SysGet("MonitorPrimary") ; We're assuming the taskbar is in the same place on all monitors, which is fine for my purposes.
		bounds := getMonitorBounds(primaryMonitorNum)
		
		; (Maximized size - monitor working area - both borders) / 2
		offsetWidth  := (maximizedWidth  - bounds["WIDTH"]  - (borderWidthX * 2)) / 2
		offsetHeight := (maximizedHeight - bounds["HEIGHT"] - (borderWidthY * 2)) / 2
		
		windowOffsets["LEFT"]   := offsetWidth
		windowOffsets["RIGHT"]  := offsetWidth
		windowOffsets["TOP"]    := offsetHeight
		windowOffsets["BOTTOM"] := offsetHeight
	}
	
	; Assuming the taskbar is on top, otherwise could use something like https://autohotkey.com/board/topic/91513-function-get-the-taskbar-location-win7/ to figure out where it is.
	windowOffsets["TOP"] := 0 ; Taskbar side never has an offset.
	
	return windowOffsets
}

getMonitorBounds(monitorNum := "", titleString := "A") {
	monitorsAry := getMonitorBoundsAry()
	
	if(!monitorNum)
		monitorNum := getWindowMonitor(titleString, monitorsAry)
	
	; DEBUG.popup("monitorsAry",monitorsAry, "titleString",titleString, "monitorNum",monitorNum, "monitorsAry[monitorNum]",monitorsAry[monitorNum])
	return monitorsAry[monitorNum]
}
; Returns an array of monitors with LEFT/RIGHT/TOP/BOTTOM values for their working area (doesn't include taskbar or other toolbars).
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
	
	; DEBUG.popup("WindowMonitorFixer", "Moving window", "ID", titleString, "Current monitor", currMonitor, "Destination monitor", destMonitor)
	
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
	
	; DEBUG.popup("Moving window", "", "Curr X", winX, "Curr Y", winY, "New X", newX, "New Y", newY, "Old mon (" currMonitor ")", oldMon, "New mon (" destMonitor ")", newMon)
	
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
	
	windowMonitorWorkBounds := getWindowMonitorWorkBounds(titleString)
	
	For monitorNum,monitor in monitorsAry {
		monLeft   := monitor["LEFT"]
		monTop    := monitor["TOP"]
		
		if(monLeft = windowMonitorWorkBounds["LEFT"] && monTop = windowMonitorWorkBounds["TOP"])
			return monitorNum
	}
	
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

activateWindowUnderMouse() {
	MouseGetPos( , , winId)
	WinActivate, % "ahk_id " winId
}
