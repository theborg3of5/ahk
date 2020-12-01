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

; Resize window
#+r::
	selectResize() {
		if(WindowLib.isNoMoveSizeWindow("A")) {
			new ErrorToast("Invalid window for resizing").showShort()
			return
		}
		
		data := new Selector("resize.tls").selectGui()
		if(!data)
			return
		
		new VisualWindow("A").resizeMove(data["WIDTH"], data["HEIGHT"], VisualWindow.X_Centered, VisualWindow.Y_Centered) ; Center resized window
	}

; "Fix" window position and size to match configuration TL
 #+f::fixWindowPositions("A")
^#+f::fixWindowPositions() ; Fix all windows in the config file
fixWindowPositions(titleString := "") {
	; If we're being asked to fix a specific window, assume non-preset case. Otherwise, ask for preset (which can also turn out blank).
	if(titleString != "")
		preset := "NORMAL"
	else
		preset := new Selector("windowPositionPresets.tls").selectGui("PRESET")
	if(preset = "")
		return
	
	positions := new TableList("windowPositions.tl").filterByColumn("PRESET", preset).getRowsByColumn("NAME")
	
	; Fix a single window.
	if(titleString != "") {
		For _,names in Config.findAllMatchingWindowNames(titleString) { ; Looping in priority order
			For _,name in names {
				if(positions[name]) {
					position := positions[name]
					Break
				}
			}
		}
		
		fixWindowPosition(titleString, position)
	
	; Fix all the windows in the config file at once.
	} else {
		pt := new ProgressToast("Fixing window positions")
		For name,position in positions {
			pt.nextStep(name, "fixed")
			
			winInfo := Config.windowInfo[name]
			if(!winInfo.exists()) {
				pt.endStep("not found")
				Continue
			}
			
			fixWindowPosition(winInfo.idString, position)
		}
		pt.finish()
	}
}
fixWindowPosition(titleString, position) {
	if(!position)
		return
	
	; Track initially-minimized windows so we can re-minimize them when we're done (VisualWindow.resizeMove will restore them).
	startedMinimized := WindowLib.isMinimized(titleString)
	
	workArea := MonitorLib.workAreaForLocation[position["MONITOR"]]
	new VisualWindow(titleString).resizeMove(position["WIDTH"], position["HEIGHT"], position["X"], position["Y"], workArea)
	
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
