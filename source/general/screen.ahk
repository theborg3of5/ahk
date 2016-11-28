; Minimizing shortcut.
$!q::minimizeWindow()

; Escape key will generally minimize or close things.
~Escape::
	doEscAction()
	KeyWait, Esc, T1 ; Ensures that we don't have fall-through window closing.
return

; Sets current window to stay on top
#Space::Winset, Alwaysontop, , A

; Center current window onscreen.
#!c::centerWindow("A")

; Enable any window mouse is currently over.
#c::
	MouseGetPos,,, WinHndl, CtlHndl, 2
	
	WinGet, Style, Style, ahk_id %WinHndl%
	if (Style & 0x8000000) { ; WS_DISABLED.
		WinSet, Enable,, ahk_id %WinHndl%
	}
	
	WinGet, Style, Style, ahk_id %CtlHndl%
	if (Style & 0x8000000) { ; WS_DISABLED.
		WinSet, Enable,, ahk_id %CtlHndl%
	}
return

#w::
	Sleep, 5000
	SendMessage, 0x112, 0xF170, 2,, Program Manager
return

!+w::
	rows := []
	
	WinGetClass, currClass, A
	WinGetTitle, currTitle, A
	currControl := getFocusedControl()
	tooltipText := getTooltipText()
	
	rows.Insert(new SelectorRow("", "Class",   "c", currClass,   true))
	rows.Insert(new SelectorRow("", "Title",   "t", currTitle,   true))
	rows.Insert(new SelectorRow("", "Control", "o", currControl, true))
	rows.Insert(new SelectorRow("", "Tooltip", "p", tooltipText, true))
	
	textToCopy := Selector.select("", "RET", , , , rows)
	if(textToCopy) {
		clipboard := textToCopy
		DEBUG.popup("Copied to clipboard", textToCopy)
	}
return

; Call the Windows API function "SetSuspendState" to have the system suspend or hibernate.
; Parameter #1: Pass 1 instead of 0 to hibernate rather than suspend.
; Parameter #2: Pass 1 instead of 0 to suspend immediately rather than asking each application for permission.
; Parameter #3: Pass 1 instead of 0 to disable all wake events.
^+!#s::DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)

; Lock the computer. Good for when remote desktop'd in.
#+l::DllCall("LockWorkStation")
