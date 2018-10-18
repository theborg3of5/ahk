; Functions related to setting up a script.

; Sets a global that's read by _commonHotkeys.ahk to decide what kind of 
; common hotkeys (pause, close, reload, etc.) the script should get.
; type - the type of hotkeys, as described by a HOTKEY_TYPE_* constant (located in _constants.ahk)

;---------
; DESCRIPTION:    Defines which kind of script this is, in terms of which common hotkeys it should
;                 inherit.
; PARAMETERS:
;  type (I,REQ) - A value from one of the HOTKEY_TYPE_* constants (found in _constants.ahk)
;                 which describes the sort of script.
; SIDE EFFECTS:   Sets the scriptHotkeyType global, which is used to determine which common hotkeys
;                 should be active in _commonHotkeys.ahk.
;---------
setCommonHotkeysType(type) {
	global scriptHotkeyType
	scriptHotkeyType := type
}

;---------
; DESCRIPTION:    Set a normal icon to use for your script, and a suspended icon to use when the
;                 script is suspended (using the common !#x hotkey).
; PARAMETERS:
;  normalIcon    (I,REQ) - The full path to the "normal" icon - this will be used when the script
;                          is not suspended.
;  suspendedIcon (I,REQ) - The full path to the suspended icon - this will be used when the script
;                          is suspended.
;  tooltipText   (I,OPT) - Text to show when the user hovers over the tray icon.
;---------
setUpTrayIcons(normalIcon, suspendedIcon, tooltipText = "") {
	states                     := []
	states["A_IsSuspended", 0] := normalIcon
	states["A_IsSuspended", 1] := suspendedIcon
	setUpTrayIconStates(states)
	
	if(tooltipText)
		Menu, Tray, Tip, % tooltipText
}

;---------
; DESCRIPTION:    Store off the array that will be used by evalStateIcon() to determine what icon
;                 to show for a script.
; PARAMETERS:
;  states (I,REQ) - A tree-like array that maps the states of different variables to the icons that
;                   we should use for the script. Format:
;                   	states["varName", varState] := iconPath
;                   See evalStateIcon() for a more in-depth explanation.
; SIDE EFFECTS:   Set the value of the global stateIcons array, configure the tray icon so that it
;                 won't change to the default suspended icon when the script is suspended.
;---------
setUpTrayIconStates(states) {
	global stateIcons
	stateIcons := states
	
	Menu, Tray, Icon, , , 1 ; 1 - Keep suspend from changing it to the AHK default.
	updateTrayIcon()
}

;---------
; DESCRIPTION:    Determine the icon that should be used for the script (based on the variables
;                 defined in the global stateIcons array) and have the script use it.
; SIDE EFFECTS:   Potentially update the script's tray icon.
;---------
updateTrayIcon() {
	global stateIcons
	; DEBUG.popup("_setup","updateTrayIcon", "Icon states array",stateIcons)
	
	newIcon := evalStateIcon(stateIcons)
	
	if(newIcon) {
		iconPath := A_WorkingDir "\" newIcon
		if(iconPath && FileExist(iconPath))
			Menu, Tray, Icon, % iconPath
	}
}

;---------
; DESCRIPTION:    Drill down into the given array and determine (based on the states of the
;                 variables named in that array) the matching icon.
; PARAMETERS:
;  stateIcons (I,REQ) - An array that dictates which icon we should use, based on the states of
;                       different variables. Format:
;                       	stateIcons["var1", 0]            := iconPath1
;                       	stateIcons["var1", 1, "var2", 0] := iconPath2
;                       	stateIcons["var1", 1, "var2", 1] := iconPath3
;                       	...
; RETURNS:        The icon (path) that matches the current state.
; NOTES:          An example:
;                 	Variables and desired icons to use:
;                 		suspended  - 0 or 1. If 1, show suspended.ico. Otherwise, check other states.
;                 		otherState - 0 or 1. If 1, show other.ico, otherwise show normal.ico.
;                 	Array that should be used:
;                 		stateIcons["suspended", 1]                  := "suspended.ico"
;                 		stateIcons["suspended", 0, "otherState", 1] := "other.ico"
;                 		stateIcons["suspended", 0, "otherState", 0] := "normal.ico"
;---------
evalStateIcon(stateIcons) {
	if(!isObject(stateIcons)) {
		; DEBUG.popup("tray","evalStateIcon", "Base case: quitting because no longer object", stateIcons)
		return stateIcons
	}
	
	; Doesn't really need to be a loop, but this lets us get the index (which is the variable name in question) and corresponding pieces easier.
	For varName,states in stateIcons {
		; DEBUG.popup("Var name", varName, "States", states, "Variable value", %varName%, "Corresponding value", states[%varName%])
		return evalStateIcon(states[%varName%])
	}
	
	; Shouldn't happen if the stateIcons array is comprehensive.
	return "" ; If we get to a state where there's no matching icon, just return "".
}
