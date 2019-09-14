; Minimizing shortcut.
$!q::WindowActions.minimizeWindow()

; Escape key will generally minimize or close things.
~Escape::
	WindowActions.escAction()
	KeyWait, Esc, T1 ; Ensures that we don't have fall-through window closing.
return

; Sets current window to stay on top
#+t::
	toggleAlwaysOnTop() {
		WinGet, extendedStyle, ExStyle, A
		if(extendedStyle & WS_EX_WS_EX_TOPMOST) ; Window is currently always on top
			newState := "Off"
		else
			newState := "On"
		
		Toast.showMedium("Window always on top: " newState)
		WinSet, AlwaysOnTop, % newState, A
	}

; Center current window onscreen.
#+c::centerWindow()

; Fake-maximize the window and center it.
#+m::fakeMaximizeWindow()

; Resize window
#+r::
	selectResize() {
		data := new Selector("resize.tls").selectGui()
		if(!data)
			return
		
		; Default to centering resized window if nothing specified.
		x := data["X"]
		y := data["Y"]
		if(x = "")
			x := VisualWindow.X_Centered
		if(y = "")
			y := VisualWindow.Y_Centered
		
		new VisualWindow("A").resizeMove(data["WIDTH"], data["HEIGHT"], x, y)
	}

; Call the Windows API function "SetSuspendState" to have the system suspend or hibernate.
; Parameter #1: Pass 1 instead of 0 to hibernate rather than suspend.
; Parameter #2: Pass 1 instead of 0 to suspend immediately rather than asking each application for permission.
; Parameter #3: Pass 1 instead of 0 to disable all wake events.
^+!#s::DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)

; Lock the computer. Good for when remote desktop'd in.
#+l::DllCall("LockWorkStation")
