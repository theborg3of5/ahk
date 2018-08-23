
	
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
	
	activateWindow(titleString := "A") {
		this.windowAction(WIN_ACTION_ACTIVATE, "", titleString)
	}
	activateWindowByName(name) {
		this.windowAction(WIN_ACTION_ACTIVATE, name)
	}
	
	closeWindow(titleString := "A") {
		this.windowAction(WIN_ACTION_CLOSE, "", titleString)
	}
	closeWindowByName(name) {
		this.windowAction(WIN_ACTION_CLOSE, name)
	}
	
	deleteWord(titleString := "A") {
		this.windowAction(WIN_ACTION_DELETE_WORD, "", titleString)
	}
	deleteWordByName(name) {
		this.windowAction(WIN_ACTION_DELETE_WORD, name)
	}
	
	escAction(titleString := "A") {
		this.windowAction(WIN_ACTION_ESC, "", titleString)
	}
	escActionByName(name) {
		this.windowAction(WIN_ACTION_ESC, name)
	}
	
	minimizeWindow(titleString := "A") {
		this.windowAction(WIN_ACTION_MIN, "", titleString)
	}
	minimizeWindowByName(name) {
		this.windowAction(WIN_ACTION_MIN, name)
	}
	
	selectAll(titleString := "A") {
		this.windowAction(WIN_ACTION_SELECT_ALL, "", titleString)
	}
	selectAllByName(name) {
		this.windowAction(WIN_ACTION_SELECT_ALL, name)
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
	
	windowAction(action, name := "", titleString := "") {
		if(!action)
			return
		if(!titleString && !name)
			return
		
		if(!name)
			name := MainConfig.findWindowName(titleString)
		if(!titleString)
			titleString := MainConfig.getWindowTitleString(name)
		
		this.doWindowAction(action, titleString, this.actions[name])
	}
	
	doWindowAction(action, titleString, windowActionSettings) {
		if(!action || !titleString)
			return
		
		; How we want to perform the action
		method := windowActionSettings[action]
		if(method = WIN_ACTION_OTHER) {
			this.doSpecialWindowMethod(action, titleString, windowActionSettings)
			return
		}
		if(method = "")
			method := WIN_METHOD_DEFAULT
		
		; Do that action.
		if(action = WIN_ACTION_NONE)             ; Do nothing
			return
		else if(action = WIN_ACTION_ACTIVATE)    ; Activate the given window
			this.doActivateWindow(method, titleString, windowActionSettings)
		else if(action = WIN_ACTION_CLOSE)       ; Close the given window
			this.doCloseWindow(method, titleString, windowActionSettings)
		else if(action = WIN_ACTION_DELETE_WORD) ; Backspace one word
			this.doDeleteWord(method, titleString, windowActionSettings)
		else if(action = WIN_ACTION_ESC)         ; React to the escape key (generally to minimize or close the window)
			this.doEscAction(method, titleString, windowActionSettings)
		else if(action = WIN_ACTION_MIN)         ; Minimize the given window
			this.doMinimizeWindow(method, titleString, windowActionSettings)
		else if(action = WIN_ACTION_SELECT_ALL)  ; Select all
			this.doSelectAll(method, titleString, windowActionSettings)
		else
			DEBUG.popup("WindowActions.doWindowAction","Error", "Action not found",action)
	}
	
	doActivateWindow(method, titleString, windowActionSettings) {
		if(method = WIN_METHOD_DEFAULT) {
			WinShow,     %titleString%
			WinActivate, %titleString%
			
		} else {
			this.doWindowAction(method, titleString, windowActionSettings)
		}
	}
	doCloseWindow(method, titleString, windowActionSettings) {
		if(method = WIN_METHOD_DEFAULT)
			WinClose, %titleString%
			
		else
			this.doWindowAction(method, titleString, windowActionSettings)
	}
	doDeleteWord(method, titleString, windowActionSettings) {
		if(method = WIN_METHOD_DEFAULT) {
			Send, ^{Backspace}
			
		} else if(method = WIN_DELETE_CTRL_SHIFT) { ; For older places that don't allow it properly.
			Send, ^+{Left}
			Send, {Backspace}
			
		} else {
			this.doWindowAction(method, titleString, windowActionSettings)
		}
	}
	doEscAction(method, titleString, windowActionSettings) {
		if(method = WIN_METHOD_DEFAULT) ; Default is to do nothing.
			return
		else
			this.doWindowAction(method, titleString, windowActionSettings)
	}
	doMinimizeWindow(method, titleString, windowActionSettings) {
		if(method = WIN_METHOD_DEFAULT) {
			WinMinimize, %titleString%
		
		} else if(method = WIN_MIN_POST_MESSAGE) {
			PostMessage, 0x112, 0xF020 , , , %titleString%
		
		} else {
			this.doWindowAction(method, titleString, windowActionSettings)
		}
	}
	doSelectAll(method, titleString, windowActionSettings) {
		if(method = WIN_METHOD_DEFAULT) {
			Send, ^a
		
		} else if(method = WIN_SELECT_ALL_HOME_END) { ; For older places that don't allow it properly.
			Send, ^{Home}
			Send, ^+{End}
		
		} else {
			this.doWindowAction(method, titleString, windowActionSettings)
		}
	}
	
	doSpecialWindowMethod(action, titleString, windowActionSettings) {
		; ; DEBUG.popup("windowMethodSpecial","", "Settings",winSettings, "Action",action)
		
		; if(!action)
			; return ""
		
		; method := WIN_ACTION_NONE ; Start with the assumption that we shouldn't do anything after this - the specific cases will say otherwise if needed.
		
		; ; Windows explorer
		; if(winSettings["NAME"] = "Explorer")
			; if(action = WIN_ACTION_MIN)
				; Send, !q ; QTTabBar's min to tray
		
		; ; Spotify
		; if(winSettings["NAME"] = "Spotify") {
			; if(action = WIN_ACTION_CLOSE) {
				; ; Spotify has a whole bunch of windows that are difficult to tell apart from 
				; ; the real thing, so make sure we're closing the right one.
				
				; ; Title is "Spotify" if not playing anything, and has a hyphen between the title and artist if it is playing something.
				; spotifyTitleBase := " ahk_exe Spotify.exe"
				; titleAry := []
				; titleAry.push("Spotify" spotifyTitleBase)
				; titleAry.push("-" spotifyTitleBase)
				
				; winId := isWindowInState("exists", titleAry, "", TITLE_MATCH_MODE_Contain, "", "On")
				; WinClose, ahk_id %winId%
			; }
		; }
		
		; ; DEBUG.popup("window.windowMethodSpecial","Finished", "Action",action, "Method",method, "Settings",winSettings)
		; return method
	}
}