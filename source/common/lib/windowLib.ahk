; Library of helpful functions for examining and manipulating a window.

class WindowLib {
	; #PUBLIC#
	
	; @GROUP@ Monitor locations (only 3 monitors in a horizontal line supported)
	static MonitorLocation_Left   := "LEFT"   ; Left-most monitor
	static MonitorLocation_Middle := "MIDDLE" ; Center monitor
	static MonitorLocation_Right  := "RIGHT"  ; Right-most monitor
	; @GROUP-END@
	
	;---------
	; DESCRIPTION:    
	; PARAMETERS:
	;  location (I,REQ) - The location of the monitor to get the work area bounds for, from WindowLib.MonitorLocation_*.
	; RETURNS:        Bounds array for the requested monitor (see .getMonitorWorkBounds)
	; SIDE EFFECTS:   
	; NOTES:          
	;---------
	monitorWorkAreaForLocation[location] {
		get {
			if(location = "")
				return ""
			
			areas := this.getMonitorWorkAreasByLocation()
			return areas[location]
		}
	}
	
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
	
	; [[Monitor/screen size]] --=
	;---------
	; DESCRIPTION:    Get the dimensions of the work area of the monitor "closest" (according to
	;                 Windows) to the given window.
	; PARAMETERS:
	;  titleString (I,REQ) - Title string that identifies your chosen window.
	; RETURNS:        Associative array of position/size information for the working area of the
	;                 monitor that the window is "closest" to. Format:
	;                    workArea["LEFT"]   = X coordinate of monitor's (working area's) left bound
	;                          ["RIGHT"]  = X coordinate of monitor's (working area's) right bound
	;                          ["TOP"]    = Y coordinate of monitor's (working area's) top bound
	;                          ["BOTTOM"] = Y coordinate of monitor's (working area's) bottom bound
	;                          ["WIDTH"]  = width of the monitor's work area
	;                          ["HEIGHT"] = height of the monitor's work area
	; NOTES:          This working area excludes things like the taskbar - it's the full space that a
	;                 window can occupy.
	;---------
	getMonitorWorkAreaForWindow(titleString) {
		winId := WinExist(titleString) ; Window handle
		
		; Get the monitor nearest to the window with the MonitorFromWindow function (https://docs.microsoft.com/en-us/windows/desktop/api/winuser/nf-winuser-monitorfromwindow )
		MONITOR_DEFAULTTONEAREST := 0x00000002 ; Get the monitor "closest" to the window
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
		
		workArea := {}
		workArea["LEFT"]   := NumGet(monitorInfo, memOffsetLeft,   "Int")
		workArea["TOP"]    := NumGet(monitorInfo, memOffsetTop,    "Int")
		workArea["RIGHT"]  := NumGet(monitorInfo, memOffsetRight,  "Int")
		workArea["BOTTOM"] := NumGet(monitorInfo, memOffsetBottom, "Int")
		this.addAdditionalBoundsInfo(workArea)
		
		return workArea
	}
	
	;---------
	; DESCRIPTION:    Determine whether the given window is on (or rather, nearest to, according to Windows) the monitor
	;                 with the given index.
	; PARAMETERS:
	;  titleString (I,REQ) - Title string representing the window.
	;  index       (I,REQ) - Index (according to AHK) of the monitor to check against.
	; RETURNS:        true/false - is the window on the given monitor?
	;---------
	isWindowOnMonitor(titleString, index) {
		return (this.getMonitorIndexForWindow(titleString) = index)
	}
	
	;---------
	; DESCRIPTION:    Determine whether the given window is on (or rather, nearest to, according to Windows) the monitor
	;                 with the given index.
	; PARAMETERS:
	;  titleString (I,REQ) - Title string representing the window.
	;  location    (I,REQ) - Location constant (from WindowLib.MonitorLocation_*) for which monitor location we're checking against.
	; RETURNS:        true/false - is the window on the monitor with the given location?
	;---------
	isWindowOnMonitorWithLocation(titleString, location) {
		workArea := this.monitorWorkAreaForLocation[location]
		locationIndex := workArea["MONITOR_INDEX"]
		
		return this.isWindowOnMonitor(titleString, locationIndex)
	}
	
	;---------
	; DESCRIPTION:    Find the monitor that the mouse is on and return its bounds.
	; RETURNS:        The bounds of the monitor that the mouse is on.
	; NOTES:          If the mouse is on the border between monitors, we will return the bottom-right most monitor.
	;---------
	getMouseMonitorBounds() {
		settings := new TempSettings().coordMode("Mouse", "Screen")
		MouseGetPos(mouseX, mouseY)
		settings.restore()
		
		partialMatches := []
		
		; Initial search - mouse must be within a monitor (not directly on an edge)
		Loop, % SysGet("MonitorCount") {
			bounds := SysGet("Monitor", A_Index)
			; Debug.popup("Testing",, "mouseX",mouseX, "mouseY",mouseY, "bounds",bounds)
			
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
				; Debug.popup("Partial match",, "mouseX",mouseX, "mouseY",mouseY, "bounds",bounds)
				partialMatches.push(bounds)
				Continue
			}
			
			foundBounds := bounds
			Break
		}
		
		; If we found an exact match, we're finished.
		if(foundBounds)
			return foundBounds
		
		; Debug.popup("No exact match",, "mouseX",mouseX, "mouseY",mouseY, "partialMatches",partialMatches)
		
		; If we only matched a single monitor partially, we're just along one of the outer edges of that monitor.
		if(partialMatches.count() = 1)
			return partialMatches[1]
		
		; If there were multiple, pick the lower-right-most monitor.
		foundBounds := ""
		For _,bounds in partialMatches {
			if(WindowLib.isSecondMonitorMoreLowerRight(foundBounds, bounds))
				foundBounds := bounds
		}
		
		return foundBounds
	}
	; =--
	
	
	; #PRIVATE#
	
	static _monitorWorkAreasByLocation := ""
	
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
	
	;---------
	; DESCRIPTION:    Get the bounds of all monitors, indexed by which position (left/middle/right) they are in.
	; RETURNS:        Array of monitor bounds - indices are WindowLib.MonitorLocation_* constants, and each monitor's
	;                 bounds come from .getMonitorWorkArea.
	; NOTES:          Assumes there are only 3 monitors, and they're laid out in a horizontal line.
	;---------
	getMonitorWorkAreasByLocation() {
		if(this._monitorWorkAreasByLocation)
			return this._monitorWorkAreasByLocation
		
		Loop, % SysGet("MonitorCount") {
			currMon := WindowLib.getMonitorWorkArea(A_Index)
			
			; If this is the first one we found, stick it into all spots.
			if(monLeft = "") {
				monLeft  := currMon
				monMid   := currMon
				monRight := currMon
				Continue
			}
			
			if(currMon["LEFT"] < monLeft["LEFT"])
				monLeft := currMon
			else if(currMon["LEFT"] > monRight["LEFT"])
				monRight := currMon
			else
				monMid := currMon
		}
		
		monitors := {}
		monitors[ WindowLib.MonitorLocation_Left   ] := monLeft
		monitors[ WindowLib.MonitorLocation_Middle ] := monMid
		monitors[ WindowLib.MonitorLocation_Right  ] := monRight
		
		this._monitorWorkAreasByLocation := monitors
		return monitors
	}
	
	;---------
	; DESCRIPTION:    Get the bounds of a specific monitor by its index.
	; PARAMETERS:
	;  index (I,REQ) - The index (according to AHK, not Windows) of the monitor.
	; RETURNS:        An array of monitor work area dimensions:
	;                    bounds["LEFT"]          = X coordinate of monitor work area's left edge
	;                    bounds["RIGHT"]         = X coordinate of monitor work area's right edge
	;                    bounds["TOP"]           = Y coordinate of monitor work area's top edge
	;                    bounds["BOTTOM"]        = Y coordinate of monitor work area's bottom edge
	;                    bounds["WIDTH"]         = Width of the monitor's work area
	;                    bounds["HEIGHT"]        = Height of the monitor's work area
	;                    bounds["MONITOR_INDEX"] = Monitor index (according to AHK)
	; NOTES:          This gives the monitor work area, not its total dimensions.
	;---------
	getMonitorWorkArea(index) {
		; Gives us left/right/top/bottom info
		bounds := SysGet("MonitorWorkArea", index)
		
		; Add width/height and monitor index (if not given)
		this.addAdditionalBoundsInfo(bounds, index)
		
		return bounds
	}
	
	;---------
	; DESCRIPTION:    Get the index (according to AHK) of the monitor that the given window is nearest to.
	; PARAMETERS:
	;  titleString (I,REQ) - Title string representing the window.
	; RETURNS:        The numeric index of the monitor that the window is on.
	;---------
	getMonitorIndexForWindow(titleString) {
		workArea := this.getMonitorWorkAreaForWindow(titleString)
		return workArea["MONITOR_INDEX"]
	}
	
	;---------
	; DESCRIPTION:    Add some additional info calculated onto the given bounds array for easy access.
	; PARAMETERS:
	;  bounds (IO,REQ) - The bounds array to update.
	;  index   (I,OPT) - If known, the index (according to AHK) of the monitor that these bounds represent. If blank, we'll
	;                    loop through all monitors to determine which one exactly matches these bounds.
	;---------
	addAdditionalBoundsInfo(ByRef bounds, index := "") {
		; Calculate width and height for easier access.
		bounds["WIDTH"]  := bounds["RIGHT"]  - bounds["LEFT"]
		bounds["HEIGHT"] := bounds["BOTTOM"] - bounds["TOP"]
		
		; If we weren't given the index, figure it out.
		if(index = "") {
			Loop, % SysGet("MonitorCount") {
				; Check for a match on either work area or full bounds
				if(this.boundsMatch(bounds, SysGet("MonitorWorkArea", A_Index))
				|| this.boundsMatch(bounds, SysGet("Monitor",         A_Index))) {
					index := A_Index
					Break
				}
			}
		}
		bounds["MONITOR_INDEX"] := index
	}
	
	;---------
	; DESCRIPTION:    Check whether two sets of bounds match on the most basic level (ignoring calculated values).
	; PARAMETERS:
	;  boundsA (I,REQ) - First set of bounds to check
	;  boundsB (I,REQ) - Second set of bounds to check
	; RETURNS:        true/false - are they the same?
	;---------
	boundsMatch(boundsA, boundsB) {
		; Just check the 4 edges - width/height are calculated from these values, and this logic typically
		; used to figure out index so we can't check that either.
		if(boundsA["LEFT"]   != boundsB["LEFT"])
			return false
		if(boundsA["RIGHT"]  != boundsB["RIGHT"])
			return false
		if(boundsA["TOP"]    != boundsB["TOP"])
			return false
		if(boundsA["BOTTOM"] != boundsB["BOTTOM"])
			return false
		
		return true
	}
	; #END#
}
