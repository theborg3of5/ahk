global WIN_ACTION_NONE        := "NONE"
global WIN_ACTION_OTHER       := "OTHER"
global WIN_ACTION_ACTIVATE    := "ACTIVATE"
global WIN_ACTION_CLOSE       := "CLOSE"
global WIN_ACTION_ESC         := "ESC"
global WIN_ACTION_MIN         := "MIN"
global WIN_ACTION_SELECT_ALL  := "SELECT_ALL"
global WIN_ACTION_DELETE_WORD := "DELETE_WORD"

global WIN_METHOD_DEFAULT := "DEFAULT"

global WIN_MIN_POST_MESSAGE  := "POST_MESSAGE"

global WIN_SELECT_ALL_HOME_END := "HOME_END"

global WIN_DELETE_CTRL_SHIFT := "CTRL_SHIFT"

; Convenience function to get the full window title string using the NAME column in programs.tl.
getProgramTitleString(progName, ByRef progInfo = "") {
	if(!progName)
		return ""
	if(!progInfo)
		progInfo := MainConfig.getProgram(progName)
	
	winExe   := progInfo["EXE"]
	winClass := progInfo["CLASS"]
	winTitle := progInfo["TITLE"]
	titleString := buildWindowTitleString(winExe, winClass, winTitle)
	; DEBUG.popup("getProgramTitleString","", "progName",progName, "winExe",winExe, "winClass",winClass, "winTitle",winTitle, "Title string",titleString)
	
	return titleString
}
; Convenience function to get the full window title string using the NAME column in windows.tl.
getWindowTitleString(winName) {
	if(!winName)
		return ""
	
	winSettings := MainConfig.getWindow(winName)
	winExe   := winSettings["EXE"]
	winClass := winSettings["CLASS"]
	winTitle := winSettings["TITLE"]
	titleString := buildWindowTitleString(winExe, winClass, winTitle)
	
	; DEBUG.popup("getWindowTitleString","", "winName",winName, "winExe",winExe, "winClass",winClass, "winTitle",winTitle, "Title string",titleString)
	return titleString
}
; Puts together a string that can be used with the likes of WinActivate, etc.
buildWindowTitleString(exeName = "", winClass = "", winTitle = "") {
	if(winTitle) ; Title has to go first since it doesn't have an "ahk_" identifier to go with it.
		outStr .= winTitle
	
	if(exeName)
		outStr .= " ahk_exe " exeName
	
	if(winClass)
		outStr .= " ahk_class " winClass
	
	return outStr
}

