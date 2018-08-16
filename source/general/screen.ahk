; Minimizing shortcut.
$!q::minimizeWindow()

; Escape key will generally minimize or close things.
~Escape::
	escAction()
	KeyWait, Esc, T1 ; Ensures that we don't have fall-through window closing.
return

; Sets current window to stay on top
#+t::Winset, Alwaysontop, , A

; Center current window onscreen.
#+c::centerWindow()

; Fake-maximize the window and center it.
#+m::fakeMaximizeWindow()

; Resize window
#+r::
	selectResize() {
		s := new Selector("resize.tl")
		data := s.selectGui()
		if(data)
			WinMove, A, , , , data["WIDTH"], data["HEIGHT"]
	}

; ; Enable any window mouse is currently over.
; #c::
	; MouseGetPos(, , WinHndl, CtlHndl, 2)
	
	; winStyle := WinGet("Style", "ahk_id " WinHndl)
	; if (winStyle & WS_DISABLED) {
		; WinSet, Enable,, ahk_id %WinHndl%
	; }
	
	; winStyle := WinGet("Style", "ahk_id " CtlHndl)
	; if (winStyle & WS_DISABLED) {
		; WinSet, Enable,, ahk_id %CtlHndl%
	; }
; return

; Call the Windows API function "SetSuspendState" to have the system suspend or hibernate.
; Parameter #1: Pass 1 instead of 0 to hibernate rather than suspend.
; Parameter #2: Pass 1 instead of 0 to suspend immediately rather than asking each application for permission.
; Parameter #3: Pass 1 instead of 0 to disable all wake events.
^+!#s::DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)

; Lock the computer. Good for when remote desktop'd in.
#+l::DllCall("LockWorkStation")
