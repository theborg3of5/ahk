; Class to handle performing some window actions, supporting overrides for some windows/programs.

; Window actions supported by the WindowActions class.
global WIN_ACTION_NONE        := "NONE"
global WIN_ACTION_OTHER       := "OTHER"
global WIN_ACTION_ACTIVATE    := "ACTIVATE"
global WIN_ACTION_CLOSE       := "CLOSE"
global WIN_ACTION_ESC         := "ESC"
global WIN_ACTION_MIN         := "MIN"
global WIN_ACTION_SELECT_ALL  := "SELECT_ALL"
global WIN_ACTION_DELETE_WORD := "DELETE_WORD"

; Specific methods for performing the actions above.
global WIN_METHOD_DEFAULT         := "DEFAULT"
global WIN_METHOD_MIN_MESSAGE     := "POST_MESSAGE"
global WIN_METHOD_SELECT_ALL_HOME := "HOME_END"
global WIN_METHOD_DELETE_CTRL     := "CTRL_SHIFT"

class WindowActions {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	;---------
	; DESCRIPTION:    
	; PARAMETERS:
	;  windowActionsFile (I,REQ) - The filename of the .tl file to read in for window
	;                              actions.
	;---------
	init(windowActionsFile) {
		windowActionsPath := findConfigFilePath(windowActionsFile)
		this.actionOverrides := this.loadActions(windowActionsPath)
		; DEBUG.popupEarly("WindowActions.init","Finished", "windowActionsFile",windowActionsFile, "windowActionsPath",windowActionsPath, "this.actionOverrides",this.actionOverrides)
	}
	
	;---------
	; DESCRIPTION:    Activate and show a window, respecting any custom overrides for the identified
	;                 window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string identifying the window.
	;---------
	activateWindow(titleString := "A") {
		this.windowAction(WIN_ACTION_ACTIVATE, "", titleString)
	}
	;---------
	; DESCRIPTION:    Activate and show a window, respecting any custom overrides for the identified
	;                 window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window to activate, as defined in windows.tl.
	;---------
	activateWindowByName(name) {
		this.windowAction(WIN_ACTION_ACTIVATE, name)
	}
	
	;---------
	; DESCRIPTION:    Close a window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string representing the window.
	;---------
	closeWindow(titleString := "A") {
		this.windowAction(WIN_ACTION_CLOSE, "", titleString)
	}
	;---------
	; DESCRIPTION:    Close a window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window to activate, as defined in windows.tl.
	;---------
	closeWindowByName(name) {
		this.windowAction(WIN_ACTION_CLOSE, name)
	}
	
	;---------
	; DESCRIPTION:    Delete a single word before the cursor within a particular window, respecting
	;                 any custom overrides for the identified window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string representing the window.
	;---------
	deleteWord(titleString := "A") {
		this.windowAction(WIN_ACTION_DELETE_WORD, "", titleString)
	}
	;---------
	; DESCRIPTION:    Delete a single word before the cursor within a particular window, respecting
	;                 any custom overrides for the identified window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window to activate, as defined in windows.tl.
	;---------
	deleteWordByName(name) {
		this.windowAction(WIN_ACTION_DELETE_WORD, name)
	}
	
	;---------
	; DESCRIPTION:    Respond to the escape key within a particular window, respecting any custom
	;                 overrides for the identified window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string representing the window.
	;---------
	escAction(titleString := "A") {
		this.windowAction(WIN_ACTION_ESC, "", titleString)
	}
	;---------
	; DESCRIPTION:    Respond to the escape key within a particular window, respecting any custom
	;                 overrides for the identified window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window to activate, as defined in windows.tl.
	;---------
	escActionByName(name) {
		this.windowAction(WIN_ACTION_ESC, name)
	}
	
	;---------
	; DESCRIPTION:    Minimize a window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string representing the window.
	;---------
	minimizeWindow(titleString := "A") {
		this.windowAction(WIN_ACTION_MIN, "", titleString)
	}
	;---------
	; DESCRIPTION:    Minimize a window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window to activate, as defined in windows.tl.
	;---------
	minimizeWindowByName(name) {
		this.windowAction(WIN_ACTION_MIN, name)
	}
	
