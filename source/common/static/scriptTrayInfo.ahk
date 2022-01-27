/* Class for keeping track of (and updating) tray-related information about a script, including the tray icon. =--
	
	Example usage:
;		ScriptTrayInfo.Init("AHK: Precise Mouse Movement", "mouseGreen.ico", "mouseRed.ico")
	
*/ ; --=

class ScriptTrayInfo {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Create a new object representing the tray information for the script, including icons.
	; PARAMETERS:
	;  tooltipText   (I,REQ) - Text to show when the user hovers over the tray icon.
	;  normalIcon    (I,OPT) - The full path to the "normal" icon - this will be used when the script
	;                          is not suspended.
	;  suspendedIcon (I,OPT) - The full path to the suspended icon - this will be used when the script
	;                          is suspended using the common !#x hotkey (see CommonHotkeys).
	;---------
	Init(tooltipText, normalIcon := "", suspendedIcon := "") {
		Menu, Tray, Tip, % tooltipText
		
		; Keep suspend from changing it to the AHK default, so we can use our custom suspendedIcon instead.
		if(suspendedIcon)
			Menu, Tray, Icon, , , 1
		
		; Build states array from given icons
		this.stateIcons := {}
		this.stateIcons["A_IsSuspended", 0] := normalIcon
		this.stateIcons["A_IsSuspended", 1] := suspendedIcon
		
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
	setStateIcons(states) {
		Menu, Tray, Icon, , , 1 ; Assume that there will always be a path in here to a suspended icon we should use.
		
		this.stateIcons := states
		this.updateTrayIcon()
	}

	;---------
	; DESCRIPTION:    Determine the icon that should be used for the script (based on the variables
	;                 defined in the stateIcons array) and apply it.
	;---------
	updateTrayIcon() {
		newIcon := this.getIconForCurrentState(this.stateIcons)
		; Debug.popup("ScriptTrayInfo.updateTrayIcon","Start", "this.stateIcons",this.stateIcons, "newIcon",newIcon)
		if(!newIcon)
			return
			
		iconPath := A_WorkingDir "\" newIcon
		if(!FileExist(iconPath))
			return
		
		Menu, Tray, Icon, % iconPath
	}
	
	
	; #PRIVATE#
	
	static stateIcons := {} ; Associative array representing which icon to use in different situations - see .getIconForCurrentState() for explanation.

	;---------
	; DESCRIPTION:    Recursively drill down into the given array and determine (based on the states
	;                 of the variables named in that array) the matching icon.
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
		if(!isObject(stateIcons))
			return stateIcons
		
		; Doesn't really need to be a loop, but this lets us get the index (which is the variable name in question) and corresponding pieces easier.
		For varName,states in stateIcons {
			; Debug.popup("varName",varName, "states",states, "%varName%",%varName%, "states[%varName%]",states[%varName%])
			return this.getIconForCurrentState(states[%varName%])
		}
		
		return "" ; If we get to a state where there's no matching icon, just return "".
	}
	; #END#
}
