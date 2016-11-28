global WS_EX_CONTROLPARENT = 0x10000
global WS_EX_APPWINDOW     = 0x40000
global WS_EX_TOOLWINDOW    = 0x80
global WS_DISABLED         = 0x8000000
global WS_POPUP            = 0x80000000

global ACTION_NONE         := "NONE"
global ACTION_OTHER        := "OTHER"
global ACTION_ACTIVATE     := "ACTIVATE"
global ACTION_CLOSE_WINDOW := "CLOSE_WINDOW"
global ACTION_ESC          := "ESC"
global ACTION_MIN          := "MIN"
global ACTION_SELECT_ALL   := "SELECT_ALL"
global ACTION_DELETE_WORD  := "DELETE_WORD"

global METHOD_DEFAULT := "DEFAULT"

global MIN_POST_MESSAGE  := "POST_MESSAGE"
global MIN_HIDE_TOOL_WIN := "HIDE_TOOL_WIN"

global SELECT_ALL_HOME_END := "HOME_END"

global DELETE_CTRL_SHIFT := "CTRL_SHIFT"

global MATCH_MODE                  := "MATCH_MODE"
global MATCH_SPEED                 := "MATCH_SPEED"
global MATCH_DETECT_HIDDEN_WINDOWS := "DETECT_HIDDEN"

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
isWindowInStates(states, titles, texts, matchMode = 1, matchSpeed = "Fast", findHidden = "Off") {
	if(!states)
		states := [""]
	if(!titles)
		titles := [""]
	if(!texts)
		texts := [""]
	
	; DEBUG.popup("Window states to check", states, "Window titles to match", titles, "Window texts to match", texts, "Title match mode", matchMode)
	
	retVal := false
	For i,s in states {
		For j,t in titles {
			For k,x in texts {
				if(isWindowInState(s, t, x, matchMode, matchSpeed)) {
					return true
				}
			}
		}
	}
	
	return false
}

