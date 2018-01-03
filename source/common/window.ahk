global WIN_ACTION_NONE         := "NONE"
global WIN_ACTION_OTHER        := "OTHER"
global WIN_ACTION_ACTIVATE     := "ACTIVATE"
global WIN_ACTION_CLOSE_WINDOW := "CLOSE_WINDOW"
global WIN_ACTION_ESC          := "ESC"
global WIN_ACTION_MIN          := "MIN"
global WIN_ACTION_SELECT_ALL   := "SELECT_ALL"
global WIN_ACTION_DELETE_WORD  := "DELETE_WORD"

global WIN_METHOD_DEFAULT := "DEFAULT"

global WIN_MIN_POST_MESSAGE  := "POST_MESSAGE"
global WIN_MIN_HIDE_TOOL_WIN := "HIDE_TOOL_WIN"

global WIN_SELECT_ALL_HOME_END := "HOME_END"

global WIN_DELETE_CTRL_SHIFT := "CTRL_SHIFT"

; Returns true if the current window's title contains any of a given array of strings.
titleContains(haystack) {
	WinGetActiveTitle, title
	return containsAnyOf(title, haystack) > 0
}
exeActive(exeName, partialMatch = false) {
	WinGet, currEXE, ProcessName, A
	if(partialMatch)
		return stringContains(currExe, exeName)
	else
		return (currEXE = exeName)
}

