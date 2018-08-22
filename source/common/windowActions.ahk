
	
; global WIN_ACTION_NONE        := "NONE"
; global WIN_ACTION_OTHER       := "OTHER"
; global WIN_ACTION_ACTIVATE    := "ACTIVATE"
; global WIN_ACTION_CLOSE       := "CLOSE"
; global WIN_ACTION_ESC         := "ESC"
; global WIN_ACTION_MIN         := "MIN"
; global WIN_ACTION_SELECT_ALL  := "SELECT_ALL"
; global WIN_ACTION_DELETE_WORD := "DELETE_WORD"

; global WIN_METHOD_DEFAULT := "DEFAULT"

; global WIN_MIN_POST_MESSAGE  := "POST_MESSAGE"

; global WIN_SELECT_ALL_HOME_END := "HOME_END"

; global WIN_DELETE_CTRL_SHIFT := "CTRL_SHIFT"
	
class WindowActions {
	
	; ==============================
	; == Public ====================
	; ==============================
	init(windowActionsFile) {
		windowActionsPath := findConfigFilePath(windowActionsFile)
		this.actions := this.loadActions(windowActionsPath)
	}
	
	;Want to replace WinActivate, % MainConfig.getWindowTitleString("Remote Desktop")
	;With            WindowActions.activateWindowWithName("Remote Desktop")
	activateWindowWithName(name) {
		if(name = "")
			return
		
		this.doActivateWindow(this.actions[name])
	}
	activateWindow(titleString := "A") {
		name := MainConfig.findWindowName(titleString)
		if(name = "")
			return
		
		this.doActivateWindow(this.actions[name])
	}
	
	
	doActivateWindow(actionSettings) {
		method := actionSettings[WIN_ACTION_ACTIVATE]
		; GDB TODO: figure out how to structure OTHER (WIN_ACTION_OTHER) stuff - one function or within each do* function?
		
		; if(method = WIN_METHOD_DEFAULT) {
			; WinShow,     %titleString%
			; WinActivate, %titleString%
		; } else {
			; doWindowAction(method, titleString, winSettings)
		; }
	}
	
	
	; activateWindow(titleString := "A", winSettings := "") {
		; method := processWindow(titleString, WIN_ACTION_ACTIVATE, winSettings)
		; ; DEBUG.popup("activateWindow","", "Title string",titleString, "Window settings",winSettings, "Method",method)
		
		; if(method = WIN_METHOD_DEFAULT) {
			; WinShow,     %titleString%
			; WinActivate, %titleString%
		; } else {
			; doWindowAction(method, titleString, winSettings)
		; }
	; }
	closeWindow(titleString := "A", winSettings := "") {
		method := processWindow(titleString, WIN_ACTION_CLOSE, winSettings)
		; DEBUG.popup("closeWindow","", "Title string",titleString, "Window settings",winSettings, "Method",method)
		
		if(method = WIN_METHOD_DEFAULT)
			WinClose, %titleString%
		else
			doWindowAction(method, titleString, winSettings)
	}
	; Delete a word, generally via use of the Ctrl+Backspace hotkey.
	deleteWord(titleString := "A", winSettings := "") {
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
	doEscAction(titleString := "A", winSettings := "") {
		method := processWindow(titleString, WIN_ACTION_ESC, winSettings)
		; DEBUG.popup("doEscAction","", "Title string",titleString, "Window settings",winSettings, "Method",method)
		
		if(method = WIN_METHOD_DEFAULT) ; Default is to do nothing.
			return
		else
			doWindowAction(method, titleString, winSettings)
	}
	minimizeWindow(titleString := "A", winSettings := "") {
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
	selectAll(titleString := "A", winSettings := "") {
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
	
	
	
	
	; ==============================
	; == Private ===================
	; ==============================
	static actions := []
	
	
	
	
	loadActions(filePath) {
		tl := new TableList(filePath)
		actionsTable := tl.getTable()
		
		; Index actions by window name
		actionsAry := []
		For i,row in actionsTable
			actionsAry[row["NAME"]] := row
		
		return actionsAry
	}
	
	
	
	
	
	
	getWindowSettingsAry(titleString := "A") {
		winExe   := WinGet("ProcessName", titleString)
		winClass := WinGetClass(titleString)
		winTitle := WinGetTitle(titleString)
		winText  := WinGetText(titleString)
		return MainConfig.getWindowLegacy("", winExe, winClass, winTitle, winText)
	}

	doWindowAction(action, titleString := "A", winSettings := "") {
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

	processWindow(ByRef titleString := "A", action := "", ByRef winSettings := "") {
		if(!titleString)
			return ""
		
		; Identify the window with regards to our settings.
		if(!IsObject(winSettings))
			winSettings := getWindowSettingsAry(titleString)
		; DEBUG.popup("window.processWindow", "Got winSettings", "Window Settings", winSettings)
		
		; ; If there's some text that has to be in the window, turn the titleString 
		; ; into one with a unique window ID, so that's taken into account.
		; ; Leave active window (A) alone though, since you can't use window text 
		; ; with that and it's already a single target by definition.
		; if(winSettings["TEXT"] && titleString != "A") {
			; winExe   := winSettings["EXE"]
			; winClass := winSettings["CLASS"]
			; winTitle := winSettings["TITLE"]
			; winText  := winSettings["TEXT"]
			
			; titleString := "ahk_id " WinExist(buildWindowTitleString(winExe, winClass, winTitle), winText)
		; }
		
		; Figure out the method (how we're going to perform the action).
		method := winSettings[action]
		if(method = WIN_ACTION_OTHER) ; Special handling - WIN_ACTION_OTHER goes to a separate function first.
			method := windowMethodSpecial(winSettings, action)
		if(!method) ; Return default if nothing found.
			method := WIN_METHOD_DEFAULT
		
		return method
	}
	
	
	
	
	; For all special cases for just a single case, so not worth creating a new constant, etc for.
	; The return value should be what we should do from here - so if we end up deciding that a 
	; standard method works, just return that constant. If it's not standard, just do it and then 
	; return WIN_ACTION_NONE.
	windowMethodSpecial(winSettings := "", action := "") {
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
	
}