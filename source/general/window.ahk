; Consistent hotkeys that do the same basic thing for various windows, but sometimes in a slightly different way.

; Select all with special per-window handling.
$^a::WindowActions.selectAll()

; Backspace shortcut for those that don't handle it well.
$^Backspace::WindowActions.deleteWord()

; Escape key will generally minimize or close things.
~Escape::
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
			new Toast("Window set to always on top").setParent("A").showMedium()
		else
			new Toast("Window set to NOT always on top").setParent("A").showMedium()
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

; "Fix" window position and size to match configuration TL
#+f::
	fixWindowPositionSingle() {
		titleString := "A"
		
		name := Config.findWindowName(titleString)
		if(!name)
			return
		
		table := new TableList(".\windowPositions.tl").getRowsByColumn("NAME")
		position := table[name]
		
		; If we didn't find a line in the table for the window name, make sure it doesn't match any of the other rows' windows (for specific overrides).
		if(!position) {
			; GDB TODO consider a version of Config.findWindowName() that returns something other than the lowest-priority option - maybe return array of results, indexed by priority?
			For posName,pos in table {
				if(Config.windowInfo[posName].windowMatches(titleString)) {
					position := pos
					break
				}
			}
		}
		
		fixWindowPosition(titleString, position)
	}
^#+f::
	fixWindowPositionAll() {
		table := new TableList("windowPositions.tl").getRowsByColumn("NAME")
		For name,position in table {
			idString := "ahk_id " Config.windowInfo[name].getMatchingWindowID()
			fixWindowPosition(idString, position)
		}
	}
fixWindowPosition(titleString, position) {
	if(!position)
		return
	
	; Track initially-minimized windows so we can re-minimize them when we're done (VisualWindow.resizeMove will restore them).
	startedMinimized := WindowLib.isMinimized(titleString)
	
	monitorBoundsByLocation := WindowLib.getMonitorBoundsByLocation()
	monitorBounds := monitorBoundsByLocation[position["MONITOR"]]
	new VisualWindow(titleString).resizeMove(position["WIDTH"], position["HEIGHT"], position["X"], position["Y"], monitorBounds)
	
	; Re-minimize if the window started out that way.
	if(startedMinimized)
		WinMinimize, % titleString
}

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
		
		settings := new TempSettings().sendLevel(1) ; Allow the keystrokes to be caught and handled by other hotkeys.
		Send, %keys%
		settings.restore()
	}
#If
