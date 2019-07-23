/* Class for keeping track of certain information about a script
*/

class CommonHotkeys {

; ==============================
; == Public ====================
; ==============================
	; Different sets of common hotkeys
	static ScriptType_Master     := 1 ; Master script
	static ScriptType_SubMaster  := 2 ; Standalone scripts that the master script starts and that run alongside the master script
	static ScriptType_Standalone := 3 ; One-off scripts, not connected to master script
	
	
	__New(scriptType, trayInfo := "") {
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
	SuspendHotkeyOn {
		get {
			return CommonHotkeys._suspendHotkeyOn
		}
		set {
			CommonHotkeys._suspendHotkeyOn := value
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
	static _scriptType := "" ; Type of script, from CommonHotkeys.ScriptType_* constants
	static _trayInfo := "" ; Reference to the script's ScriptTrayInfo object
	static _confirmExit := false
	static _suspendHotkeyOn := true ; Whether the suspend hotkey is on ; GDB TODO is this needed, or can the property just make it happen, clearing the hotkey if it already exists?
	
	
	applyHotkeys() {
		; doEmergencyExit  := ObjBindMethod(CommonHotkeys, "doEmergencyExit")
		; doToggleSuspend  := ObjBindMethod(CommonHotkeys, "doToggleSuspend")
		
		; Things that should work even when the script is suspended (using CommonHotkeys_* functions outside of the class, as we can't make a BoundFunc object run while suspended)
		Hotkey, ~^+!#r, CommonHotkeys_doEmergencyExit
		if(CommonHotkeys.IsMaster)
			Hotkey, !#x, CommonHotkeys_doToggleSuspend ; Master script catches it to prevent it falling through
		else if(CommonHotkeys.IsSub || CommonHotkeys.IsStandalone)
			Hotkey, ~!#x, CommonHotkeys_doToggleSuspend ; Other scripts let it fall through so all other scripts can react
		
		; Hotkeys that only run when we're not suspended (so we can use BoundFunc objects to reference functions inside this class).
		doExit   := ObjBindMethod(CommonHotkeys, "doExit")
		doReload := ObjBindMethod(CommonHotkeys, "doReload")
		; areEditingScript := ObjBindMethod(CommonHotkeys, "areEditingScript")
		if(CommonHotkeys.IsMaster)
			Hotkey, !+r, % doReload ; Master only, it replaces the sub scripts by running them again.
		if(CommonHotkeys.IsStandalone) {
			Hotkey, !+x, % doExit
			; Hotkey, If, CommonHotkeys.areEditingScript
			; Hotkey, ~^s, % doReload()
			; Hotkey, If ; Clear condition
		}
	}
	
	doEmergencyExit() {
		ExitApp
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
	
	areEditingScript() {
		if(!WinActive("ahk_class Notepad++"))
			return false
		
		return stringContains(WinGetActiveTitle(), A_ScriptFullPath)
	}
	
	
	
	
	
}

CommonHotkeys_doEmergencyExit() {
	Suspend, Permit
	CommonHotkeys.doEmergencyExit()
}
CommonHotkeys_doToggleSuspend() {
	Suspend, Permit
	CommonHotkeys.doToggleSuspend()
}
; CommonHotkeys_doExit() {
	; CommonHotkeys.doExit()
; }
; CommonHotkeys_doReload() {
	; CommonHotkeys.doReload()
; }