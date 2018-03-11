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
		updateTrayIcon()
		
		; Allow caps lock/scroll lock to be used normally while the script is suspended.
		if(A_IsSuspended) {
			SetCapsLockState,   Off
			SetScrollLockState, Off
			SetNumLockState,    On
		} else {
			SetCapsLockState,   AlwaysOff
			SetScrollLockState, AlwaysOff
			SetNumLockState,    AlwaysOn
		}
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
		updateTrayIcon()
		
		; Timers
		setTimerRunning("MainLoop", !A_IsSuspended)
	return
	setTimerRunning(timerLabel, shouldRun = 1) {
		if(!timerLabel || !IsLabel(timerLabel))
			return
		
		if(shouldRun)
			SetTimer, %timerLabel%, On
		else
			SetTimer, %timerLabel%, Off
	}
#If


; One-off scripts
#If scriptHotkeyType = HOTKEY_TYPE_STANDALONE
	; Normal exit
	!+x::ExitApp
	
	; Auto-reload script when it's saved.
	~^s::
		reloadScriptWhenSaved() {
			if(!WinActive("ahk_class Notepad++"))
				return
			
			WinGetActiveTitle, winTitle
			if(stringContains(winTitle, A_ScriptFullPath))
				Reload
		}
#If
