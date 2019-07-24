/* Class for keeping track of (and updating) tray-related information about a script, including the tray icon.
*/

class ScriptTrayInfo {

; ==============================
; == Public ====================
; ==============================
	;---------
	; DESCRIPTION:    Set a normal icon to use for your script, and a suspended icon to use when the ; GDB TODO redo all of these function headers.
	;                 script is suspended (using the common !#x hotkey).
	; PARAMETERS:
	;  tooltipText   (I,REQ) - Text to show when the user hovers over the tray icon.
	;  normalIcon    (I,OPT) - The full path to the "normal" icon - this will be used when the script
	;                          is not suspended.
	;  suspendedIcon (I,OPT) - The full path to the suspended icon - this will be used when the script
	;                          is suspended.
	;---------
	__New(tooltipText, normalIcon := "", suspendedIcon := "") {
		Menu, Tray, Tip, % tooltipText
		
		; Keep suspend from changing it to the AHK default, so we can use our custom suspendedIcon instead.
		if(suspendedIcon)
			Menu, Tray, Icon, , , 1
		
		; Build states array from given icons
		this._iconStates := []
		this._iconStates["A_IsSuspended", 0] := normalIcon
		this._iconStates["A_IsSuspended", 1] := suspendedIcon
		
		this.updateTrayIcon()
	}

	;---------
	; DESCRIPTION:    Store off the array that will be used by getIconForCurrentState() to determine what icon
	;                 to show for a script.
	; PARAMETERS:
	;  states (I,REQ) - A tree-like array that maps the states of different variables to the icons that
	;                   we should use for the script. Format:
	;                   	states["varName", varState] := iconPath
	;                   See getIconForCurrentState() for a more in-depth explanation.
	; SIDE EFFECTS:   Set the value of the global scriptStateIcons array, configure the tray icon so that it
	;                 won't change to the default suspended icon when the script is suspended.
	;---------
	setIconStates(statesAry) {
		this._iconStates := statesAry
		
		Menu, Tray, Icon, , , 1 ; Assume that there will always be a path in here to a suspended icon we should use.
		
		this.updateTrayIcon()
	}

	;---------
	; DESCRIPTION:    Determine the icon that should be used for the script (based on the variables
	;                 defined in the global scriptStateIcons array) and have the script use it.
	; SIDE EFFECTS:   Potentially update the script's tray icon.
	;---------
	updateTrayIcon() {
		newIcon := this.getIconForCurrentState(this._iconStates)
		; DEBUG.popup("ScriptTrayInfo.updateTrayIcon","Start", "this._iconStates",this._iconStates, "newIcon",newIcon)
		if(!newIcon)
			return
			
		iconPath := A_WorkingDir "\" newIcon
		if(!FileExist(iconPath))
			return
		
		Menu, Tray, Icon, % iconPath
	}
	
	
; ==============================
; == Private ===================
; ==============================
	_iconStates := []

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
	getIconForCurrentState(stateIcons) {
		if(!isObject(stateIcons)) {
			; DEBUG.popup("tray","getIconForCurrentState", "Base case: quitting because no longer object", stateIcons)
			return stateIcons
		}
		
		; Doesn't really need to be a loop, but this lets us get the index (which is the variable name in question) and corresponding pieces easier.
		For varName,states in stateIcons {
			; DEBUG.popup("Var name", varName, "States", states, "Variable value", %varName%, "Corresponding value", states[%varName%])
			return this.getIconForCurrentState(states[%varName%])
		}
		
		; Shouldn't happen if the this._iconStates array is comprehensive.
		return "" ; If we get to a state where there's no matching icon, just return "".
	}
}
