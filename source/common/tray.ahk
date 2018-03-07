; Simple wrapper to set up needed state array of icons.
; suspendStateVar - name of variable that will be true if the script is suspended.
setUpTrayIconsSimple(suspendStateVar, normalIcon, suspendedIcon) {
	states                     := []
	states[suspendStateVar, 0] := normalIcon
	states[suspendStateVar, 1] := suspendedIcon
	setUpTrayIcons(states)
}

; Stores off an array representing which tray icons to show in different situations. See evalStateIcon for input format and examples.
setUpTrayIcons(states) {
	global stateIcons
	stateIcons := states
	
	Menu, Tray, Icon, , , 1 ; 1 - Keep suspend from changing it to the AHK default.
	updateTrayIcon()
}

; Checks the states in the stateIcons array and switches the tray icon out accordingly.
updateTrayIcon() {
	global stateIcons
	; DEBUG.popup("tray", "updateTrayIcon", "Icon states array", stateIcons)
	
	newIcon := evalStateIcon(stateIcons)
	
	if(newIcon) {
		iconPath := A_WorkingDir "\" newIcon
		if(iconPath && FileExist(iconPath))
			Menu, Tray, Icon, % iconPath
	}
}

; Recursive function that drills down into an array that describes what icons should be shown when a script is in various states.
; Format:
; 		stateIcons["var1", 0]            := iconPath1
;		stateIcons["var1", 1, "var2", 0] := iconPath2
; 		stateIcons["var1", 1, "var2", 1] := iconPath3
;
; Example:
; 		Variables and desired icons to use:
; 			suspended  - 0 or 1. If 1, show suspended.ico. Otherwise, check other states.
; 			otherState - 0 or 1. If 1, show other.ico, otherwise show normal.ico.
; 		Input:
; 			stateIcons["suspended", 1] := "suspended.ico"
; 			stateIcons["suspended", 0, "otherState", 1] := "other.ico"
; 			stateIcons["suspended", 0, "otherState", 0] := "normal.ico"
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