; See if a window exists or is active with a given TitleMatchMode.
isWindowInState(states = "", titles = "", texts = "", matchMode = 1, matchSpeed = "Fast", findHidden = "Off") {
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
waitUntilWindowState(state, title = "", text = "", matchMode = 1, matchSpeed = "Fast") {
	; Plug in the new match settings.
	origMatchSettings := setMatchSettings(matchMode, matchSpeed)
	
	; DEBUG.popup("Window state to wait on", state, "Window title to match", title, "Window text to match", text, "Title match mode", matchMode, "Title match speed", matchSpeed)
	
	if(state = "active")
		WinWaitActive, %title%, %text%
	else if(stringContains(state, "exist"))
		WinWait, %title%, %text%
	
	; Restore defaults when done.
	restoreMatchSettings(origMatchSettings)
}

; Get/set/restore various matching behavior states all at once.
setMatchSettings(mode = "", speed = "", detectHidden = "") {
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

; Get current control in a functional wrapper.
getFocusedControl(titleString = "A") {
	ControlGetFocus, outControl, %titleString%
	return outControl
}

; Focus a window, running the program if it doesn't yet exist.
activateProgram(progName) {
	progInfo := MainConfig.getProgram(progName)
	; DEBUG.popup("window.activateProgram", "start", "Program name", progName, "Program info", progInfo)
	
	winTitle := progInfo["TITLE"]
	winClass := progInfo["CLASS"]
	titleFindString := buildWindowTitleString(winTitle, winClass)
	; DEBUG.popup("Title string", titleFindString)
	
	; DEBUG.popup("Hotkey", A_ThisHotkey)
	waitForHotkeyRelease()
	
	; If the program is already running, go ahead and activate it.
	if(WinExist(titleFindString)) {
		activateWindow(winTitle, winClass)
		
	; If it doesn't exist yet, we need to run the executable to make it happen.
	} else {
		; DEBUG.popup("Run path", progInfo["PATH"])
		runProgram(progName, progInfo)
	}
}
runProgram(progName, progInfo = "") {
	if(!progInfo)
		progInfo := MainConfig.getProgram(progName)
	
	; DEBUG.popup("Run path", progInfo["PATH"])
	RunAsUser(progInfo["PATH"], progInfo["ARGS"])
}

getWindowSettingsAry(titleString = "A") {
	WinGetTitle, winTitle, %titleString%
	WinGetClass, winClass, %titleString%
	WinGet, winExe, ProcessName, %titleString%
	controlClass := getFocusedControl(titleString)
	
	return MainConfig.getWindow(winTitle, winClass, winExe, controlClass)
}
getWindowSetting(settingName, titleString = "A") {
	if(!settingName)
		return ""
	
	winSettings := getWindowSettingsAry(titleString)
	return winSettings[settingName]
}

; fillFromActive - whether to overwrite winTitle, winClass, and controlClass from the active window if they're blank.
processWindow(ByRef winTitle = "", ByRef winClass = "", ByRef controlClass = "", ByRef winSettings = "", action = "", fillFromActive = true) {
	if(fillFromActive) {
		if(!winTitle)
			WinGetTitle, winTitle, A
		if(!winClass)
			WinGetClass, winClass, A
		if(!controlClass)
			controlClass := getFocusedControl()
	}
	
	if(!IsObject(winSettings)) {
		winSettings := MainConfig.getWindow(winTitle, winClass, "", controlClass)
		
		if(fillFromActive) {
			if(!winSettings["WIN_TITLE"])
				winSettings["WIN_TITLE"] := winTitle
			if(!winSettings["WIN_CLASS"])
				winSettings["WIN_CLASS"] := winClass
			if(!winSettings["CONTROL_CLASS"])
				winSettings["CONTROL_CLASS"] := controlClass
		}
	}
	; DEBUG.popup("window.processWindow", "Got winSettings", "Window Settings", winSettings)
	
	; Figure out the method.
	method := winSettings[action]
	if(method = WIN_ACTION_OTHER) ; Special handling - WIN_ACTION_OTHER goes to a separate function first.
		method := doWindowActionSpecial(action, winTitle, winClass, controlClass, winSettings)
	if(!method) ; Return default if nothing found.
		method := WIN_METHOD_DEFAULT
	
	return method
}

doWindowAction(action, winSettings = "", winTitle = "", winClass = "", controlClass = "") {
	if(!action)
		return
	
	; Gather any needed info we're not given.
	processWindow(winTitle, winClass, controlClass, winSettings)
	; DEBUG.popup("doWindowAction", "", "Action", action, "Window settings", winSettings, "Class", winClass, "Title", winTitle)
	
	; Do that action.
	if(action = WIN_ACTION_NONE) {                ; WIN_ACTION_NONE means do nothing.
		return
		
	} else if(action = WIN_ACTION_ACTIVATE) {     ; Activate the given window
		activateWindow(winTitle, winClass, controlClass, winSettings)
		
	} else if(action = WIN_ACTION_CLOSE_WINDOW) { ; Close the given window
		closeWindow(winTitle, winClass, controlClass, winSettings)
		
	} else if(action = WIN_ACTION_ESC) {          ; React to the escape key (generally ends up minimizing or closing)
		doEscAction(winTitle, winClass, controlClass, winSettings)
		
	} else if(action = WIN_ACTION_MIN) {          ; Minimize the given window
		minimizeWindow(winTitle, winClass, controlClass, winSettings)
	
	} else if(action = WIN_ACTION_SELECT_ALL) {   ; Select all
		selectAll(winTitle, winClass, controlClass, winSettings)
		
	} else if(action = WIN_ACTION_DELETE_WORD) {  ; Delete one word, a la Ctrl+Backspace
		deleteWord(winTitle, winClass, controlClass, winSettings)
	
	} else {
		DEBUG.popup("window.doWindowAction", "Error", "Action not found", action)
	}
}

activateWindow(winTitle = "", winClass = "", controlClass = "", winSettings = "") { ; , winText = "", matchMode = "", matchSpeed = "", detectHidden = "") {
	; Gather any needed info we're not given.
	method := processWindow(winSettings, winTitle, winClass, controlClass, WIN_ACTION_ACTIVATE, false) ; Last parameter - don't overwrite a blank winTitle, winClass, or controlClass.
	; DEBUG.popup("activateWindow", "", "Activate method", method, "Window settings", winSettings, "Class", winClass, "Title", winTitle)
	
	; Get default window match settings for the given window from config.
	matchMode    := winSettings["MATCH_MODE"]
	matchSpeed   := winSettings["MATCH_SPEED"]
	detectHidden := winSettings["DETECT_HIDDEN"]
	
	; Do it!
	if(method = WIN_METHOD_DEFAULT) { ; Generic case.
		origMatchSettings := setMatchSettings(matchMode, matchSpeed, detectHidden)
		titleFindString := buildWindowTitleString(winTitle, winClass)
		WinShow, % titleFindString
		WinActivate, % titleFindString
		restoreMatchSettings(origMatchSettings)
		
	} else {
		doWindowAction(method, winSettings, winTitle, winClass, controlClass)
	}
}

doEscAction(winTitle = "", winClass = "", controlClass = "", winSettings = "") {
	; Gather any needed info we're not given.
	method := processWindow(winTitle, winClass, controlClass, winSettings, WIN_ACTION_ESC)
	; DEBUG.popup("doEscAction", "", "Action", method, "Window settings", winSettings, "Class", winClass, "Title", winTitle)
	
	if(method = WIN_METHOD_DEFAULT) { ; Default is to do nothing.
		return
	} else {
		doWindowAction(method, winSettings, winTitle, winClass, controlClass)
	}
}

closeWindow(winTitle = "", winClass = "", controlClass = "", winSettings = "") { ; controlClass and closeMethod currently ignored/unused, but left in for consistency with other methods and future needs.
	; No special cases for closing, and not likely to be one, so ignoring method and other such stuff for now.
	; DEBUG.popup("Settings", winSettings, "Title", winTitle, "Control class", controlClass, "Close method", closeMethod)
	
	titleString := buildWindowTitleString(winTitle, winClass)
	WinClose, %titleString%
}

minimizeWindow(winTitle = "", winClass = "", controlClass = "", winSettings = "") {
	; Gather any needed info we're not given.
	method := processWindow(winTitle, winClass, controlClass, winSettings, WIN_ACTION_MIN)
	; DEBUG.popup("minimizeWindow", "", "Min method", method, "Window settings", winSettings, "Class", winClass, "Title", winTitle)
	
	; Do it!
	titleFindString := buildWindowTitleString(winTitle, winClass)
	if(method = WIN_METHOD_DEFAULT) { ; Generic case.
		WinMinimize, %titleFindString%
	
	} else if(method = WIN_MIN_POST_MESSAGE) {
		PostMessage, 0x112, 0xF020 , , , %titleFindString%
		
	} else if(method = WIN_MIN_HIDE_TOOL_WIN) { ; Special deal to hide away tool-type windows (hidden from taskbar)
		WinMinimize
		WinHide
		WinSet, Redraw
		WinSet, Bottom
		
	} else {
		doWindowAction(method, winSettings, winTitle, winClass, controlClass)
	}
}

; Select all text in a control, generally via use fo the Ctrl+A hotkey.
selectAll(winTitle = "", winClass = "", controlClass = "", winSettings = "") {
	; Gather any needed info we're not given.
	method := processWindow(winTitle, winClass, controlClass, winSettings, WIN_ACTION_SELECT_ALL)
	; DEBUG.popup("selectAll", "", "Select method", method, "Window settings", winSettings, "Class", winClass, "Title", winTitle)

	; Do it!
	if(method = WIN_METHOD_DEFAULT) { ; Generic case.
		Send, ^a
		
	} else if(method = WIN_SELECT_ALL_HOME_END) { ; For older places that don't allow it properly.
		Send, ^{Home}
		Send, ^+{End}
		
	} else {
		doWindowAction(method, winSettings, winTitle, winClass, controlClass)
	}
}

; Delete a word, generally via use of the Ctrl+Backspace hotkey.
deleteWord(winTitle = "", winClass = "", controlClass = "", winSettings = "") {
	; Gather any needed info we're not given.
	method := processWindow(winTitle, winClass, controlClass, winSettings, WIN_ACTION_DELETE_WORD)
	; DEBUG.popup("selectAll", "", "Delete method", method, "Window settings", winSettings, "Class", winClass, "Title", winTitle)

	; Do it!
	if(method = WIN_METHOD_DEFAULT) { ; Generic case.
		Send, ^{Backspace}
		
	} else if(method = WIN_DELETE_CTRL_SHIFT) { ; For older places that don't allow it properly.
		Send, ^+{Left}
		Send, {Backspace}
		
	} else {
		doWindowAction(method, winSettings, winTitle, winClass, controlClass)
	}
}

; For all special cases for just a single case, so not worth creating a new constant, etc for.
; The return value should be what we should do from here - so if we end up deciding that a 
; standard method works, just return that constant.
doWindowActionSpecial(action, winTitle = "", winClass = "", controlClass = "", winSettings = "") {
	method := WIN_ACTION_NONE ; Start with the assumption that we shouldn't do anything after this - the specific cases will say otherwise if needed.
	
	if(action = WIN_ACTION_ESC) {
		; Guru Quick Dial Popup
		if(winClass = "WindowsForms10.Window.8.app.0.1517e87") {
			ControlFocus, WindowsForms10.BUTTON.app.0.1517e871, A ; Hang up button
			Send, {Space}
			method := WIN_ACTION_NONE
		}
		
	} else if(action = WIN_ACTION_MIN) {
		; Windows explorer
		if(winClass = MainConfig.getProgram("Explorer", "CLASS")) {
			if(MainConfig.isMachine(MACHINE_EpicLaptop)) { ; QTTabBar's min to tray
				Send, !q
				method := WIN_ACTION_NONE
			} else {
				method := WIN_METHOD_DEFAULT
			}
		}
	}
	
	; DEBUG.popup("window.doWindowActionSpecial", "Finished", "Action", action, "Method", method)
	return method
}


; Puts together a string that can be used with the likes of WinActivate, etc.
buildWindowTitleString(winTitle = "", winClass = "", winId = "", processID = "", exeName = "", groupName = "") {
	if(winTitle)
		outStr .= winTitle
	
	if(winClass)
		outStr .= " ahk_class " winClass
	
	if(winId)
		outStr .= " ahk_id " winId
	
	if(processID)
		outStr .= " ahk_pid " processID
	
	if(exeName)
		outStr .= " ahk_exe " exeName
	
	if(groupName)
		outStr .= " ahk_group " groupName
	
	return outStr
}

; Centers a window on the screen.
centerWindow(titleString = "A") {
	winId := WinExist(titleString)
	idString := "ahk_id " winId
	
	; Window size
	WinGetPos, , , winW, winH, %idString%
	offsetsAry := getWindowOffsets(idString)
	winW -= (offsetsAry["LEFT"]   + offsetsAry["RIGHT"]) ; The window is wider/taller than it looks by these offsets.
	winH -= (offsetsAry["BOTTOM"] + offsetsAry["TOP"]  )
	
	; Make sure that our screen sizes take which monitor we're on into account.
	currMonbounds := getMonitorBounds("", idString)
	
	; Coordinates relative to screen
	relX := (currMonbounds["WIDTH"]  - winW) / 2
	relY := (currMonbounds["HEIGHT"] - winH) / 2
	
	; True coordinates
	x := currMonbounds["LEFT"] + relX - offsetsAry["LEFT"]
	y := currMonbounds["TOP"]  + relY - offsetsAry["TOP"]
	
	; DEBUG.popup("Screen bounds", currMonbounds, "Offsets", offsetsAry, "WinW", winW, "WinH", winH, "Relative X", relX, "Relative Y", relY, "X", x, "Y", y)
	WinMove, %idString%, , x, y
}

fakeMaximizeWindow(titleString = "A") {
	winId := WinExist(titleString)
	idString := "ahk_id " winId
	
	boundsAry  := getMonitorBounds( , idString)
	offsetsAry := getWindowOffsets(idString)
	
	newWidth  := boundsAry["WIDTH"] + offsetsAry["LEFT"] + offsetsAry["RIGHT"]
	newHeight := boundsAry["HEIGHT"] + offsetsAry["TOP"] + offsetsAry["BOTTOM"]
	
	; DEBUG.popup("Bounds", boundsAry, "Offsets", offsetsAry, "New width", newWidth, "New height", newHeight)
	resizeWindow(newWidth, newHeight, idString)
	centerWindow()
}

; Jacked from http://www.howtogeek.com/howto/28663/create-a-hotkey-to-resize-windows-to-a-specific-size-with-autohotkey/
resizeWindow(width = "", height = "", titleString = "A") {
	WinGetPos, X, Y, W, H, %titleString%
	if(!width)
		width  := W
	if(!height)
		height := H
	
	WinMove, A, , %X%, %Y%, %width%, %height%
}


getWindowOffsets(titleString = "A") {
	global SM_CXMAXIMIZED, SM_CYMAXIMIZED, SM_CXBORDER, SM_CYBORDER
	offsetsAry := []
	
	offsetOverride := getWindowSetting("WINDOW_EDGE_OFFSET_OVERRIDE", titleString)
	if(offsetOverride != "") { ; Specific window has an override.
		offsetsAry["LEFT"]   := offsetOverride
		offsetsAry["RIGHT"]  := offsetOverride
		offsetsAry["TOP"]    := offsetOverride
		offsetsAry["BOTTOM"] := offsetOverride
	} else { ; Calculate it.
		SysGet, maximizedWidth,    %SM_CXMAXIMIZED% ; For non-3D windows (which should be most), the width of the border on the left and right.
		SysGet, maximizedHeight,   %SM_CYMAXIMIZED% ; For non-3D windows (which should be most), the width of the border on the top and bottom.
		SysGet, borderWidthX,      %SM_CXBORDER%    ; Width of a maximized window on the primary monitor. Includes any weird offsets.
		SysGet, borderWidthY,      %SM_CYBORDER%    ; Height of a maximized window on the primary monitor. Includes any weird offsets.
		SysGet, primaryMonitorNum, MonitorPrimary   ; We're assuming the taskbar is in the same place on all monitors, which is fine for my purposes.
		bounds := getMonitorBounds(primaryMonitorNum)
		
		; (Maximized size - monitor working area - both borders) / 2
		offsetX := (maximizedWidth  - bounds["WIDTH"]  - (borderWidthX * 2)) / 2
		offsetY := (maximizedHeight - bounds["HEIGHT"] - (borderWidthY * 2)) / 2
		
		offsetsAry["LEFT"]   := offsetX
		offsetsAry["RIGHT"]  := offsetX
		offsetsAry["TOP"]    := offsetY
		offsetsAry["BOTTOM"] := offsetY
	}
	
	; Assuming the taskbar is on top, otherwise could use something like https://autohotkey.com/board/topic/91513-function-get-the-taskbar-location-win7/ to figure out where it is.
	offsetsAry["TOP"] := 0 ; Taskbar side never has an offset.
	
	return offsetsAry
}

getMonitorBounds(monitorNum = "", titleString = "") {
	monitorsAry := getMonitorBoundsAry()
	
	if(!monitorNum)
		monitorNum := getWindowMonitor(titleString, monitorsAry)
	
	return monitorsAry[monitorNum]
}
; Returns an array of monitors with LEFT/RIGHT/TOP/BOTTOM values for their working area (doesn't include taskbar or other toolbars).
getMonitorBoundsAry() {
	monitorsAry := []
	
	SysGet, numMonitors, MonitorCount
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


moveWindowToMonitor(titleString, destMonitor, monitorsAry = "") {
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
	WinGet, minMaxState, MinMax, %titleString%
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

; Get the index of the monitor containing the specified x and y co-ordinates.
; Adapted from http://www.autohotkey.com/board/topic/69464-how-to-determine-a-window-is-in-which-monitor/
getWindowMonitor(titleString, monitorsAry = "") {
	; If monitorsAry isn't given, make our own...with blackjack and hookers.
	if(!IsObject(monitorsAry))
		monitorsAry := getMonitorBoundsAry()
	; DEBUG.popup("Monitor list", monitorsAry, "Title string", titleString)
	
	; Get the X/Y for the given window.
	WinGetPos, winX, winY, , , %titleString%
	
	; Account for any window offsets.
	offsetsAry := getWindowOffsets(idString)
	winX += offsetsAry["LEFT"] ; The window is wider/taller than it looks by these offsets.
	winY += offsetsAry["TOP"]
	
	WinGet, minMaxState, MinMax, %titleString%
	if(minMaxState = 1) ; Window is maximized
		winX += 1
	
	; Iterate over all monitors until we find a match.
	For i,mon in monitorsAry {
		monLeft   := mon["LEFT"]
		monRight  := mon["RIGHT"]
		monTop    := mon["TOP"]
		monBottom := mon["BOTTOM"]
		
		; Check if the window is on this monitor.
		; DEBUG.popup("Monitor", A_Index, "Left", MonLeft, "Right", MonRight, "Top", MonTop, "Bottom", MonBottom, "Window X", winX, "Window Y", winY)
		if(winX >= MonLeft && winX < MonRight && winY >= MonTop && winY < MonBottom)
			return A_Index
	}
	
	return -1
}
