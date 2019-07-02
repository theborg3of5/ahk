; === Hotkeys that all scripts should use. === ;

global scriptHotkeyType, scriptStateIcons, scriptConfirmQuit

; Emergency exit
~^+!#r::
	Suspend, Permit
	ExitApp
return

#If scriptHotkeyType = HOTKEY_TYPE_Master
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
#If (scriptHotkeyType = HOTKEY_TYPE_SubMaster) || (scriptHotkeyType = HOTKEY_TYPE_Standalone)
	; Suspend hotkey (with pass-thru so it applies to all scripts)
	~!#x::
		Suspend, Toggle
		updateTrayIcon()
		
		; Timers
		setTimerRunning("MainLoop", !A_IsSuspended)
	return
	setTimerRunning(timerLabel, shouldRun := 1) {
		if(!timerLabel || !IsLabel(timerLabel))
			return
		
		if(shouldRun)
			SetTimer, %timerLabel%, On
		else
			SetTimer, %timerLabel%, Off
	}
#If


; One-off scripts
#If scriptHotkeyType = HOTKEY_TYPE_Standalone
	; Normal exit
	!+x::
		if(scriptConfirmQuit)
			if(!showConfirmationPopup("Are you sure you want to exit this script?"))
				return
		
		ExitApp
	return
	
	; Auto-reload script when it's saved.
	~^s::
		reloadScriptWhenSaved() {
			if(!WinActive("ahk_class Notepad++"))
				return
			
			winTitle := WinGetActiveTitle()
			if(stringContains(winTitle, A_ScriptFullPath))
				Reload
		}
#If
