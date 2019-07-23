/* Class for keeping track of certain information about a script
*/

class CommonHotkeys {

; ==============================
; == Public ====================
; ==============================
	; Different sets of common hotkeys
	static ScriptType_Standalone := 0 ; One-off scripts, not connected to master script
	static ScriptType_Master     := 1 ; Master script
	static ScriptType_SubMaster  := 2 ; Standalone scripts that the master script starts and that run alongside the master script
	
	
	__New(scriptType, trayInfo := "") {
		this._scriptType := scriptType
		this._trayInfo   := trayInfo
		
		this.applyHotkeys()
	}
	
	
	ConfirmExit {
		get {
			return this._confirmExit
		}
		set {
			this._confirmExit := value
		}
	}
	SuspendHotkeyOn {
		get {
			return this._suspendHotkeyOn
		}
		set {
			this._suspendHotkeyOn := value
		}
	}
	
	
	IsStandalone {
		get {
			return (this._scriptType = this.ScriptType_Standalone)
		}
	}
	IsMaster {
		get {
			return (this._scriptType = this.ScriptType_Master)
		}
	}
	IsSub {
		get {
			return (this._scriptType = this.ScriptType_SubMaster)
		}
	}
	
	
	
	
	
	
	
	
	
	
; ==============================
; == Private ===================
; ==============================
	static _scriptType := "" ; Type of script, from this.ScriptType_* constants
	static _trayInfo := "" ; Reference to the script's ScriptTrayInfo object
	static _confirmExit := false
	static _suspendHotkeyOn := true ; Whether the suspend hotkey is on ; GDB TODO is this needed, or can the property just make it happen, clearing the hotkey if it already exists?
	
	
	
	applyHotkeys() {
		
		; doEmergencyExit  := ObjBindMethod(this, "doEmergencyExit")
		doExit           := ObjBindMethod(this, "doExit")
		; doToggleSuspend  := ObjBindMethod(this, "doToggleSuspend")
		; doReload         := ObjBindMethod(this, "doReload")
		; areEditingScript := ObjBindMethod(this, "areEditingScript")
		
		; Exit
		; Hotkey, ~^+!#r, % doEmergencyExit
		; functionObjToDoEvenIfSuspended := doEmergencyExit
		Hotkey, ~^+!#r, CommonHotkeys_doEmergencyExit
		if(this.IsStandalone)
			Hotkey, !+x, CommonHotkeys_doExit
			; Hotkey, !+x, % doExit
			; Hotkey, !+x, CommonHotkeys_doExit
		
		; ; Suspend
		; if(this.IsMaster)
			; Hotkey, !#x, % doToggleSuspend ; Master script catches it to prevent it falling through
		; else if(this.IsSub || this.IsStandalone)
			; Hotkey, ~!#x, % doToggleSuspend ; Other scripts let it fall through so all other scripts can react
		
		; ; Reload
		; if(this.IsMaster)
			; Hotkey, !+r, % doReload ; Master only, it replaces the sub scripts by running them again.
		; if(this.IsStandalone) { ; Reload on save for standalone scripts
			; Hotkey, If, this.areEditingScript
			; Hotkey, ~^s, % doReload()
			; Hotkey, If ; Clear condition
		; }
	}
	
	doEmergencyExit() {
		ExitApp
	}
	
	doExit() {
		MsgBox, % this._confirmExit
		
		; Confirm exiting if that's turned on.
		if(this._confirmExit) {
			if(!showConfirmationPopup("Are you sure you want to exit this script?"))
				return
		}
		
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
		Suspend, Permit
		
		; Pre-suspend hook (implemented by calling script)
		if(!A_IsSuspended) { ; Not suspended, so about to be
			beforeSuspendFunction := "beforeSuspend"
			if(isFunc(beforeSuspendFunction))
				%beforeSuspendFunction%()
		}
		
		Suspend, Toggle
		this._trayInfo.updateTrayIcon()
		
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
	
	doReload() {
		Suspend, Permit
		Reload
	}
	
	areEditingScript() {
		if(!WinActive("ahk_class Notepad++"))
			return false
		
		return stringContains(WinGetActiveTitle(), A_ScriptFullPath)
	}
	
	
	
	
	
}

global CommonHotkeysInstance

CommonHotkeys_doEmergencyExit() {
	Suspend, Permit
	CommonHotkeysInstance.doEmergencyExit()
}
CommonHotkeys_doExit() {
	CommonHotkeysInstance.doExit()
}
CommonHotkeys_doToggleSuspend() {
	Suspend, Permit
	CommonHotkeysInstance.doToggleSuspend()
}
CommonHotkeys_doReload() {
	CommonHotkeysInstance.doReload()
}