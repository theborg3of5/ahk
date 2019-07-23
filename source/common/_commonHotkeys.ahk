; === Hotkeys that all scripts should use. === ;

; Globals used here are defined in _setup.ahk:
;   scriptHotkeyType
;   scriptStateIcons
;   scriptConfirmQuit

; Emergency exit
~^+!#r::
	Suspend, Permit
	ExitApp
return

; Suspend + update tray icon, pause special timers, call pre-suspend/post-unsuspend hooks
#If scriptHotkeyType = HOTKEY_TYPE_Master
	!#x::
		Suspend, Permit
		suspendScript()
	return
#If (scriptHotkeyType = HOTKEY_TYPE_SubMaster) || (scriptHotkeyType = HOTKEY_TYPE_Standalone)
	~!#x:: ; Pass-through needed on this one so that all non-master scripts can get it (and then master catches it last).
		Suspend, Permit
		suspendScript()
	return
#If

;---------
; DESCRIPTION:    Suspend the script, updating the tray icon, pausing a timer with a special name
;                 and calling pre-suspend/post-unsuspend hooks.
; NOTES:          - Any timers for the label called "MainLoop" will be disabled on suspend and re-enabled on unsuspend.
;                 - If a function named "beforeSuspend" exists, we will call it before we suspend the script.
;                 - If a function named "afterUnsuspend" exists, we will call it after we unsuspend the script.
;---------
suspendScript() {
	; Pre-suspend hook (implemented by calling script)
	if(!A_IsSuspended) { ; Not suspended, so about to be
		beforeSuspendFunction := "beforeSuspend"
		if(isFunc(beforeSuspendFunction))
			%beforeSuspendFunction%()
	}
	
	Suspend, Toggle
	updateTrayIcon()
	
	; Timers
	mainLoopLabel := "MainLoop"
	if(IsLabel(mainLoopLabel)) {
		if(A_IsSuspended)
			SetTimer, % mainLoopLabel, Off
		else
			SetTimer, % mainLoopLabel, On
	}
	
	; Post-unsuspend hook (implemented by calling script)
	if(!A_IsSuspended) { ; Just unsuspended
		afterUnsuspendFunction := "afterUnsuspend"
		if(isFunc(afterUnsuspendFunction))
			%afterUnsuspendFunction%()
	}
}

; Reload
#If scriptHotkeyType = HOTKEY_TYPE_Master ; Master only, it replaces the sub scripts by running them again.
	!+r::
		Suspend, Permit
		Reload
	return
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
