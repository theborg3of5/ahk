global customToggleTimerFunc := "toggleTimers"
global defaultTimerLoopLabel := "MainLoop"

; Stores off an array representing which tray icons to show in different situations. See evalStateIcon for input format and examples.
setupTrayIcons(states) {
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


; Modified from http://www.autohotkey.com/forum/topic43514.html .
TrayIcons(sExeName = "") {
	WinGet, pidTaskbar, PID, ahk_class Shell_TrayWnd
	hProc := DllCall("OpenProcess", "Uint", 0x38, "int", 0, "Uint", pidTaskbar)
	pProc := DllCall("VirtualAllocEx", "Uint", hProc, "Uint", 0, "Uint", 32, "Uint", 0x1000, "Uint", 0x4)
	idxTB := GetTrayBar()
	SendMessage, 0x418, 0, 0, ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd ; TB_BUTTONCOUNT
	
	; DEBUG.popup("Taskbar PID", pidTaskbar, "Process handle", hProc, "Process p", pProc, "Taskbar Index", idxTB, "Error Level", ErrorLevel)
	
	Loop, %ErrorLevel%
	{
		SendMessage, 0x417, A_Index-1, pProc, ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd ; TB_GETBUTTON
			VarSetCapacity(btn,32,0), VarSetCapacity(nfo,32,0)
		DllCall("ReadProcessMemory", "Uint", hProc, "Uint", pProc, "Uint", &btn, "Uint", 32, "Uint", 0)
		iBitmap := NumGet(btn, 0)
		idn := NumGet(btn, 4)
		Statyle := NumGet(btn, 8)
		
		if(dwData := NumGet(btn,12)) {
			iString := NumGet(btn,16)
		} else {
			dwData := NumGet(btn,16,"int64")
			iString :=NumGet(btn,24,"int64")
		}
		
		; DEBUG.popup("iBitmap", iBitmap, "idn", idn, "Statyle", Statyle, "dwData", dwData, "iString", iString)
		
		DllCall("ReadProcessMemory", "Uint", hProc, "Uint", dwData, "Uint", &nfo, "Uint", 32, "Uint", 0)
		
		if(NumGet(btn,12)) {
			hWnd := NumGet(nfo, 0)
			uID := NumGet(nfo, 4)
			nMsg := NumGet(nfo, 8)
			hIcon := NumGet(nfo,20)
		} else { 
			hWnd := NumGet(nfo, 0,"int64")
			uID :=NumGet(nfo, 8)
			nMsg :=NumGet(nfo,12)
		}
		
		WinGet, pid, PID, ahk_id %hWnd%
		WinGet, sProcess, ProcessName, ahk_id %hWnd%
		WinGetClass, sClass, ahk_id %hWnd%
		
		; DEBUG.popup("Window handle", hWnd, "uID", uID, "nMsg", nMsg, "hIcon", hIcon, "sExeName", sExeName, "pid", pid, "sProcess", sProcess, "sClass", sClass)
		
		if(!sExeName || (sExeName = sProcess) || (sExeName = pid)) {
			VarSetCapacity(sTooltip,128)
			VarSetCapacity(wTooltip,128*2)
			DllCall("ReadProcessMemory", "Uint", hProc, "Uint", iString, "Uint", &wTooltip, "Uint", 128*2, "Uint", 0)
			DllCall("WideCharToMultiByte", "Uint", 0, "Uint", 0, "str", wTooltip, "int", -1, "str", sTooltip, "int", 128, "Uint", 0, "Uint", 0)
			sTrayIcons .= "idx: " . A_Index-1 . " | idn: " . idn . " | Pid: " . pid . " | uID: " . uID . " | MessageID: " . nMsg . " | hWnd: " . hWnd . " | Class: " . sClass . " | Process: " . sProcess . "`n" . "   | Tooltip: " . sTooltip . "`n"
		}
		
		; DEBUG.popup("Window handle", hWnd, "uID", uID, "nMsg", nMsg, "hIcon", hIcon, "sExeName", sExeName, "pid", pid, "sProcess", sProcess, "sClass", sClass)
	}
	
	DllCall("VirtualFreeEx", "Uint", hProc, "Uint", pProc, "Uint", 0, "Uint", 0x8000)
	DllCall("CloseHandle", "Uint", hProc)
	
	return sTrayIcons
}

GetTrayBar() {
	ControlGet, hParent, hWnd, , TrayNotifyWnd1  , ahk_class Shell_TrayWnd
	ControlGet, hChild , hWnd, , ToolbarWindow321, ahk_id %hParent%
	
	Loop {
		ControlGet, hWnd, hWnd,, ToolbarWindow32%A_Index%, ahk_class Shell_TrayWnd
		if(NOT hWnd) {
			Break
		} else if (hWnd == hChild) {
			idxTB := A_Index
			Break
		}
	}
	
	return idxTB
}

; Double-click an icon in the system tray with the given executable (case sensitive).
doubleClickTrayIcon(exeName) {
	TI := TrayIcons(exeName)
	StringSplit,TIV, TI, |
	uID  := RegExReplace( TIV4, "uID: " )
	Msg  := RegExReplace( TIV5, "MessageID: " )
	hWnd := RegExReplace( TIV6, "hWnd: " )
	
	; DEBUG.popup("TI", TI, "uID", uID, "Msg", Msg, "hWnd", hWnd)
	
	PostMessage, Msg, uID, 0x0203, , ahk_id %hWnd% ; Double Click Icon
}
