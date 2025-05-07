/* Class for applying certain common hotkeys to a script, based on the type of script and certain flags.
	
	Example usage:
;		CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)
	
*/

class CommonHotkeys {
	;region ------------------------------ PUBLIC ------------------------------
	;region Script "types"
	; Each gets a different set of hotkeys.
	static ScriptType_Main       := 1 ; Main script
	static ScriptType_Sub        := 2 ; Standalone scripts that the main script starts and that run alongside the main script
	static ScriptType_Standalone := 3 ; One-off scripts, not connected to main script
	;endregion Script "types"
	
	;---------
	; DESCRIPTION:    Set up the common hotkeys.
	; PARAMETERS:
	;  scriptType        (I,REQ) - The "type" of script, from CommonHotkeys.ScriptType_*. This
	;                              determines which "set" of hotkeys are applied.
	;---------
	Init(scriptType) {
		this.scriptType := scriptType
		
		this.applyHotkeys()
	}
	
	;---------
	; DESCRIPTION:    The name of a label that should be suspended when the script is suspended using the hotkey from this
	;                 class.
	; PARAMETERS:
	;  newLabel (I,REQ) - The name of the label.
	;---------
	setSuspendTimerLabel(newLabel) {
		this.suspendTimerLabel := newLabel
	}
	
	;---------
	; DESCRIPTION:    Prompt the user to confirm when exiting with the common exit hotkey (!+x).
	;---------
	confirmExitOn(message := "") {
		this.confirmExit := true
		if(message != "")
			this.confirmExitMessage := message
	}
	;---------
	; DESCRIPTION:    Do not prompt the user to confirm when exiting with the common exit hotkey (!+x).
	;---------
	confirmExitOff() {
		this.confirmExit := false
	}
	