isWindowInState(state, title = "", text = "", matchMode = 1, matchSpeed = "Fast") {
	; DEBUG.popup("Window state to check", state, "Window title to match", title, "Window text to match", text, "Title match mode", matchMode, "Title match speed", matchSpeed)
	
	; Plug in the new match settings.
	origMatchSettings := setMatchSettings(matchMode, matchSpeed)
	
	retVal := false
	if(state = "active")
		retVal := WinActive(title, text)
	else if(stringContains(state, "exist"))
		retVal := WinExist(title, text)
	
	; Restore defaults when done.
	restoreMatchSettings(origMatchSettings)
	
	; DEBUG.popup("Window state to check", state, "Window title to match", title, "Window text to match", text, "Title match mode", matchMode, "Result", retVal)
	return retVal
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
getMatchSettings() {
	settings := Object()
	settings["MODE"]          := A_TitleMatchMode
	settings["SPEED"]         := A_TitleMatchModeSpeed
	settings["DETECT_HIDDEN"] := A_DetectHiddenWindows
	
	return settings
}
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
restoreMatchSettings(settings) {
	if(!settings)
		return
	
	SetTitleMatchMode,   % settings["MODE"]
	SetTitleMatchMode,   % settings["SPEED"]
	DetectHiddenWindows, % settings["DETECT_HIDDEN"]
}

; Get current control in a functional wrapper.
getFocusedControl() {
	ControlGetFocus, outControl, A
	return outControl
}

; Check current control for a match.
isFocusedControl(testControl) {
	if(testControl = getFocusedControl())
		return true
	return false
}

; Focus a window, running the program if it doesn't yet exist.
activateProgram(progName) {
	progInfo := BorgConfig.getProgram(progName)
	; DEBUG.popup("window.activateProgram", "start", "Program name", progName, "Program info", progInfo)
	
	winTitle := progInfo["TITLE"]
	winClass := progInfo["CLASS"]
	titleFindString := buildWindowTitleString(winTitle, winClass)
	; DEBUG.popup("Title string", titleFindString)
	
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
		progInfo := BorgConfig.getProgram(progName)
	
	; DEBUG.popup("Run path", progInfo["PATH"])
	RunAsUser(progInfo["PATH"], progInfo["ARGS"])
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
		winSettings := BorgConfig.getWindow(winTitle, winClass, controlClass)
		
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
	if(method = ACTION_OTHER) ; Special handling - ACTION_OTHER goes to a separate function first.
		method := doWindowActionSpecial(action, winTitle, winClass, controlClass, winSettings)
	if(!method) ; Return default if nothing found.
		method := METHOD_DEFAULT
	
	return method
}

doWindowAction(action, winSettings = "", winTitle = "", winClass = "", controlClass = "") {
	if(!action)
		return
	
	; Gather any needed info we're not given.
	processWindow(winTitle, winClass, controlClass, winSettings)
	; DEBUG.popup("doWindowAction", "", "Action", action, "Window settings", winSettings, "Class", winClass, "Title", winTitle)
	
	; Do that action.
	if(action = ACTION_NONE) {                ; ACTION_NONE means do nothing.
		return
		
	} else if(action = ACTION_ACTIVATE) {     ; Activate the given window
		activateWindow(winTitle, winClass, controlClass, winSettings)
		
	} else if(action = ACTION_CLOSE_WINDOW) { ; Close the given window
		closeWindow(winTitle, winClass, controlClass, winSettings)
		
	} else if(action = ACTION_ESC) {          ; React to the escape key (generally ends up minimizing or closing)
		doEscAction(winTitle, winClass, controlClass, winSettings)
		
	} else if(action = ACTION_MIN) {          ; Minimize the given window
		minimizeWindow(winTitle, winClass, controlClass, winSettings)
	
	} else if(action = ACTION_SELECT_ALL) {   ; Select all
		selectAll(winTitle, winClass, controlClass, winSettings)
		
	} else if(action = ACTION_DELETE_WORD) {  ; Delete one word, a la Ctrl+Backspace
		deleteWord(winTitle, winClass, controlClass, winSettings)
	
	} else {
		DEBUG.popup("window.doWindowAction", "Error", "Action not found", action)
	}
}

activateWindow(winTitle = "", winClass = "", controlClass = "", winSettings = "") { ; , winText = "", matchMode = "", matchSpeed = "", detectHidden = "") {
	; Gather any needed info we're not given.
	method := processWindow(winSettings, winTitle, winClass, controlClass, ACTION_ACTIVATE, false) ; Last parameter - don't overwrite a blank winTitle, winClass, or controlClass.
	; DEBUG.popup("activateWindow", "", "Activate method", method, "Window settings", winSettings, "Class", winClass, "Title", winTitle)
	
	; Get default window match settings for the given window from config.
	matchMode    := winSettings[MATCH_MODE]
	matchSpeed   := winSettings[MATCH_SPEED]
	detectHidden := winSettings[MATCH_DETECT_HIDDEN_WINDOWS]
	
	; Do it!
	if(method = METHOD_DEFAULT) { ; Generic case.
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
	method := processWindow(winTitle, winClass, controlClass, winSettings, ACTION_ESC)
	; DEBUG.popup("doEscAction", "", "Action", method, "Window settings", winSettings, "Class", winClass, "Title", winTitle)
	
	if(method = METHOD_DEFAULT) { ; Default is to do nothing.
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
	method := processWindow(winTitle, winClass, controlClass, winSettings, ACTION_MIN)
	; DEBUG.popup("minimizeWindow", "", "Min method", method, "Window settings", winSettings, "Class", winClass, "Title", winTitle)
	
	; Do it!
	titleFindString := buildWindowTitleString(winTitle, winClass)
	if(method = METHOD_DEFAULT) { ; Generic case.
		WinMinimize, %titleFindString%
	
	} else if(method = MIN_POST_MESSAGE) {
		PostMessage, 0x112, 0xF020 , , , %titleFindString%
		
	} else if(method = MIN_HIDE_TOOL_WIN) { ; Special deal to hide away tool-type windows (hidden from taskbar)
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
	method := processWindow(winTitle, winClass, controlClass, winSettings, ACTION_SELECT_ALL)
	; DEBUG.popup("selectAll", "", "Select method", method, "Window settings", winSettings, "Class", winClass, "Title", winTitle)

	; Do it!
	if(method = METHOD_DEFAULT) { ; Generic case.
		Send, ^a
		
	} else if(method = SELECT_ALL_HOME_END) { ; For older places that don't allow it properly.
		Send, ^{Home}
		Send, ^+{End}
		
	} else {
		doWindowAction(method, winSettings, winTitle, winClass, controlClass)
	}
}

; Delete a word, generally via use of the Ctrl+Backspace hotkey.
deleteWord(winTitle = "", winClass = "", controlClass = "", winSettings = "") {
	; Gather any needed info we're not given.
	method := processWindow(winTitle, winClass, controlClass, winSettings, ACTION_DELETE_WORD)
	; DEBUG.popup("selectAll", "", "Delete method", method, "Window settings", winSettings, "Class", winClass, "Title", winTitle)

	; Do it!
	if(method = METHOD_DEFAULT) { ; Generic case.
		Send, ^{Backspace}
		
	} else if(method = DELETE_CTRL_SHIFT) { ; For older places that don't allow it properly.
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
	method := ACTION_NONE ; Start with the assumption that we shouldn't do anything after this - the specific cases will say otherwise if needed.
	
	if(action = ACTION_ESC) {
		; Guru Quick Dial Popup
		if(winClass = "WindowsForms10.Window.8.app.0.1517e87") {
			ControlFocus, WindowsForms10.BUTTON.app.0.1517e871, A ; Hang up button
			Send, {Space}
			method := ACTION_NONE
		}
		
	} else if(action = ACTION_MIN) {
		; Windows explorer
		if(winClass = BorgConfig.getProgram("Explorer", "CLASS")) {
			if(BorgConfig.isMachine(EPIC_DESKTOP)) { ; QTTabBar's min to tray
				Send, !q
				method := ACTION_NONE
			} else {
				method := METHOD_DEFAULT
			}
		}
	}
	
	; DEBUG.popup("window.doWindowActionSpecial", "Finished", "Action", action, "Method", method)
	return method
}


; Puts together a string that can be used with the likes of WinActivate, etc.
buildWindowTitleString(winTitle = "", winClass = "", winID = "", processID = "", exeName = "", groupName = "") {
	if(winTitle)
		outStr .= winTitle
	
	if(winClass)
		outStr .= " ahk_class " winClass
	
	if(winID)
		outStr .= " ahk_id " winID
	
	if(processID)
		outStr .= " ahk_pid " processID
	
	if(exeName)
		outStr .= " ahk_exe " exeName
	
	if(groupName)
		outStr .= " ahk_group " groupName
	
	return outStr
}

; Centers a window on the screen. "A" will use the active window, and passing nothing will use the last found window.
centerWindow(title = "") {
	if(!title)
		WinGetTitle, title
	else if(title = "A")
		WinGetTitle, title, A
	
	WinGetPos, , , Width, Height, %title%
	WinMove, %title%, , (A_ScreenWidth / 2) - (Width / 2), (A_ScreenHeight / 2) - (Height / 2)
}

activateLastWindow() {
	WinActivate, % "ahk_id " getPreviousWindowID()
}

getPreviousWindowID() {
	; Gather a list of running programs to loop over.
	WinGet, windowList, List
	WinGetTitle, oldTitle, A
	WinGetClass, oldClass, A
	
	; Loop until we have the previous window.
	Loop, %windowList%
	{
		; Gather information on the window.
		currID := windowList%A_Index%
		WinGetTitle, currTitle, ahk_id %currID%
		WinGet, currStyle, Style, ahk_id %currID%
		WinGet, currExStyle, ExStyle, ahk_id %currID%
		WinGetClass, currClass, ahk_id %currID%
		currParent := decimalToHex(DllCall("GetParent", "uint", currID))
		WinGet, currParentStyle, Style, ahk_id %currParent%
		; DEBUG.popup(currID, "Current ID", currStyle, "Current style", currExStyle, "Current extended style", currParentStyle, "Current parent style", currParent, "Current parent")
		
		; Skip unimportant windows.
		if((currStyle & WS_DISABLED) || !(currTitle))
			Continue
		
		; Skip tool-type windows.
		if(currExStyle & WS_EX_TOOLWINDOW)
			Continue
		
		; Skip pspad child windows.
		if (currExStyle & WS_EX_CONTROLPARENT) 
		&& (currClass != "#32770") 
		&& !(currStyle & WS_POPUP) 
		&& !(currExStyle & WS_EX_APPWINDOW)
		{
			Continue
		}
		
		; Skip notepad find windows.
		if(currParent && (currStyle & WS_POPUP) && ((currParentStyle & WS_DISABLED) = 0))
			Continue
		
		; Skip other random windows.
		if (currClass = "#32770")
		|| (currClass = "AU3Reveal")
		|| (currClass = "Progman")
		|| (currClass = "AutoHotkey")
		|| (currClass = "AutoHotkeyGUI")
		{
			Continue
		}
		
		; Don't get yourself, either.
		if(oldClass = currClass || oldTitle = currTitle)
			Continue

		break
	}
	
	return, currID
}

; Jacked from http://www.howtogeek.com/howto/28663/create-a-hotkey-to-resize-windows-to-a-specific-size-with-autohotkey/
resizeWindow(width = 0, height = 0) {
	WinGetPos, X, Y, W, H, A
	
	if(width = 0)
		width := W
	
	if(height = 0)
		height := H
	
	WinMove, A, , %X%, %Y%, %width%, %height%
}

getWindowTitle(winID = "A", winText = "", excludeTitle = "", excludeText = "") {
	WinGetTitle, title, %winID%, %winText%, %excludeTitle%, %excludeText%
	return title
}

getMonitorInfo() {
	monitorList := []
	
	SysGet, m, MonitorCount
	Loop, %m%
	{
		; Dimensions of this monitor go in Moni*
		SysGet, Moni, Monitor, %A_Index%
		
		mon := []
		mon["LEFT"]   := MoniLeft
		mon["RIGHT"]  := MoniRight
		mon["TOP"]    := MoniTop
		mon["BOTTOM"] := MoniBottom
		
		; DEBUG.popup("Monitor " A_Index, mon)
		
		monitorList.Push(mon)
	}
	
	; DEBUG.popup("Monitor List", monitorList)
	
	return monitorList
}

moveWindowToMonitor(winID, destMonitor, monitorList = "") {
	; If monitorList isn't given, make our own.
	if(!IsObject(monitorList))
		monitorList := getMonitorInfo()
	
	currMonitor := getWindowMonitor(winID, monitorList)
	if(currMonitor = -1) ; Couldn't find what monitor the window is on.
		return
	
	; DEBUG.popup("WindowMonitorFixer", "Found matching window", "ID", winID, "Title", getWindowTitle(winID), "Current monitor", currMonitor, "Destination monitor", destMonitor)
	
	; Window is already on the correct monitor, or we couldn't figure out what monitor this window was on.
	if( (currMonitor = destMonitor) || !currMonitor)
		return
	
	; DEBUG.popup("WindowMonitorFixer", "Moving window", "ID", winID, "Title", getWindowTitle(winID), "Current monitor", currMonitor, "Destination monitor", destMonitor)
	
	; Move the window to the correct monitor.
	
	; If the window is maximized, restore it.
	WinGet, minMaxState, MinMax, %winID%
	if(minMaxState = 1)
		WinRestore, %winID%
	
	; Calculate the new position for the window.
	WinGetPos, winX, winY, , , %winID%
	oldMon := monitorList[currMonitor]
	newMon := monitorList[destMonitor]
	newX := winX - oldMon["LEFT"] + newMon["LEFT"]
	newY := winY - oldMon["TOP"]  + newMon["TOP"]
	
	; DEBUG.popup("Moving window", getWindowTitle(winID), "Curr X", winX, "Curr Y", winY, "New X", newX, "New Y", newY, "Old mon (" currMonitor ")", oldMon, "New mon (" destMonitor ")", newMon)
	
	; Move it there.
	WinMove, %winID%, , newX, newY
	
	; If the window was maximized before, re-maximize it.
	if(minMaxState = 1)
		WinMaximize, %winID%
}

; Get the index of the monitor containing the specified x and y co-ordinates.
; Adapted from http://www.autohotkey.com/board/topic/69464-how-to-determine-a-window-is-in-which-monitor/
getWindowMonitor(winID, monitorList = "") {
	; If monitorList isn't given, make our own...with blackjack and hookers.
	if(!IsObject(monitorList))
		monitorList := getMonitorInfo()
	
	; DEBUG.popup("Monitor list", monitorList)
	
	; Get the X/Y for the given window.
	WinGetPos, winX, winY, , , %winID%
	
	; Fudge the X value a little if needed.
	winX += BorgConfig.getSetting("WINDOW_EDGE_OFFSET")
	
	WinGet, minMaxState, MinMax, %winID%
	if(minMaxState = 1) ; Window is maximized
		winX += BorgConfig.getSetting("MAX_EXTRA_WINDOW_EDGE_OFFSET")
	
	; Iterate over all monitors until we find a match.
	For i,mon in monitorList {
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
