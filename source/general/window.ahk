; Consistent hotkeys that do the same basic thing for various windows, but sometimes in a slightly different way.

; Select all with special per-window handling.
$^a::WindowActions.selectAll()

; Backspace shortcut for those that don't handle it well.
$^Backspace::WindowActions.deleteWord()

; Escape key will generally minimize or close things.
~Escape::
	if(Config.debugOn) ; GDB TODO remove
		MsgBox, Escaping!
	WindowActions.escAction()
	KeyWait, Esc, T1 ; Ensures that we don't have fall-through window closing.
return

; When escape key is useful but is being used to minimize/close things, use backtick as a replacement.
$`::WindowActions.backtickAction()

; Minimizing shortcut.
$!q::WindowActions.minimizeWindow()

; Sets current window to stay on top
#+t::
	toggleAlwaysOnTop() {
		WinSet, AlwaysOnTop, Toggle, A
		if(WindowLib.isAlwaysOnTop("A"))
			Toast.ShowMedium("Window set to always on top").setParent("A")
		else
			Toast.ShowMedium("Window set to NOT always on top").setParent("A")
	}

; Center current window onscreen.
#+c::WindowLib.center()

; Resize window
#+r::
	selectResize() {
		if(WindowLib.isNoMoveSizeWindow("A")) {
			Toast.ShowError("Invalid window for resizing")
			return
		}
		
		data := new Selector("resize.tls").selectGui()
		if(!data)
			return
		
		new VisualWindow("A").resizeMove(data["WIDTH"], data["HEIGHT"], VisualWindow.X_Centered, VisualWindow.Y_Centered) ; Center resized window
	}

; "Fix" window position and size to match configuration TL
 #+f::WindowPositions.fixWindow() ; Active window
^#+f::WindowPositions.fixAllWindows()

; Scroll horizontally with Shift held down.
#If !(Config.isWindowActive("EpicStudio") || Config.isWindowActive("Chrome")) ; Chrome and EpicStudio handle their own horizontal scrolling, and doesn't support WheelLeft/Right all the time.
	+WheelUp::WheelLeft
	+WheelDown::WheelRight
#If

; Use the extra mouse buttons to switch tabs in various programs
#If !Config.windowIsGame() && !Config.isWindowActive("Remote Desktop") && !Config.isWindowActive("VMware Horizon Client")
	XButton1::activateWindowUnderMouseAndSendKeys("^{Tab}")
	XButton2::activateWindowUnderMouseAndSendKeys("^+{Tab}")
	activateWindowUnderMouseAndSendKeys(keys) {
		idString := WindowLib.getIdTitleStringUnderMouse()
		
		; Ignore Windows taskbars entirely.
		if(Config.windowInfo["Windows Taskbar"].windowMatches(idString))
			return
		if(Config.windowInfo["Windows Taskbar Secondary"].windowMatches(idString))
			return
		
		WinActivate, % idString
		
		HotkeyLib.sendCatchableKeys(keys)
	}
#If
