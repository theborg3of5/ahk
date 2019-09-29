/* Class for applying certain common hotkeys to a script, based on the type of script and certain flags.
	
	Example usage:
		CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone, trayInfo) ; trayInfo is the instance of ScriptTrayInfo defined on some line above this.
*/

class CommonHotkeys {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	; Different "types" of scripts, which get different sets of hotkeys
	static ScriptType_Main       := 1 ; Main script
	static ScriptType_Sub        := 2 ; Standalone scripts that the main script starts and that run alongside the main script
	static ScriptType_Standalone := 3 ; One-off scripts, not connected to main script
	
	;---------
	; DESCRIPTION:    Set up the common hotkeys.
	; PARAMETERS:
	;  scriptType (I,REQ) - The "type" of script, from CommonHotkeys.ScriptType_*. This determines
	;                       which "set" of hotkeys are applied.
	;  trayInfo   (I,OPT) - The script's ScriptTrayInfo instance, used to swich out icons when using
	;                       the suspend hotkey (!#x).
	;---------
	Init(scriptType, trayInfo := "") {
		CommonHotkeys._scriptType := scriptType
		CommonHotkeys._trayInfo   := trayInfo
		
		CommonHotkeys.applyHotkeys()
	}
	
	;---------
	; DESCRIPTION:    Turn on/off whether to prompt the user to confirm when exiting with the common exit hotkey (!+x).
	;---------
	ConfirmExitOn(message := "") {
		CommonHotkeys._confirmExit := true
		if(message != "")
			CommonHotkeys._confirmExitMessage := message
	}
	ConfirmExitOff() {
		CommonHotkeys._confirmExit := false
	}
	
	;---------
	; DESCRIPTION:    Turn on/off whether to ignore the common suspend hotkey (!#x) or not.
	; SIDE EFFECTS:   Will actually turn the hotkey on or off.
	;---------
	NoSuspendOn() {
		if(CommonHotkeys._noSuspend)
			return
		
		CommonHotkeys._noSuspend := true
		Hotkey, !#x, Off
	}
	NoSuspendOff() {
		if(!CommonHotkeys._noSuspend)
			return
		
		CommonHotkeys._noSuspend := false
		Hotkey, !#x, On
	}
	
	;---------
	; DESCRIPTION:    Wrappers for checking which "type" the script is. These correspond to
	;                 CommonHotkeys.ScriptType_*.
	; RETURNS:        true if the script matches the type in question, false otherwise.
	;---------
	IsMain {
		get {
			return (CommonHotkeys._scriptType = CommonHotkeys.ScriptType_Main)
		}
	}
	IsSub {
		get {
			return (CommonHotkeys._scriptType = CommonHotkeys.ScriptType_Sub)
		}
	}
	IsStandalone {
		get {
			return (CommonHotkeys._scriptType = CommonHotkeys.ScriptType_Standalone)
		}
	}
	
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	static _scriptType         := "" ; Type of script, from CommonHotkeys.ScriptType_* constants
	static _trayInfo           := "" ; Reference to the script's ScriptTrayInfo object
	static _confirmExit        := false ; Whether to confirm before exiting
	static _confirmExitMessage := "Are you sure you want to exit this script?" ; Message to show when confirming an exit based on _confirmExit
	static _noSuspend          := false ; Whether the suspend hotkey is suppressed
	
	;---------
	; DESCRIPTION:    Apply the basic "set" of hotkeys matching the script's type.
	;---------
	applyHotkeys() {
		; Exit
		Hotkey, ~^+!#r, CommonHotkeys_doEmergencyExit
		if(CommonHotkeys.IsStandalone)
			Hotkey, !+x, CommonHotkeys_doExit
		if(CommonHotkeys.IsMain) {
			; Block close hotkey (as it does bad things in some places) if there are no standalone scripts running
			noStandaloneScriptsRunning := ObjBindMethod(CommonHotkeys, "noStandaloneScriptsRunning")
			Hotkey, If, % noStandaloneScriptsRunning
			Hotkey, !+x, CommonHotkeys_doBlock ; Catch exit hotkey in main so it doesn't bleed through when there are no standalone scripts
			Hotkey, If ; Clear condition
		}
		
		; Suspend (on by default, can be disabled/re-enabled with CommonHotkeys.NoSuspend)
		if(CommonHotkeys.IsMain)
			Hotkey, !#x, CommonHotkeys_doToggleSuspend ; Main script catches it to prevent it falling through
		if(CommonHotkeys.IsSub || CommonHotkeys.IsStandalone)
			Hotkey, ~!#x, CommonHotkeys_doToggleSuspend ; Other scripts let it fall through so all other scripts can react
		
		; Reload
		if(CommonHotkeys.IsMain)
			Hotkey, !+r, CommonHotkeys_doReload ; Main only, it replaces the sub scripts by running them again.
		if(CommonHotkeys.IsStandalone) {
			; Reload on save if editing the script in question
			isEditingThisScript := ObjBindMethod(CommonHotkeys, "isEditingThisScript")
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
		if(CommonHotkeys._confirmExit) {
			if(!showConfirmationPopup(CommonHotkeys._confirmExitMessage))
				return
		}
		
		ExitApp
	}
	
	;---------
	; DESCRIPTION:    Reload the script.
	;---------
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
	
	;---------
	; DESCRIPTION:    Check whether we're currently editing the current script in Notepad++.
	; RETURNS:        true if the script is currently open in an active Notepad++ window,
	;                 false otherwise.
	;---------
	isEditingThisScript() {
		if(!WinActive("ahk_class Notepad++"))
			return false
		
		return WinGetActiveTitle().contains(A_ScriptFullPath)
	}
	
	;---------
	; DESCRIPTION:    Check whether there are any standalone (or test) scripts running.
	; RETURNS:        true if there are no standalone/test scripts running, false if there are.
	;---------
	noStandaloneScriptsRunning() {
		origDetectSetting := setDetectHiddenWindows("On")
		
		standaloneWinId := WinExist(buildWindowTitleString("AutoHotkey.exe", "AutoHotkey", Config.path["AHK_ROOT"] "\source\standalone\"))
		testWinId       := WinExist(buildWindowTitleString("AutoHotkey.exe", "AutoHotkey", Config.path["AHK_ROOT"] "\test\"))
		
		setDetectHiddenWindows(origDetectSetting)
		; DEBUG.popup("standaloneWinId",standaloneWinId, "testWinId",testWinId, "(standaloneWinId || testWinId)",(standaloneWinId || testWinId))
		return !(standaloneWinId || testWinId)
	}
}

;---------
; DESCRIPTION:    Wrappers for CommonHotkeys.* functions that we can point hotkeys to directly.
; NOTES:          We can technically point to the CommonHotkeys.* functions directly using
;                 ObjBindMethod(), but that doesn't work with Suspend, Permit (to allow the hotkey
;                 to work when the script is suspended). Some of these require that functionality,
;                 so they're all out here for consistency's sake.
;---------
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