; Class to handle performing some window actions, supporting overrides for some windows/programs.

class WindowActions {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Activate and show a window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string identifying the window.
	;---------
	static activateWindow(titleString := "A") {
		this.windowAction(this.Action_Activate, "", titleString)
	}
	;---------
	; DESCRIPTION:    Activate and show a window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window, as defined in windows.tl.
	;---------
	static activateWindowByName(name) {
		this.windowAction(this.Action_Activate, name)
	}
	
	;---------
	; DESCRIPTION:    Close a window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string representing the window.
	;---------
	static closeWindow(titleString := "A") {
		this.windowAction(this.Action_Close, "", titleString)
	}
	;---------
	; DESCRIPTION:    Close a window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window, as defined in windows.tl.
	;---------
	static closeWindowByName(name) {
		this.windowAction(this.Action_Close, name)
	}
	
	;---------
	; DESCRIPTION:    Delete a single word before the cursor within a particular window, respecting any custom overrides
	;                 for the identified window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string representing the window.
	;---------
	static deleteWord(titleString := "A") {
		this.windowAction(this.Action_DeleteWord, "", titleString)
	}
	;---------
	; DESCRIPTION:    Delete a single word before the cursor within a particular window, respecting any custom overrides
	;                 for the identified window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window, as defined in windows.tl.
	;---------
	static deleteWordByName(name) {
		this.windowAction(this.Action_DeleteWord, name)
	}
	
	;---------
	; DESCRIPTION:    Respond to the escape key within a particular window, respecting any custom overrides for the
	;                 identified window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string representing the window.
	;---------
	static escAction(titleString := "A") {
		this.windowAction(this.Action_EscapeKey, "", titleString)
	}
	;---------
	; DESCRIPTION:    Respond to the escape key within a particular window, respecting any custom overrides for the
	;                 identified window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window, as defined in windows.tl.
	;---------
	static escActionByName(name) {
		this.windowAction(this.Action_EscapeKey, name)
	}
	
	;---------
	; DESCRIPTION:    Minimize a window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string representing the window.
	;---------
	static minimizeWindow(titleString := "A") {
		this.windowAction(this.Action_Minimize, "", titleString)
	}
	;---------
	; DESCRIPTION:    Minimize a window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window, as defined in windows.tl.
	;---------
	static minimizeWindowByName(name) {
		this.windowAction(this.Action_Minimize, name)
	}
	
	;---------
	; DESCRIPTION:    Select all within a particular window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  titleString (I,REQ) - A title string representing the window.
	;---------
	static selectAll(titleString := "A") {
		this.windowAction(this.Action_SelectAll, "", titleString)
	}
	;---------
	; DESCRIPTION:    Select all within a particular window, respecting any custom overrides for the identified window.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window, as defined in windows.tl.
	;---------
	static selectAllByName(name) {
		this.windowAction(WindowActions.Action_SelectAll, name)
	}
	
