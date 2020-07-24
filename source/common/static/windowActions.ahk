; Class to handle performing some window actions, supporting overrides for some windows/programs.

class WindowActions {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Initialize this class with window identifiers and actions.
	;---------
	Init() {
		this.actionOverrides := new TableList("windowActions.tl").getRowsByColumn("NAME", "MACHINE")
		; Debug.popupEarly("WindowActions.Init",, "this.actionOverrides",this.actionOverrides)
	}
	
	;---------
	; DESCRIPTION:    Activate and show a window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string identifying the window.
	;---------
	activateWindow(titleString := "A") {
		this.windowAction(this.Action_Activate, "", titleString)
	}
	;---------
	; DESCRIPTION:    Activate and show a window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window, as defined in windows.tl.
	;---------
	activateWindowByName(name) {
		this.windowAction(this.Action_Activate, name)
	}
	
	;---------
	; DESCRIPTION:    Close a window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string representing the window.
	;---------
	closeWindow(titleString := "A") {
		this.windowAction(this.Action_Close, "", titleString)
	}
	;---------
	; DESCRIPTION:    Close a window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window, as defined in windows.tl.
	;---------
	closeWindowByName(name) {
		this.windowAction(this.Action_Close, name)
	}
	
	;---------
	; DESCRIPTION:    Delete a single word before the cursor within a particular window, respecting any custom overrides
	;                 for the identified window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string representing the window.
	;---------
	deleteWord(titleString := "A") {
		this.windowAction(this.Action_DeleteWord, "", titleString)
	}
	;---------
	; DESCRIPTION:    Delete a single word before the cursor within a particular window, respecting any custom overrides
	;                 for the identified window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window, as defined in windows.tl.
	;---------
	deleteWordByName(name) {
		this.windowAction(this.Action_DeleteWord, name)
	}
	
	;---------
	; DESCRIPTION:    Respond to the escape key within a particular window, respecting any custom overrides for the
	;                 identified window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string representing the window.
	;---------
	escAction(titleString := "A") {
		this.windowAction(this.Action_EscapeKey, "", titleString)
	}
	;---------
	; DESCRIPTION:    Respond to the escape key within a particular window, respecting any custom overrides for the
	;                 identified window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window, as defined in windows.tl.
	;---------
	escActionByName(name) {
		this.windowAction(this.Action_EscapeKey, name)
	}
	
	;---------
	; DESCRIPTION:    Minimize a window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string representing the window.
	;---------
	minimizeWindow(titleString := "A") {
		this.windowAction(this.Action_Minimize, "", titleString)
	}
	;---------
	; DESCRIPTION:    Minimize a window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window, as defined in windows.tl.
	;---------
	minimizeWindowByName(name) {
		this.windowAction(this.Action_Minimize, name)
	}
	
	;---------
	; DESCRIPTION:    Select all within a particular window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string representing the window.
	;---------
	selectAll(titleString := "A") {
		this.windowAction(this.Action_SelectAll, "", titleString)
	}
	;---------
	; DESCRIPTION:    Select all within a particular window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window, as defined in windows.tl.
	;---------
	selectAllByName(name) {
		this.windowAction(WindowActions.Action_SelectAll, name)
	}
	
	;---------
	; DESCRIPTION:    Respond to the backtick key within a particular window. Generally used to send Escape when Escape is
	;                 being used for something else.
	; PARAMETERS:
	;  titleString (I,OPT) - A title string representing the window.
	;---------
	backtickAction(titleString := "A") {
		this.windowAction(this.Action_Backtick, "", titleString)
	}
	;---------
	; DESCRIPTION:    Respond to the backtick key within a particular window. Generally used to send Escape when Escape is
	;                 being used for something else.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window, as defined in windows.tl.
	;---------
	backtickActionByName(name) {
		this.windowAction(this.Action_Backtick, name)
	}
	
	
	; #PRIVATE#
	
	; Supported window actions
	static Action_None       := "NONE"        ; Nothing
	static Action_Activate   := "ACTIVATE"    ; Activate the window
	static Action_Backtick   := "BACKTICK"    ; Handle the backtick key being pressed
	static Action_Close      := "CLOSE"       ; Close the window
	static Action_DeleteWord := "DELETE_WORD" ; Delete the word to the left of the cursor
	static Action_EscapeKey  := "ESC"         ; Handle the escape key being pressed
	static Action_Minimize   := "MIN"         ; Minimize the window
	static Action_SelectAll  := "SELECT_ALL"  ; Select all of the current field
	
