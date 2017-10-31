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
#+c::centerWindow()

; Fake-maximize the window and center it.
#+m::fakeMaximizeWindow()

; Enable any window mouse is currently over.
#c::
	MouseGetPos,,, WinHndl, CtlHndl, 2
	
	WinGet, Style, Style, ahk_id %WinHndl%
	if (Style & WS_DISABLED) {
		WinSet, Enable,, ahk_id %WinHndl%
	}
	
	WinGet, Style, Style, ahk_id %CtlHndl%
	if (Style & WS_DISABLED) {
		WinSet, Enable,, ahk_id %CtlHndl%
	}
return

F1::
	rows := []
	
	WinGetClass, currClass, A
	WinGetTitle, currTitle, A
	currControl := getFocusedControl()
	tooltipText := getTooltipText()
	
	; DEBUG.popup("Class", currClass, "Title", currTitle, "Control", currControl, "Tooltip text", tooltipText)
	
	rows.Insert(new SelectorRow("", "Class",   "c", currClass,   true))
	rows.Insert(new SelectorRow("", "Tooltip", "t", tooltipText, true))
	rows.Insert(new SelectorRow("", "Title",   "i", currTitle,   true))
	rows.Insert(new SelectorRow("", "Control", "o", currControl, true))
	
	s := new Selector()
	s.setChoices(rows)
	textToCopy := s.selectGui()
	
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
