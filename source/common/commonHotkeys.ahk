; === Hotkeys that all scripts should use. === ;

; Emergency exit
~^+!#r::
	Suspend, Permit
	ExitApp
return

#If scriptHotkeyType = HOTKEY_TYPE_MASTER
	; Suspend hotkey, change tray icon too.
	!#x::
		Suspend, Toggle
		suspended := !suspended
		updateTrayIcon()
	return

	; Hotkey for reloading entire script.
	!+r::
		Suspend, Permit
		Reload
	return
#If

; All standalone - both those that main script runs, and one-off scripts
#If (scriptHotkeyType = HOTKEY_TYPE_SUB_MASTER) || (scriptHotkeyType = HOTKEY_TYPE_STANDALONE)
	; Suspend hotkey (with pass-thru so it applies to all scripts)
	~!#x::
		Suspend, Toggle
		suspended := !suspended
		updateTrayIcon()
		
		; Timers
		if(IsFunc(customToggleTimerFunc))       ; If there's a custom toggleTimers() function, use that.
			%customToggleTimerFunc%(suspended)
		else if(IsLabel(defaultTimerLoopLabel)) ; Otherwise, if the label "MainLoop" exists, turn that timer off.
			SetTimer, %defaultTimerLoopLabel%, % suspended ? "Off" : "On" ; If script is suspended, toggle it off, otherwise on.
	return
#If

; One-off scripts
#If scriptHotkeyType = HOTKEY_TYPE_STANDALONE
	; Normal exit
	!+x::ExitApp
	
	; Auto-reload script when it's saved.
	~^s::
		if(!WinActive("ahk_class Notepad++"))
			return
		
		WinGetActiveTitle, winTitle
		if(stringContains(winTitle, A_ScriptFullPath))
			Reload
	return
#If