	;---------
	; DESCRIPTION:    Respond to the backtick key within a particular window. Generally used to send Escape when Escape is
	;                 being used for something else.
	; PARAMETERS:
	;  titleString (I,OPT) - A title string representing the window.
	;---------
	static backtickAction(titleString := "A") {
		this.windowAction(this.Action_Backtick, "", titleString)
	}
	;---------
	; DESCRIPTION:    Respond to the backtick key within a particular window. Generally used to send Escape when Escape is
	;                 being used for something else.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window, as defined in windows.tl.
	;---------
	static backtickActionByName(name) {
		this.windowAction(this.Action_Backtick, name)
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	;region Supported window actions
	static Action_Activate   := "ACTIVATE"    ; Activate the window
	static Action_Backtick   := "BACKTICK"    ; Handle the backtick key being pressed
	static Action_Close      := "CLOSE"       ; Close the window
	static Action_DeleteWord := "DELETE_WORD" ; Delete the word to the left of the cursor
	static Action_EscapeKey  := "ESC"         ; Handle the escape key being pressed
	static Action_Minimize   := "MIN"         ; Minimize the window
	static Action_SelectAll  := "SELECT_ALL"  ; Select all of the current field
	;endregion Supported window actions
	
	;region Supported action methods
	static Method_Other             := "OTHER"        ; Special app-specific handling, defined in .performActionForOtherWindow
	static Method_Minimize_Message  := "POST_MESSAGE" ; Minimize: send a windows message to do it
	static Method_SelectAll_Home    := "HOME_END"     ; Select all using home/end keys
	static Method_DeleteWord_Select := "SELECT"       ; Delete a word by selecting it
	static Method_SendEsc           := "ESCAPE"       ; Send an escape keystroke
	static Method_Run               := "RUN"          ; Run the named program
	static Method_None              := "NONE"         ; Do nothing
	;endregion Supported action methods
	
	static _actionOverrides := "" ; {windowName: {action: method}}

	;---------
	; DESCRIPTION:    Get an array of overrides for how to do actions for a particular named window.
	; PARAMETERS:
	;  name (I,REQ) - Name of the window we're interested in
	; SIDE EFFECTS:   Initializes the static this._actionOverrides array the first time it's called.
	;---------
	static actionOverrides[name] {
		get {
			if !this._actionOverrides
				this._actionOverrides := TableList("windowActions.tl").getRowsByColumn("NAME", "MACHINE")

			return this._actionOverrides[name]
		}
	}
	
	;---------
	; DESCRIPTION:    Set up the needed information to perform a window action and execute it.
	; PARAMETERS:
	;  action      (I,REQ) - The action to perform, from WindowActions.Action_* constants.
	;  name        (I,OPT) - The name of the window, as identified in windows.tl. Either this or titleString is required.
	;  titleString (I,OPT) - A title string that identifies the window we want to perform the action on. Either this or name is
	;                        required.
	;---------
	static windowAction(action, name := "", titleString := "") {
		if !action
			return
		if !titleString && !name
			return

		if !name
			name := Config.findWindowName(titleString)

		if titleString
			titleString := WindowLib.getIdTitleString(titleString)
		else
			titleString := Config.windowInfo[name].idString

		if WindowLib.isNoMoveSizeWindow(titleString) {
			Toast.ShowError("WindowActions: cannot touch window", "Window should not be moved or resized")
			return
		}

		this.performAction(action, titleString, this.actionOverrides[name])
	}
	
	;---------
	; DESCRIPTION:    Perform an action on the identified window, respecting any overrides.
	; PARAMETERS:
	;  action               (I,REQ) - The action to perform, from WindowActions.Action_* constants.
	;  titleString          (I,REQ) - A title string that identifies the window we want to perform the action on.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in question, from WindowActions.actionOverrides.
	;---------
	static performAction(action, titleString, windowActionSettings) {
		if !action || !titleString
			return

		method := windowActionSettings[action]

		if method = "" {
			this.performDefaultMethod(action, titleString)
			return
		}
		
		if method = this.Method_Other {
			this.performActionForOtherWindow(action, titleString, windowActionSettings)
			return
		}
		
		if this.isAction(method) {
			this.performAction(method, titleString, windowActionSettings)
			return
		}
		
		; Perform the given method
		this.performSpecificMethod(method, titleString, windowActionSettings)
	}
	
	;---------
	; DESCRIPTION:    Check whether the given string matches one of our actions.
	; PARAMETERS:
	;  action (I,REQ) - Action string to check
	; RETURNS:        true/false - is it an action?
	;---------
	static isAction(action) {
		actions := []
		actions.push(this.Action_Activate)
		actions.push(this.Action_Backtick)
		actions.push(this.Action_Close)
		actions.push(this.Action_DeleteWord)
		actions.push(this.Action_EscapeKey)
		actions.push(this.Action_Minimize)
		actions.push(this.Action_SelectAll)
		
		return actions.contains(action)
	}
	
	;---------
	; DESCRIPTION:    Catch-all function for performing actions on windows, where those action overrides are unique to the
	;                 particular program (and therefore not worth standardizing into a method constant).
	; PARAMETERS:
	;  action               (I,REQ) - The action to try and perform.
	;  titleString          (I,REQ) - Title string identifying the window to act upon.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in question, from WindowActions.actionOverrides.
	;---------
	static performActionForOtherWindow(action, titleString, windowActionSettings) {
		if !action
			return ""

		Switch windowActionSettings["NAME"] {
			Case "Putty":
				if action = this.Action_Minimize {
					if Config.doesWindowExist("MTPutty")
						this.minimizeWindowByName("MTPutty")
					else
						WinMinimize(titleString)
				}
		}
	}
	
	;---------
	; DESCRIPTION:    Perform the given action using our default method for it.
	; PARAMETERS:
	;  action      (I,REQ) - Action to perform, from Action_* constants.
	;  titleString (I,REQ) - Title string identifying the window to act upon.
	;---------
	static performDefaultMethod(action, titleString) {
		Switch action {
			Case this.Action_Activate:
				WinShow(titleString)
				WinActivate(titleString)

			Case this.Action_Backtick:
				Send("``")

			Case this.Action_Close:
				WinClose(titleString)

			Case this.Action_DeleteWord:
				Send("^{Backspace}")

			Case this.Action_EscapeKey:
				return

			Case this.Action_Minimize:
				WinMinimize(titleString)

			Case this.Action_SelectAll:
				Send("^a")

			Default:
				Toast.ShowError("Could not perform method", "Unknown action: " action)
		}
	}
	
	;---------
	; DESCRIPTION:    Perform a specific, named method.
	; PARAMETERS:
	;  method               (I,REQ) - Method to perform, from the Method_* constants.
	;  titleString          (I,REQ) - Title string identifying the window to act upon.
	;  windowActionSettings (I,REQ) - Array of action override information for the window in question, from WindowActions.actionOverrides.
	;---------
	static performSpecificMethod(method, titleString, windowActionSettings) {
		Switch method {
			Case this.Method_Run:
				Config.runProgram(windowActionSettings["NAME"])

			Case this.Method_Minimize_Message:
				PostMessage(MicrosoftLib.Message_WindowMenu, MicrosoftLib.SystemCommand_Minimize, , , titleString)

			Case this.Method_SelectAll_Home:
				Send("^{Home}")
				Send("^+{End}")

			Case this.Method_DeleteWord_Select:
				Send("^+{Left}")
				Send("{Backspace}")

			Case this.Method_SendEsc:
				Send("{Esc}")

			Case this.Method_None:
				return

			Default:
				Toast.ShowError("Could not perform method", "Method unknown: " method)
		}
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
