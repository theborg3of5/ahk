; === Hotkeys that all scripts should use. === ;

#If isBorgMasterScript
	; Hotkey to die.
	^+!#r::
		Suspend, Permit
		ExitApp
	return
	
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
	
	; Pop up the keys pressed/debug window.
	^!k::KeyHistory

	; Universal closer for other AHK scripts, catch it here to prevent going to the underlying window.
	!+x::return
#If

#If !isBorgMasterScript
	; Hotkey to die.
	~^+!#r::
		Suspend, Permit
		ExitApp
	return
	
	; Suspend hotkey.
	~!#x::
		Suspend, Toggle
		suspended := !suspended
		
		; Update tray icon
		updateTrayIcon()
		
		; Timers
		if(IsFunc(customToggleTimerFunc))       ; If there's a custom toggleTimers() function, use that.
			customToggleTimerFunc.(suspended)
		else if(IsLabel(defaultTimerLoopLabel)) ; Otherwise, if the label "MainLoop" exists, turn that timer off.
			SetTimer, %defaultTimerLoopLabel%, % suspended ? "Off" : "On" ; If script is suspended, toggle it off, otherwise on.
	return

	; Hotkey for reloading entire script.
	~!+r::
		Suspend, Permit
		Reload
	return
#If

; One-off scripts
#If isSingleUserScript
	~!+x::ExitApp
#If
