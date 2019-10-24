; Minimizing shortcut.
$!q::WindowActions.minimizeWindow()

; Escape key will generally minimize or close things.
~Escape::
	WindowActions.escAction()
	KeyWait, Esc, T1 ; Ensures that we don't have fall-through window closing.
return

; Sets current window to stay on top
+#t::
	toggleAlwaysOnTop() {
		WinSet, AlwaysOnTop, Toggle, A
		if(WindowLib.isAlwaysOnTop())
			new Toast("Window set to always on top").showMedium()
		else
			new Toast("Window set to NOT always on top").showMedium()
	}

; Center current window onscreen.
+#c::WindowLib.center()

; Fake-maximize the window and center it.
+#m::WindowLib.fakeMaximize()

; Resize window
+#r::
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