	; Supported action methods
	static Method_Default          := "DEFAULT"      ; Use the default way of performing the action
	static Method_Other            := "OTHER"        ; Something special, defined in .doSpecialWindowMethod
	static Method_Minimize_Message := "POST_MESSAGE" ; Minimize: send a windows message to do it
	static Method_SelectAll_Home   := "HOME_END"     ; Select all: send home/end (and holding shift in between)
	static Method_DeleteWord_Ctrl  := "CTRL_SHIFT"   ; Delete word: send Ctrl+Shift+Left to select it, then delete
	static Method_Esc              := "ESCAPE"       ; Send an escape keystroke
	
	actionOverrides := "" ; {windowName: {action: method}}
	
	;---------
	; DESCRIPTION:    Set up the needed information to perform a window action and execute it.
	; PARAMETERS:
	;  action      (I,REQ) - The action to perform, from WindowActions.Action_* constants.
	;  name        (I,OPT) - The name of the window, as identified in windows.tl. Either this or titleString is required.
	;  titleString (I,OPT) - A title string that identifies the window we want to perform the action on. Either this or name is
	;                        required.
	;---------
	windowAction(action, name := "", titleString := "") {
		if(!action)
			return
		if(!titleString && !name)
			return
		
		if(!name)
			name := Config.findWindowName(titleString)
		if(!titleString)
			titleString := Config.windowInfo[name].titleString
		
		; Debug.popup("WindowActions.windowAction","Finished prep", "action",action, "titleString",titleString, "this.actionOverrides[name]",this.actionOverrides[name])
		this.doWindowAction(action, titleString, this.actionOverrides[name])
	}
	
	;---------
	; DESCRIPTION:    Perform an action on the identified window, respecting any overrides.
	; PARAMETERS:
	;  action               (I,REQ) - The action to perform, from WindowActions.Action_* constants.
	;  titleString          (I,REQ) - A title string that identifies the window we want to perform the action on.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in question, from WindowActions.actionOverrides.
	;---------
	doWindowAction(action, titleString, windowActionSettings) {
		if(!action || !titleString)
			return
		
		; How we want to perform the action
		method := windowActionSettings[action]
		if(method = this.Method_Other) {
			this.doSpecialWindowMethod(action, titleString, windowActionSettings)
			return
		}
		if(method = "")
			method := this.Method_Default
		
		; Do that action.
		Switch action {
			Case this.Action_None:       return                                                           ; Do nothing
			Case this.Action_Activate:   this.doActivateWindow(method, titleString, windowActionSettings) ; Activate the given window
			Case this.Action_Backtick:   this.doBacktickAction(method, titleString, windowActionSettings) ; React to backtick
			Case this.Action_Close:      this.doCloseWindow(   method, titleString, windowActionSettings) ; Close the given window
			Case this.Action_DeleteWord: this.doDeleteWord(    method, titleString, windowActionSettings) ; Backspace one word
			Case this.Action_EscapeKey:  this.doEscAction(     method, titleString, windowActionSettings) ; React to the escape key (generally to minimize or close the window)
			Case this.Action_Minimize:   this.doMinimizeWindow(method, titleString, windowActionSettings) ; Minimize the given window
			Case this.Action_SelectAll:  this.doSelectAll(     method, titleString, windowActionSettings) ; Select all
			Default: Debug.popup("WindowActions.doWindowAction","Error", "Action not found",action)
		}
	}
	
