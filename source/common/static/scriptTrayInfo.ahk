/* Class for keeping track of (and updating) tray-related information about a script, including the tray icon.
	
	Example usage:
;		ScriptTrayInfo.Init("AHK: Precise Mouse Movement", "mouseGreen.ico", "mouseRed.ico")
	
*/

class ScriptTrayInfo {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Create a new object representing the tray information for the script, including icons.
	; PARAMETERS:
	;  tooltipText   (I,REQ) - Text to show when the user hovers over the tray icon.
	;  normalIcon    (I,OPT) - The full path to the "normal" icon - this will be used when the script
	;                          is not suspended.
	;  suspendedIcon (I,OPT) - The full path to the suspended icon - this will be used when the script
	;                          is suspended using the common !#x hotkey (see CommonHotkeys).
	;---------
	static Init(tooltipText, normalIcon := "", suspendedIcon := "") {
		A_IconTip := tooltipText

		; Keep suspend from changing it to the AHK default, so we can use our custom suspendedIcon instead.
		if suspendedIcon
			TraySetIcon(, , true)

		; Build states map from given icons. Keys are getter functions that return current state.
		this.stateIcons := Map()
		this.stateIcons[() => A_IsSuspended] := Map(0, normalIcon, 1, suspendedIcon)

		this.updateTrayIcon()
	}

	;---------
	; DESCRIPTION:    Directly set the array used to determine which tray icon to use based on
	;                 different global variable states.
	; PARAMETERS:
	;  states (I,REQ) - A tree-like associative array that maps the states of different variables to
	;                   the icons that we should use for the script. Format:
	;                   	states["varName", varState] := iconPath
	;                   See getIconForCurrentState() for a more in-depth explanation.
	;---------
	static setStateIcons(states) {
		TraySetIcon(, , true) ; Assume that there will always be a path in here to a suspended icon we should use.

		this.stateIcons := states
		this.updateTrayIcon()
	}

	;---------
	; DESCRIPTION:    Determine the icon that should be used for the script (based on the variables
	;                 defined in the stateIcons array) and apply it.
	;---------
	static updateTrayIcon() {
		newIcon := this.getIconForCurrentState(this.stateIcons)
		; Debug.popup("ScriptTrayInfo.updateTrayIcon","Start", "this.stateIcons",this.stateIcons, "newIcon",newIcon)
		if !newIcon
			return

		iconPath := Config.path["AHK_ROOT"] "\icons\" newIcon
		if !FileExist(iconPath) ; Fallback to icons in same directory
			iconPath := A_WorkingDir "\" newIcon

		if !FileExist(iconPath)
			return

		TraySetIcon(iconPath)
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	static stateIcons := Map() ; Map of getter functions to sub-Maps - see .getIconForCurrentState() for explanation.

	;---------
	; DESCRIPTION:    Recursively drill down into the given map and determine (based on the current
	;                 state returned by getter functions) the matching icon.
	; PARAMETERS:
	;  stateIcons (I,REQ) - A Map that dictates which icon we should use, based on the current values
	;                       returned by getter functions. Format:
	;                       	stateIcons[getterFunc] := Map(value1, iconOrSubMap, value2, iconOrSubMap, ...)
	;                       Getter functions are fat-arrow closures like () => A_IsSuspended.
	; RETURNS:        The icon (path) that matches the current state.
	; NOTES:          An example:
	;                 	stateIcons[() => A_IsSuspended] := Map(
	;                 		1, "suspended.ico",
	;                 		0, Map(
	;                 			() => vimKeysOn, Map(0, "vimPause.ico", 1, "vim.ico")
	;                 		)
	;                 	)
	;---------
	static getIconForCurrentState(stateIcons) {
		if !(stateIcons is Map)
			return stateIcons

		; Doesn't really need to be a loop, but this lets us get the getter function and corresponding sub-map easier.
		for getter, states in stateIcons {
			currentValue := getter()
			return this.getIconForCurrentState(states[currentValue])
		}

		return "" ; If we get to a state where there's no matching icon, just return "".
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