; Returns true if the current window's title contains any of a given array of strings.
titleContains(haystack) {
	title := WinGetActiveTitle()
	return containsAnyOf(title, haystack) > 0
}
exeActive(exeName, partialMatch = false) {
	currEXE := WinGet("ProcessName", "A")
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

; Focus a window, running the program if it doesn't yet exist.
activateProgram(progName) {
	waitForHotkeyRelease()
	
	progInfo := MainConfig.getProgram(progName)
	titleString := getProgramTitleString(progName, progInfo)
	; DEBUG.popup("window.activateProgram","start", "Program name",progName, "Program info",progInfo, "Title string",titleString)
	
	winId := WinExist(titleString, progInfo["TEXT"])
	if(winId) ; If the program is already running, go ahead and activate it.
		activateWindow("ahk_id " winId)
	else ; If it doesn't exist yet, we need to run the executable to make it happen.
		RunAsUser(progInfo["PATH"], progInfo["ARGS"])
}
runProgram(progName) {
	waitForHotkeyRelease()
	
	progInfo := MainConfig.getProgram(progName)
	
	RunAsUser(progInfo["PATH"], progInfo["ARGS"])
}

getWindowSettingsAry(titleString = "A") {
	winExe   := WinGet("ProcessName", titleString)
	winClass := WinGetClass(titleString)
	winTitle := WinGetTitle(titleString)
	winText  := WinGetText(titleString)
	return MainConfig.getWindow("", winExe, winClass, winTitle, winText)
}
getWindowSetting(settingName, titleString = "A") {
	if(!settingName)
		return ""
	
	winSettings := getWindowSettingsAry(titleString)
	return winSettings[settingName]
}

doWindowAction(action, titleString = "A", winSettings = "") {
	if(!action)
		return
	
	; Do that action.
	if(action = WIN_ACTION_NONE)             ; WIN_ACTION_NONE means do nothing.
		return
	else if(action = WIN_ACTION_ACTIVATE)    ; Activate the given window
		activateWindow(titleString, winSettings)
	else if(action = WIN_ACTION_CLOSE)       ; Close the given window
		closeWindow(titleString, winSettings)
	else if(action = WIN_ACTION_ESC)         ; React to the escape key (generally to minimize or close the window)
		doEscAction(titleString, winSettings)
	else if(action = WIN_ACTION_MIN)         ; Minimize the given window
		minimizeWindow(titleString, winSettings)
	else if(action = WIN_ACTION_SELECT_ALL)  ; Select all
		selectAll(titleString, winSettings)
	else if(action = WIN_ACTION_DELETE_WORD) ; Backspace one word
		deleteWord(titleString, winSettings)
	else
		DEBUG.popup("window.doWindowAction", "Error", "Action not found", action)
}

processWindow(ByRef titleString = "A", action = "", ByRef winSettings = "") {
	if(!titleString)
		return ""
	
	; Identify the window with regards to our settings.
	if(!IsObject(winSettings))
		winSettings := getWindowSettingsAry(titleString)
	; DEBUG.popup("window.processWindow", "Got winSettings", "Window Settings", winSettings)
	
	; If there's some text that has to be in the window, turn the titleString 
	; into one with a unique window ID, so that's taken into account.
	; Leave active window (A) alone though, since you can't use window text 
	; with that and it's already a single target by definition.
	if(winSettings["TEXT"] && titleString != "A") {
		winExe   := winSettings["EXE"]
		winClass := winSettings["CLASS"]
		winTitle := winSettings["TITLE"]
		winText  := winSettings["TEXT"]
		
		titleString := "ahk_id " WinExist(buildWindowTitleString(winExe, winClass, winTitle), winText)
	}
	
	; Figure out the method (how we're going to perform the action).
	method := winSettings[action]
	if(method = WIN_ACTION_OTHER) ; Special handling - WIN_ACTION_OTHER goes to a separate function first.
		method := windowMethodSpecial(winSettings, action)
	if(!method) ; Return default if nothing found.
		method := WIN_METHOD_DEFAULT
	
	return method
}

activateWindow(titleString = "A", winSettings = "") {
	method := processWindow(titleString, WIN_ACTION_ACTIVATE, winSettings)
	; DEBUG.popup("activateWindow","", "Title string",titleString, "Window settings",winSettings, "Method",method)
	
	if(method = WIN_METHOD_DEFAULT) {
		WinShow,     %titleString%
		WinActivate, %titleString%
	} else {
		doWindowAction(method, titleString, winSettings)
	}
}
doEscAction(titleString = "A", winSettings = "") {
	method := processWindow(titleString, WIN_ACTION_ESC, winSettings)
	; DEBUG.popup("doEscAction","", "Title string",titleString, "Window settings",winSettings, "Method",method)
	
	if(method = WIN_METHOD_DEFAULT) ; Default is to do nothing.
		return
	else
		doWindowAction(method, titleString, winSettings)
}
closeWindow(titleString = "A", winSettings = "") {
	method := processWindow(titleString, WIN_ACTION_CLOSE, winSettings)
	; DEBUG.popup("closeWindow","", "Title string",titleString, "Window settings",winSettings, "Method",method)
	
	if(method = WIN_METHOD_DEFAULT)
		WinClose, %titleString%
	else
		doWindowAction(method, titleString, winSettings)
}
minimizeWindow(titleString = "A", winSettings = "") {
	method := processWindow(titleString, WIN_ACTION_MIN, winSettings)
	; DEBUG.popup("minimizeWindow","", "Title string",titleString, "Window settings",winSettings, "Method",method)
	
	if(method = WIN_METHOD_DEFAULT) {
		WinMinimize, %titleString%
	
	} else if(method = WIN_MIN_POST_MESSAGE) {
		PostMessage, 0x112, 0xF020 , , , %titleString%
	
	} else {
		doWindowAction(method, titleString, winSettings)
	}
}
; Select all text in a control, generally via use fo the Ctrl+A hotkey.
selectAll(titleString = "A", winSettings = "") {
	method := processWindow(titleString, WIN_ACTION_SELECT_ALL, winSettings)
	; DEBUG.popup("selectAll","", "Title string",titleString, "Window settings",winSettings, "Method",method)
	
	if(method = WIN_METHOD_DEFAULT) {
		Send, ^a
	
	} else if(method = WIN_SELECT_ALL_HOME_END) { ; For older places that don't allow it properly.
		Send, ^{Home}
		Send, ^+{End}
	
	} else {
		doWindowAction(method, titleString, winSettings)
	}
}
; Delete a word, generally via use of the Ctrl+Backspace hotkey.
deleteWord(titleString = "A", winSettings = "") {
	method := processWindow(titleString, WIN_ACTION_DELETE_WORD, winSettings)
	; DEBUG.popup("deleteWord","", "Title string",titleString, "Window settings",winSettings, "Method",method)
	
	if(method = WIN_METHOD_DEFAULT) {
		Send, ^{Backspace}
		
	} else if(method = WIN_DELETE_CTRL_SHIFT) { ; For older places that don't allow it properly.
		Send, ^+{Left}
		Send, {Backspace}
		
	} else {
		doWindowAction(method, titleString, winSettings)
	}
}
; For all special cases for just a single case, so not worth creating a new constant, etc for.
; The return value should be what we should do from here - so if we end up deciding that a 
; standard method works, just return that constant. If it's not standard, just do it and then 
; return WIN_ACTION_NONE.
windowMethodSpecial(winSettings = "", action = "") {
	global TITLE_MATCH_MODE_Contain
	; DEBUG.popup("windowMethodSpecial","", "Settings",winSettings, "Action",action)
	
	if(!action)
		return ""
	
	method := WIN_ACTION_NONE ; Start with the assumption that we shouldn't do anything after this - the specific cases will say otherwise if needed.
	
	; Windows explorer
	if(winSettings["NAME"] = "Explorer")
		if(action = WIN_ACTION_MIN)
			Send, !q ; QTTabBar's min to tray
	
	; Spotify
	if(winSettings["NAME"] = "Spotify") {
		if(action = WIN_ACTION_CLOSE) {
			; Spotify has a whole bunch of windows that are difficult to tell apart from 
			; the real thing, so make sure we're closing the right one.
			
			; Title is "Spotify" if not playing anything, and has a hyphen between the title and artist if it is playing something.
			spotifyTitleBase := " ahk_exe Spotify.exe"
			titleAry := []
			titleAry.push("Spotify" spotifyTitleBase)
			titleAry.push("-" spotifyTitleBase)
			
			winId := isWindowInState("exists", titleAry, "", TITLE_MATCH_MODE_Contain, "", "On")
			WinClose, ahk_id %winId%
		}
	}
	
	; DEBUG.popup("window.windowMethodSpecial","Finished", "Action",action, "Method",method, "Settings",winSettings)
	return method
}

; Centers a window on the screen.
centerWindow(titleString = "A") {
	; Window size
	WinGetPos, , , winW, winH, %titleString%
	offsetsAry := getWindowOffsets(titleString)
	winW -= (offsetsAry["LEFT"]   + offsetsAry["RIGHT"]) ; The window is wider/taller than it looks by these offsets.
	winH -= (offsetsAry["BOTTOM"] + offsetsAry["TOP"]  )
	
	; Make sure that our screen sizes take which monitor we're on into account.
	currMonbounds := getMonitorBounds("", titleString)
	
	; Coordinates relative to screen
	relX := (currMonbounds["WIDTH"]  - winW) / 2
	relY := (currMonbounds["HEIGHT"] - winH) / 2
	
	; True coordinates
	x := currMonbounds["LEFT"] + relX - offsetsAry["LEFT"]
	y := currMonbounds["TOP"]  + relY - offsetsAry["TOP"]
	
	; DEBUG.popup("Screen bounds", currMonbounds, "Offsets", offsetsAry, "WinW", winW, "WinH", winH, "Relative X", relX, "Relative Y", relY, "X", x, "Y", y)
	WinMove, %titleString%, , x, y
}

fakeMaximizeWindow(titleString = "A") {
	boundsAry  := getMonitorBounds( , titleString)
	offsetsAry := getWindowOffsets(titleString)
	
	newWidth  := boundsAry["WIDTH"] + offsetsAry["LEFT"] + offsetsAry["RIGHT"]
	newHeight := boundsAry["HEIGHT"] + offsetsAry["TOP"] + offsetsAry["BOTTOM"]
	
	; DEBUG.popup("Bounds", boundsAry, "Offsets", offsetsAry, "New width", newWidth, "New height", newHeight)
	resizeWindow(newWidth, newHeight, titleString)
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
		maximizedWidth    := SysGet(SM_CXMAXIMIZED)   ; For non-3D windows (which should be most), the width of the border on the left and right.
		maximizedHeight   := SysGet(SM_CYMAXIMIZED)   ; For non-3D windows (which should be most), the width of the border on the top and bottom.
		borderWidthX      := SysGet(SM_CXBORDER)      ; Width of a maximized window on the primary monitor. Includes any weird offsets.
		borderWidthY      := SysGet(SM_CYBORDER)      ; Height of a maximized window on the primary monitor. Includes any weird offsets.
		primaryMonitorNum := SysGet("MonitorPrimary") ; We're assuming the taskbar is in the same place on all monitors, which is fine for my purposes.
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
	offsetsAry := getWindowOffsets(titleString)
	winX += offsetsAry["LEFT"] ; The window is wider/taller than it looks by these offsets.
	winY += offsetsAry["TOP"]
	
	if(WinGet("MinMax", titleString) = 1) ; Window is maximized
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

activateWindowUnderMouse() {
	MouseGetPos( , , winId)
	activateWindow("ahk_id " winId)
}