	;---------
	; DESCRIPTION:    Activate the specified window.
	; PARAMETERS:
	;  method               (I,REQ) - How the action should be performed, from WindowActions.Method_* constants.
	;  titleString          (I,REQ) - Title string identifying the window to act upon.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in question, from WindowActions.actionOverrides.
	; NOTES:          If we don't recognize the specific method, we'll call back into doWindowAction() to see if it's
	;                 another action (ESC > CLOSE, etc.).
	;---------
	doActivateWindow(method, titleString, windowActionSettings) {
		Switch method {
			Case this.Method_Default:
				WinShow,     %titleString%
				WinActivate, %titleString%
			Default:
				this.doWindowAction(method, titleString, windowActionSettings)
		}
	}
	;---------
	; DESCRIPTION:    Respond to the backtick key in the specified window.
	; PARAMETERS:
	;  method               (I,REQ) - How the action should be performed, from WindowActions.Method_* constants.
	;  titleString          (I,REQ) - Title string identifying the window to act upon.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in question, from WindowActions.actionOverrides.
	; NOTES:          If we don't recognize the specific method, we'll call back into doWindowAction() to see if it's
	;                 another action (ESC > CLOSE, etc.).
	;---------
	doBacktickAction(method, titleString, windowActionSettings) {
		Switch method {
			Case this.Method_Default: Send, `` ; Default is to just let the keystroke through (escaped).
			Case this.Method_Esc:     Send, {Esc} ; Send escape - backtick is usually used for a replacement for escape in these cases.
			Default:                  this.doWindowAction(method, titleString, windowActionSettings)
		}
	}
	;---------
	; DESCRIPTION:    Close the specified window.
	; PARAMETERS:
	;  method               (I,REQ) - How the action should be performed, from WindowActions.Method_* constants.
	;  titleString          (I,REQ) - Title string identifying the window to act upon.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in question, from WindowActions.actionOverrides.
	; NOTES:          If we don't recognize the specific method, we'll call back into doWindowAction() to see if it's
	;                 another action (ESC > CLOSE, etc.).
	;---------
	doCloseWindow(method, titleString, windowActionSettings) {
		Switch method {
			Case this.Method_Default: WinClose, %titleString%
			Default:                  this.doWindowAction(method, titleString, windowActionSettings)
		}
	}
	;---------
	; DESCRIPTION:    Delete a word in the specified window.
	; PARAMETERS:
	;  method               (I,REQ) - How the action should be performed, from WindowActions.Method_* constants.
	;  titleString          (I,REQ) - Title string identifying the window to act upon.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in question, from WindowActions.actionOverrides.
	; NOTES:          If we don't recognize the specific method, we'll call back into doWindowAction() to see if it's
	;                 another action (ESC > CLOSE, etc.).
	;---------
	doDeleteWord(method, titleString, windowActionSettings) {
		Switch method {
		Case this.Method_Default:
			Send, ^{Backspace}
		Case this.Method_DeleteWord_Ctrl: ; For older places that don't allow it properly.
			Send, ^+{Left}
			Send, {Backspace}
		Default:
			this.doWindowAction(method, titleString, windowActionSettings)
		}
	}
	;---------
	; DESCRIPTION:    Respond to the escape key in the specified window.
	; PARAMETERS:
	;  method               (I,REQ) - How the action should be performed, from WindowActions.Method_* constants.
	;  titleString          (I,REQ) - Title string identifying the window to act upon.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in question, from WindowActions.actionOverrides.
	; NOTES:          If we don't recognize the specific method, we'll call back into doWindowAction() to see if it's
	;                 another action (ESC > CLOSE, etc.).
	;---------
	doEscAction(method, titleString, windowActionSettings) {
		Switch method {
			Case this.Method_Default: return ; Default is to do nothing.
			Default:                  this.doWindowAction(method, titleString, windowActionSettings)
		}
	}
	;---------
	; DESCRIPTION:    Minimize the specified window.
	; PARAMETERS:
	;  method               (I,REQ) - How the action should be performed, from WindowActions.Method_* constants.
	;  titleString          (I,REQ) - Title string identifying the window to act upon.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in question, from WindowActions.actionOverrides.
	; NOTES:          If we don't recognize the specific method, we'll call back into doWindowAction() to see if it's
	;                 another action (ESC > CLOSE, etc.).
	;---------
	doMinimizeWindow(method, titleString, windowActionSettings) {
		Switch method {
			Case this.Method_Default:          WinMinimize, %titleString%
			Case this.Method_Minimize_Message: PostMessage, 0x112, 0xF020 , , , %titleString%
			Default:                           this.doWindowAction(method, titleString, windowActionSettings)
		}
	}
	;---------
	; DESCRIPTION:    Select all text in the specified window.
	; PARAMETERS:
	;  method               (I,REQ) - How the action should be performed, from WindowActions.Method_* constants.
	;  titleString          (I,REQ) - Title string identifying the window to act upon.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in question, from WindowActions.actionOverrides.
	; NOTES:          If we don't recognize the specific method, we'll call back into doWindowAction() to see if it's
	;                 another action (ESC > CLOSE, etc.).
	;---------
	doSelectAll(method, titleString, windowActionSettings) {
		Switch method {
			Case this.Method_Default:
				Send, ^a
			Case this.Method_SelectAll_Home: ; For older places that don't allow it properly.
				Send, ^{Home}
				Send, ^+{End}
			Default:
				this.doWindowAction(method, titleString, windowActionSettings)
		}
	}
	
	;---------
	; DESCRIPTION:    Catch-all function for performing actions on windows, where those action overrides are unique to the
	;                 particular program (and therefore not worth standardizing into a method constant).
	; PARAMETERS:
	;  action               (I,REQ) - The action to try and perform.
	;  titleString          (I,REQ) - Title string identifying the window to act upon.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in question, from WindowActions.actionOverrides.
	;---------
	doSpecialWindowMethod(action, titleString, windowActionSettings) {
		if(!action)
			return ""
		
		Switch windowActionSettings["NAME"] {
			Case "Explorer":
				if(action = this.Action_Minimize)
					Send, !q ; QTTabBar's min to tray hotkey
			
			Case "Spotify":
				idString := "ahk_id " Spotify.getMainWindowId()
				Switch action {
					Case this.Action_Activate:
						WinActivate, % idString
					Case this.Action_Close:
						WinClose, % idString
				}
		}
	}
	; #END#
}