	;---------
	; DESCRIPTION:    Ignore the common suspend hotkey (!#x).
	; SIDE EFFECTS:   Actually turns the hotkey off.
	;---------
	noSuspendOn() {
		if(this.noSuspend)
			return
		
		this.noSuspend := true
		Hotkey, !#x, Off
	}
	;---------
	; DESCRIPTION:    Respect the common suspend hotkey (!#x).
	; SIDE EFFECTS:   Actually turns the hotkey on.
	;---------
	noSuspendOff() {
		if(!this.noSuspend)
			return
		
		this.noSuspend := false
		Hotkey, !#x, On
	}
	
	;---------
	; DESCRIPTION:    Add a function that will be called on exit using the "normal" (non-emergency) exit hotkey.
	; PARAMETERS:
	;  funcObject (I,REQ) - Function object (created with Func(), Func().Bind(), ObjBindMethod(), etc.) to call on exit.
	;---------
	setExitFunc(funcObject) {
		this.exitFunc := funcObject
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	static scriptType         := "" ; Type of script, from .ScriptType_* constants
	static confirmExit        := false ; Whether to confirm before exiting
	static confirmExitMessage := "Are you sure you want to exit this script?" ; Message to show when confirming an exit based on .confirmExit
	static noSuspend          := false ; Whether the suspend hotkey is suppressed
	static suspendTimerLabel  := "" ; The name of a label for which the timer should be turned off when the script is suspended.
	static exitFunc           := "" ; A BoundFunc object to call when exiting using exit using normal (non-emergency) hotkey.
	
	; Wrappers for whether we're a particular script type.
	isMain() {
		return (this.scriptType = this.ScriptType_Main)
	}
	isSub() {
		return (this.scriptType = this.ScriptType_Sub)
	}
	isStandalone() {
		return (this.scriptType = this.ScriptType_Standalone)
	}
	
	;---------
	; DESCRIPTION:    Apply the basic "set" of hotkeys matching the script's type.
	;---------
	applyHotkeys() {
		; Exit
		Hotkey, ~^!+#r, CommonHotkeys_doEmergencyExit
		if(this.isStandalone())
			Hotkey, !+x, CommonHotkeys_doExit
		if(this.isMain()) {
			; Block close hotkey (as it does bad things in some places) if there are no standalone scripts running
			noStandaloneScriptsRunning := ObjBindMethod(this, "noStandaloneScriptsRunning")
			Hotkey, If, % noStandaloneScriptsRunning
			Hotkey, !+x, CommonHotkeys_doBlock ; Catch exit hotkey in main so it doesn't bleed through when there are no standalone scripts
			Hotkey, If ; Clear condition
		}
		
		; Suspend (on by default, can be disabled/re-enabled with .NoSuspend)
		if(this.isMain())
			Hotkey, !#x, CommonHotkeys_doToggleSuspend ; Main script catches it to prevent it falling through
		if(this.isSub() || this.isStandalone())
			Hotkey, ~!#x, CommonHotkeys_doToggleSuspend ; Other scripts let it fall through so all other scripts can react
		
		; Reload
		if(this.isMain()) {
			; This one has to use ObjBindMethod so that we 
			reloadMethod := ObjBindMethod(this, "doReload", true) ; this.doReload(true)
			Hotkey, !+r, % reloadMethod ; Main only, it replaces the sub scripts by running them again.
		}
		if(this.isStandalone()) {
			; Reload on save if editing the script in question
			isEditingThisScript := ObjBindMethod(this, "isEditingThisScript")
			Hotkey, If, % isEditingThisScript
			Hotkey, ~^s, CommonHotkeys_doReload
			Hotkey, If ; Clear condition
		}
	}
	
	;---------
	; DESCRIPTION:    Helper function used to "block" a hotkey from falling through. Generally used
	;                 by the main script to prevent certain hotkeys used by standalone scripts
	;                 from falling through, if there are no standalone scripts running.
	;---------
	doBlock() {
		return
	}
	
	;---------
	; DESCRIPTION:    Exit the script immediately, doing no additional checks.
	;---------
	doEmergencyExit() {
		ExitApp
	}
	
	;---------
	; DESCRIPTION:    Exit the script, confirming with the user if the ConfirmExit flag is set to true.
	;---------
	doExit() {
		; Confirm exiting if that's turned on.
		if(this.confirmExit) {
			if(!GuiLib.showConfirmationPopup(this.confirmExitMessage))
				return
		}
		
		if(this.exitFunc)
			this.exitFunc.call()
		
		ExitApp
	}
	
	;---------
	; DESCRIPTION:    Reload the script.
	;---------
	doReload(isMain := false) {
		if(isMain)
			HotkeyLib.releaseAllModifiers()
		
		Reload
	}
	
	;---------
	; DESCRIPTION:    Suspend the script, updating the tray icon, pausing a timer with a special name
	;                 and calling pre-suspend/post-unsuspend hooks.
	; NOTES:          - Any timers for the label named in this.suspendTimerLabel will be disabled on suspend and re-enabled on unsuspend.
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
		ScriptTrayInfo.updateTrayIcon()
		
		; Timers
		if(IsLabel(this.suspendTimerLabel))
			SetTimer, % this.suspendTimerLabel, % A_IsSuspended ? "Off" : "On"
		
		; Post-unsuspend hook (implemented by calling script)
		if(!A_IsSuspended) { ; Just unsuspended
			afterUnsuspendFunction := "afterUnsuspend"
			if(isFunc(afterUnsuspendFunction))
				%afterUnsuspendFunction%()
		}
	}
	
	;---------
	; DESCRIPTION:    Check whether we're currently editing the current script in Notepad++.
	; RETURNS:        true if the script is currently open in an active Notepad++ window,
	;                 false otherwise.
	;---------
	isEditingThisScript() {
		if(!Config.isWindowActive("VSCode"))
			return false
		
		return WinGetActiveTitle().startsWith("AHK - " A_ScriptFullPath)
	}
	
	;---------
	; DESCRIPTION:    Check whether there are any standalone (or test) scripts running.
	; RETURNS:        true if there are no standalone/test scripts running, false if there are.
	;---------
	noStandaloneScriptsRunning() {
		settings := new TempSettings().detectHiddenWindows("On")
		
		standaloneWinId := WinExist(WindowLib.buildTitleString("", "AutoHotkey", Config.path["AHK_ROOT"] "\source\standalone\"))
		testWinId       := WinExist(WindowLib.buildTitleString("", "AutoHotkey", Config.path["AHK_TEST"] "\"))
		
		settings.restore()
		; Debug.popup("standaloneWinId",standaloneWinId, "testWinId",testWinId, "(standaloneWinId || testWinId)",(standaloneWinId || testWinId))
		return !(standaloneWinId || testWinId)
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}

;region Wrappers for CommonHotkeys.* functions
; These exist so we can point hotkeys to them directly.
; We can technically point to the CommonHotkeys.* functions directly using ObjBindMethod(), but that
; doesn't work with Suspend, Permit (to allow the hotkey to work when the script is suspended). Some
; of these require that functionality, so they're all out here for consistency's sake.
CommonHotkeys_doEmergencyExit() {
	Suspend, Permit
	CommonHotkeys.doEmergencyExit()
}
CommonHotkeys_doBlock() {
	CommonHotkeys.doBlock()
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
;endregion Wrappers for CommonHotkeys.* functions
