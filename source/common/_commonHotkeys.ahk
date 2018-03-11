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
		mainLoop := "MainLoop" ; Have to put this in a variable, otherwise it fails at startup for scripts that don't have a MainLoop label
		if(IsLabel(mainLoop)) { ; If the label "MainLoop" exists, turn that timer off.
			if(A_IsSuspended)
				SetTimer, %mainLoop%, Off
			else
				SetTimer, %mainLoop%, On
		}
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
