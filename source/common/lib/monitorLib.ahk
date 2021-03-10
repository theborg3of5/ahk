; Library of helpful functions for dealing with monitors.

class MonitorLib {
	; #PUBLIC#
	
	; @GROUP@ Monitor locations (only 3 monitors in a horizontal line supported)
	static Location_Left   := "LEFT"   ; Left-most monitor
	static Location_Middle := "MIDDLE" ; Center monitor
	static Location_Right  := "RIGHT"  ; Right-most monitor
	; @GROUP-END@
	
	;---------
	; DESCRIPTION:    
	; PARAMETERS:
	;  location (I,REQ) - The location of the monitor to get the work area bounds for, from MonitorLib.Location_*.
	; RETURNS:        Bounds array for the requested monitor (see .getMonitorWorkBounds)
	; SIDE EFFECTS:   
	; NOTES:          
	;---------
	workAreaForLocation[location] {
		get {
			if(location = "")
				return ""
			
			areas := this.getWorkAreasByLocation()
			return areas[location]
		}
	}
	
	;---------
	; DESCRIPTION:    Get the dimensions of the work area of the monitor "closest" (according to
	;                 Windows) to the given window.
	; PARAMETERS:
	;  titleString (I,REQ) - Title string that identifies your chosen window.
	; RETURNS:        Associative array of position/size information for the working area of the
	;                 monitor that the window is "closest" to. Format:
	;                    workArea["LEFT"]   = X coordinate of monitor's (working area's) left bound
	;                            ["RIGHT"]  = X coordinate of monitor's (working area's) right bound
	;                            ["TOP"]    = Y coordinate of monitor's (working area's) top bound
	;                            ["BOTTOM"] = Y coordinate of monitor's (working area's) bottom bound
	;                            ["WIDTH"]  = width of the monitor's work area
	;                            ["HEIGHT"] = height of the monitor's work area
	; NOTES:          This working area excludes things like the taskbar - it's the full space that a
	;                 window can occupy.
	;---------
	getWorkAreaForWindow(titleString) {
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
		return (this.getIndexForWindow(titleString) = index)
	}
	
	;---------
	; DESCRIPTION:    Determine whether the given window is on (or rather, nearest to, according to Windows) the monitor
	;                 with the given index.
	; PARAMETERS:
	;  titleString (I,REQ) - Title string representing the window.
	;  location    (I,REQ) - Location constant (from MonitorLib.Location_*) for which monitor location we're checking against.
	; RETURNS:        true/false - is the window on the monitor with the given location?
	;---------
	isWindowOnMonitorWithLocation(titleString, location) {
		workArea := this.workAreaForLocation[location]
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
			if(MonitorLib.isSecondMoreLowerRight(foundBounds, bounds))
				foundBounds := bounds
		}
		
		return foundBounds
	}
	
	
	; #PRIVATE#
	
	static _workAreasByLocation := ""
	
	;---------
	; DESCRIPTION:    Get the bounds of all monitors, indexed by which position (left/middle/right) they are in.
	; RETURNS:        Array of monitor bounds - indices are MonitorLib.Location_* constants, and each monitor's
	;                 bounds come from .getWorkArea.
	; NOTES:          Assumes there are only 3 monitors, and they're laid out in a horizontal line.
	;---------
	getWorkAreasByLocation() {
		if(this._workAreasByLocation)
			return this._workAreasByLocation
		
		; First get monitors, sorted left-to-right.
		monitorsByLeft := {}
		Loop, % SysGet("MonitorCount") {
			currMon := MonitorLib.getWorkArea(A_Index)
			monitorsByLeft[currMon["LEFT"]] := currMon
		}
		
		; Slot the monitors into matching, labelled indices
		monitorsInOrder := monitorsByLeft.toValuesArray()
		areasByLocation := {}
		areasByLocation[ MonitorLib.Location_Left   ] := monitorsInOrder[1]
		areasByLocation[ MonitorLib.Location_Middle ] := monitorsInOrder[2]
		areasByLocation[ MonitorLib.Location_Right  ] := monitorsInOrder[3]
		
		this._workAreasByLocation := areasByLocation
		return areasByLocation
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
	getWorkArea(index) {
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
	getIndexForWindow(titleString) {
		workArea := this.getWorkAreaForWindow(titleString)
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
		
		; If we weren't given the index, try to match it against a monitor.
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
	; DESCRIPTION:    Check whether two sets of monitor bounds match on the most basic level (ignoring calculated values).
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
	
	;---------
	; DESCRIPTION:    Determine which of the two bounds objects is the further lower and right.
	; PARAMETERS:
	;  firstBounds  (I,REQ) - The first bounds object. Important subscripts are "RIGHT" and "BOTTOM".
	;  secondBounds (I,REQ) - The second bounds object. Important subscripts are "RIGHT" and "BOTTOM".
	; RETURNS:        true if the second bounds object is further right or bottom, false otherwise.
	;---------
	isSecondMoreLowerRight(firstBounds, secondBounds) {
		if(firstBounds = "")
			return true
		
		if(secondBounds["RIGHT"] > firstBounds["RIGHT"])
			return true
		
		if(secondBounds["BOTTOM"] > firstBounds["BOTTOM"])
			return true
		
		return false
	}
	; #END#
}