	;---------
	; DESCRIPTION:    Select all within a particular window, respecting any custom overrides for the
	;                 identified window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string representing the window.
	;---------
	selectAll(titleString := "A") {
		this.windowAction(WIN_ACTION_SELECT_ALL, "", titleString)
	}
	;---------
	; DESCRIPTION:    Select all within a particular window, respecting any custom overrides for the
	;                 identified window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window to activate, as defined in windows.tl.
	;---------
	selectAllByName(name) {
		this.windowAction(WIN_ACTION_SELECT_ALL, name)
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	static actions := []
	
	;---------
	; DESCRIPTION:    Read in the windowActions TL file with window action overrides.
	; PARAMETERS:
	;  filePath (I,REQ) - The full filepath to the windowActions TL file.
	; RETURNS:        The parsed and name-indexed array of action overrides and info for different
	;                 windows.
	;---------
	loadActions(filePath) {
		tl := new TableList(filePath)
		actionsTable := tl.getTable()
		
		; Index actions by window name
		actionsAry := []
		For i,row in actionsTable
			actionsAry[row["NAME"]] := row
		
		return actionsAry
	}
	
	;---------
	; DESCRIPTION:    Set up the needed information to perform a window action and execute it.
	; PARAMETERS:
	;  action      (I,REQ) - The action to perform, from WIN_ACTION_* constants.
	;  name        (I,OPT) - The name of the window, as identified in windows.tl. Either this or
	;                        titleString is required.
	;  titleString (I,OPT) - A title string that identifies the window we want to perform the action
	;                        on. Either this or name is required.
	;---------
	windowAction(action, name := "", titleString := "") {
		if(!action)
			return
		if(!titleString && !name)
			return
		
		if(!name)
			name := MainConfig.findWindowName(titleString)
		if(!titleString)
			titleString := MainConfig.windowInfo[name].titleString
		
		; DEBUG.popup("WindowActions.windowAction","Finished prep", "action",action, "titleString",titleString, "this.actionOverrides[name]",this.actionOverrides[name])
		this.doWindowAction(action, titleString, this.actionOverrides[name])
	}
	
	;---------
	; DESCRIPTION:    Perform an action on the identified window, respecting any overrides.
	; PARAMETERS:
	;  action               (I,REQ) - The action to perform, from WIN_ACTION_* constants.
	;  titleString          (I,REQ) - A title string that identifies the window we want to perform
	;                                 the action on.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in
	;                                 question, from this.actionOverrides.
	;---------
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
	
	;---------
	; DESCRIPTION:    Activate the specified window.
	; PARAMETERS:
	;  method               (I,REQ) - How the action should be performed, from WIN_METHOD_*
	;                                 constants.
	;  titleString          (I,REQ) - Title string identifying the window to act upon.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in
	;                                 question, from this.actionOverrides.
	; NOTES:          If we don't recognize the specific method, we'll call back into
	;                 doWindowAction() to see if it's another action (ESC > CLOSE, etc.).
	;---------
	doActivateWindow(method, titleString, windowActionSettings) {
		if(method = WIN_METHOD_DEFAULT) {
			WinShow,     %titleString%
			WinActivate, %titleString%
			
		} else {
			this.doWindowAction(method, titleString, windowActionSettings)
		}
	}
	;---------
	; DESCRIPTION:    Close the specified window.
	; PARAMETERS:
	;  method               (I,REQ) - How the action should be performed, from WIN_METHOD_*
	;                                 constants.
	;  titleString          (I,REQ) - Title string identifying the window to act upon.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in
	;                                 question, from this.actionOverrides.
	; NOTES:          If we don't recognize the specific method, we'll call back into
	;                 doWindowAction() to see if it's another action (ESC > CLOSE, etc.).
	;---------
	doCloseWindow(method, titleString, windowActionSettings) {
		if(method = WIN_METHOD_DEFAULT)
			WinClose, %titleString%
			
		else
			this.doWindowAction(method, titleString, windowActionSettings)
	}
	;---------
	; DESCRIPTION:    Delete a word in the specified window.
	; PARAMETERS:
	;  method               (I,REQ) - How the action should be performed, from WIN_METHOD_*
	;                                 constants.
	;  titleString          (I,REQ) - Title string identifying the window to act upon.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in
	;                                 question, from this.actionOverrides.
	; NOTES:          If we don't recognize the specific method, we'll call back into
	;                 doWindowAction() to see if it's another action (ESC > CLOSE, etc.).
	;---------
	doDeleteWord(method, titleString, windowActionSettings) {
		if(method = WIN_METHOD_DEFAULT) {
			Send, ^{Backspace}
			
		} else if(method = WIN_METHOD_DELETE_CTRL) { ; For older places that don't allow it properly.
			Send, ^+{Left}
			Send, {Backspace}
			
		} else {
			this.doWindowAction(method, titleString, windowActionSettings)
		}
	}
	;---------
	; DESCRIPTION:    Respond to the escape key in the specified window.
	; PARAMETERS:
	;  method               (I,REQ) - How the action should be performed, from WIN_METHOD_*
	;                                 constants.
	;  titleString          (I,REQ) - Title string identifying the window to act upon.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in
	;                                 question, from this.actionOverrides.
	; NOTES:          If we don't recognize the specific method, we'll call back into
	;                 doWindowAction() to see if it's another action (ESC > CLOSE, etc.).
	;---------
	doEscAction(method, titleString, windowActionSettings) {
		if(method = WIN_METHOD_DEFAULT) ; Default is to do nothing.
			return
		else
			this.doWindowAction(method, titleString, windowActionSettings)
	}
	;---------
	; DESCRIPTION:    Minimize the specified window.
	; PARAMETERS:
	;  method               (I,REQ) - How the action should be performed, from WIN_METHOD_*
	;                                 constants.
	;  titleString          (I,REQ) - Title string identifying the window to act upon.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in
	;                                 question, from this.actionOverrides.
	; NOTES:          If we don't recognize the specific method, we'll call back into
	;                 doWindowAction() to see if it's another action (ESC > CLOSE, etc.).
	;---------
	doMinimizeWindow(method, titleString, windowActionSettings) {
		if(method = WIN_METHOD_DEFAULT) {
			WinMinimize, %titleString%
		
		} else if(method = WIN_METHOD_MIN_MESSAGE) {
			PostMessage, 0x112, 0xF020 , , , %titleString%
		
		} else {
			this.doWindowAction(method, titleString, windowActionSettings)
		}
	}
	;---------
	; DESCRIPTION:    Select all text in the specified window.
	; PARAMETERS:
	;  method               (I,REQ) - How the action should be performed, from WIN_METHOD_*
	;                                 constants.
	;  titleString          (I,REQ) - Title string identifying the window to act upon.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in
	;                                 question, from this.actionOverrides.
	; NOTES:          If we don't recognize the specific method, we'll call back into
	;                 doWindowAction() to see if it's another action (ESC > CLOSE, etc.).
	;---------
	doSelectAll(method, titleString, windowActionSettings) {
		if(method = WIN_METHOD_DEFAULT) {
			Send, ^a
		
		} else if(method = WIN_METHOD_SELECT_ALL_HOME) { ; For older places that don't allow it properly.
			Send, ^{Home}
			Send, ^+{End}
		
		} else {
			this.doWindowAction(method, titleString, windowActionSettings)
		}
	}
	
	;---------
	; DESCRIPTION:    Catch-all function for performing actions on windows, where those action
	;                 overrides are unique to the particular program (and therefore not worth
	;                 standardizing into a method constant).
	; PARAMETERS:
	;  action               (I,REQ) - The action to try and perform.
	;  titleString          (I,REQ) - Title string identifying the window to act upon.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in
	;                                 question, from this.actionOverrides.
	;---------
	doSpecialWindowMethod(action, titleString, windowActionSettings) {
		if(!action)
			return ""
		
		name := windowActionSettings["NAME"]
		
		; Windows explorer
		if(name = "Explorer") {
			if(action = WIN_ACTION_MIN)
				Send, !q ; QTTabBar's min to tray hotkey
		
		; Spotify
		} else if(name = "Spotify") {
			if(action = WIN_ACTION_CLOSE) {
				origMatchMode := setTitleMatchMode(TITLE_MATCH_MODE_Contain)
				
				; Spotify has a whole bunch of windows that are difficult to tell apart from 
				; the real thing, so make sure we're closing the right one.
				winId := WinExist(buildWindowTitleString("Spotify.exe", "", "Spotify")) ; Title is "Spotify" if playing nothing
				if(winId = "")
					winId := WinExist(buildWindowTitleString("Spotify.exe", "", "-")) ; Title has a hyphen between the title and artist if it is playing something
				
				if(winId != "")
					WinClose, ahk_id %winId%
				
				setTitleMatchMode(origMatchMode)
			}
		}
	}
}