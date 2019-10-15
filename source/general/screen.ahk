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
		WinSet, AlwaysOnTop, Toggle, A
		if(MicrosoftLib.isWindowAlwaysOnTop())
			new Toast("Window set to always on top").showMedium()
		else
			new Toast("Window set to NOT always on top").showMedium()
	}

; Center current window onscreen.
#+c::WindowLib.center()

; Fake-maximize the window and center it.
#+m::WindowLib.fakeMaximize()

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
