/* Class for keeping track of certain information about a script
*/

class CommonHotkeys {

; ==============================
; == Public ====================
; ==============================
	; Different "types" of scripts, which get different sets of hotkeys
	static ScriptType_Master     := 1 ; Master script
	static ScriptType_SubMaster  := 2 ; Standalone scripts that the master script starts and that run alongside the master script
	static ScriptType_Standalone := 3 ; One-off scripts, not connected to master script
	
	Init(scriptType, trayInfo := "") {
		CommonHotkeys._scriptType := scriptType
		CommonHotkeys._trayInfo   := trayInfo
		
		CommonHotkeys.applyHotkeys()
	}
	
	
	ConfirmExit {
		get {
			return CommonHotkeys._confirmExit
		}
		set {
			CommonHotkeys._confirmExit := value
		}
	}
	NoSuspend {
		get {
			return CommonHotkeys._noSuspend
		}
		set {
			if(CommonHotkeys._noSuspend = value)
				return ; No change
			
			CommonHotkeys._noSuspend := value
			if(value)
				Hotkey, !#x, Off
			else
				Hotkey, !#x, On
		}
	}
	
	
	IsMaster {
		get {
			return (CommonHotkeys._scriptType = CommonHotkeys.ScriptType_Master)
		}
	}
	IsSub {
		get {
			return (CommonHotkeys._scriptType = CommonHotkeys.ScriptType_SubMaster)
		}
	}
	IsStandalone {
		get {
			return (CommonHotkeys._scriptType = CommonHotkeys.ScriptType_Standalone)
		}
	}
	
	
; ==============================
; == Private ===================
; ==============================
	static _scriptType  := "" ; Type of script, from CommonHotkeys.ScriptType_* constants
	static _trayInfo    := "" ; Reference to the script's ScriptTrayInfo object
	static _confirmExit := false ; Whether to confirm before exiting
	static _noSuspend   := false ; Whether the suspend hotkey is suppressed
	
	
	applyHotkeys() {
		; Exit
		Hotkey, ~^+!#r, CommonHotkeys_doEmergencyExit
		if(CommonHotkeys.IsStandalone)
			Hotkey, !+x, CommonHotkeys_doExit
		
		; Suspend
		; Suspend (on by default, can be disabled/re-enabled with CommonHotkeys.NoSuspend)
		if(CommonHotkeys.IsMaster)
			Hotkey, !#x, CommonHotkeys_doToggleSuspend ; Master script catches it to prevent it falling through
		if(CommonHotkeys.IsSub || CommonHotkeys.IsStandalone)
			Hotkey, ~!#x, CommonHotkeys_doToggleSuspend ; Other scripts let it fall through so all other scripts can react
		
		; Reload
		if(CommonHotkeys.IsMaster)
			Hotkey, !+r, CommonHotkeys_doReload ; Master only, it replaces the sub scripts by running them again.
		if(CommonHotkeys.IsStandalone) {
			; Reload on save if editing the script in question
			areEditingThisScript := ObjBindMethod(CommonHotkeys, "areEditingThisScript")
			Hotkey, If, % areEditingThisScript
			Hotkey, ~^s, CommonHotkeys_doReload
			Hotkey, If ; Clear condition
		}
	}
	
	doEmergencyExit() {
		ExitApp
	}
	
	doExit() {
		; Confirm exiting if that's turned on.
		if(CommonHotkeys._confirmExit) {
			if(!showConfirmationPopup("Are you sure you want to exit this script?"))
				return
		}
		
		ExitApp
	}
	
	doReload() {
		Reload
	}
	
	
	;---------
	; DESCRIPTION:    Suspend the script, updating the tray icon, pausing a timer with a special name
	;                 and calling pre-suspend/post-unsuspend hooks.
	; NOTES:          - Any timers for the label called "MainLoop" will be disabled on suspend and re-enabled on unsuspend.
	;                 - If a function named "beforeSuspend" exists, we will call it before we suspend the script.
	;                 - If a function named "afterUnsuspend" exists, we will call it after we unsuspend the script.
	;---------
	doToggleSuspend() {
		; Pre-suspend hook (implemented by calling script)
		if(!A_IsSuspended) { ; Not suspended, so about to be
			beforeSuspendFunction := "beforeSuspend"
			if(isFunc(beforeSuspendFunction))
				%beforeSuspendFunction%()
		}
		
		Suspend, Toggle
		CommonHotkeys._trayInfo.updateTrayIcon()
		
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
	
	areEditingThisScript() {
		if(!WinActive("ahk_class Notepad++"))
			return false
		
		return stringContains(WinGetActiveTitle(), A_ScriptFullPath)
	}
	
	
	
	
	
}

CommonHotkeys_doEmergencyExit() {
	Suspend, Permit
	CommonHotkeys.doEmergencyExit()
}
CommonHotkeys_doExit() {
	CommonHotkeys.doExit()
}
CommonHotkeys_doReload() {
	CommonHotkeys.doReload()
}
CommonHotkeys_doToggleSuspend() {
	Suspend, Permit
	CommonHotkeys.doToggleSuspend()
}