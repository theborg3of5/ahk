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
	static Init(scriptType) {
		this.scriptType := scriptType
		
		this.applyHotkeys()
	}
	
	;---------
	; DESCRIPTION:    A function reference for a timer that should be paused when the script is
	;                 suspended and resumed when unsuspended.
	; PARAMETERS:
	;  newFunc (I,REQ) - The function reference used with SetTimer.
	;---------
	static setSuspendTimerFunc(newFunc) {
		this.suspendTimerFunc := newFunc
	}
	
	;---------
	; DESCRIPTION:    Prompt the user to confirm when exiting with the common exit hotkey (!+x).
	;---------
	static confirmExitOn(message := "") {
		this.confirmExit := true
		if message != ""
			this.confirmExitMessage := message
	}
	;---------
	; DESCRIPTION:    Do not prompt the user to confirm when exiting with the common exit hotkey (!+x).
	;---------
	static confirmExitOff() {
		this.confirmExit := false
	}
	
	;---------
	; DESCRIPTION:    Ignore the common suspend hotkey (!#x).
	; SIDE EFFECTS:   Actually turns the hotkey off.
	;---------
	static noSuspendOn() {
		if this.noSuspend
			return

		this.noSuspend := true
		Hotkey("!#x", "Off")
	}
	;---------
	; DESCRIPTION:    Respect the common suspend hotkey (!#x).
	; SIDE EFFECTS:   Actually turns the hotkey on.
	;---------
	static noSuspendOff() {
		if !this.noSuspend
			return

		this.noSuspend := false
		Hotkey("!#x", "On")
	}
	
	;---------
	; DESCRIPTION:    Add a function that will be called on exit using the "normal" (non-emergency) exit hotkey.
	; PARAMETERS:
	;  funcObject (I,REQ) - Function object (created with Func(), Func().Bind(), ObjBindMethod(), etc.) to call on exit.
	;---------
	static setExitFunc(funcObject) {
		this.exitFunc := funcObject
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	static scriptType         := "" ; Type of script, from .ScriptType_* constants
	static confirmExit        := false ; Whether to confirm before exiting
	static confirmExitMessage := "Are you sure you want to exit this script?" ; Message to show when confirming an exit based on .confirmExit
	static noSuspend          := false ; Whether the suspend hotkey is suppressed
	static suspendTimerFunc   := "" ; A function reference for which the timer should be turned off when the script is suspended.
	static exitFunc           := "" ; A function object to call when exiting using normal (non-emergency) hotkey.
	static beforeSuspendFunc  := "" ; Hook called before suspending. Set by calling script.
	static afterUnsuspendFunc := "" ; Hook called after unsuspending. Set by calling script.
	
	static isMain() {
		return (this.scriptType = this.ScriptType_Main)
	}
	static isSub() {
		return (this.scriptType = this.ScriptType_Sub)
	}
	static isStandalone() {
		return (this.scriptType = this.ScriptType_Standalone)
	}
	
	;---------
	; DESCRIPTION:    Apply the basic "set" of hotkeys matching the script's type.
	;---------
	static applyHotkeys() {
		; Exit (S = suspend-exempt, so emergency exit always works)
		Hotkey("~^!+#r", ObjBindMethod(this, "doEmergencyExit"), "S")
		if this.isStandalone()
			Hotkey("!+x", ObjBindMethod(this, "doExit"))
		if this.isMain() {
			noStandaloneScriptsRunning := ObjBindMethod(this, "noStandaloneScriptsRunning")
			HotIf(noStandaloneScriptsRunning)
			Hotkey("!+x", ObjBindMethod(this, "doBlock"))
			HotIf()
		}

		; Suspend (S = suspend-exempt so toggle works while suspended)
		if this.isMain()
			Hotkey("!#x", ObjBindMethod(this, "doToggleSuspend"), "S")
		if this.isSub() || this.isStandalone()
			Hotkey("~!#x", ObjBindMethod(this, "doToggleSuspend"), "S")

		; Reload
		if this.isMain() {
			reloadMethod := ObjBindMethod(this, "doReload", true)
			Hotkey("!+r", reloadMethod)
		}
		if this.isStandalone() {
			isEditingThisScript := ObjBindMethod(this, "isEditingThisScript")
			HotIf(isEditingThisScript)
			Hotkey("~^s", ObjBindMethod(this, "doReload"))
			HotIf()
		}
	}
	
	;---------
	; DESCRIPTION:    Helper function used to "block" a hotkey from falling through. Generally used
	;                 by the main script to prevent certain hotkeys used by standalone scripts
	;                 from falling through, if there are no standalone scripts running.
	;---------
	static doBlock(*) {
		return
	}
	
	;---------
	; DESCRIPTION:    Exit the script immediately, doing no additional checks.
	;---------
	static doEmergencyExit(*) {
		ExitApp()
	}
	
	;---------
	; DESCRIPTION:    Exit the script, confirming with the user if the ConfirmExit flag is set to true.
	;---------
	static doExit(*) {
		if this.confirmExit {
			if !GuiLib.showConfirmationPopup(this.confirmExitMessage)
				return
		}

		if this.exitFunc
			this.exitFunc.Call()

		ExitApp()
	}
	
	;---------
	; DESCRIPTION:    Reload the script.
	;---------
	static doReload(isMain := false, *) {
		if isMain
			HotkeyLib.releaseAllModifiers()

		Reload()
	}
	
	;---------
	; DESCRIPTION:    Suspend the script, updating the tray icon, pausing a timer with a special name
	;                 and calling pre-suspend/post-unsuspend hooks.
	; NOTES:          - Any timers for the label named in this.suspendTimerLabel will be disabled on suspend and re-enabled on unsuspend.
	;                 - If a function named "beforeSuspend" exists, we will call it before we suspend the script.
	;                 - If a function named "afterUnsuspend" exists, we will call it after we unsuspend the script.
	;---------
	static doToggleSuspend(*) {
		; Pre-suspend hook (implemented by calling script)
		if !A_IsSuspended { ; Not suspended, so about to be
			if this.beforeSuspendFunc
				this.beforeSuspendFunc.Call()
		}

		Suspend(-1) ; Toggle
		ScriptTrayInfo.updateTrayIcon()

		; Timers
		if this.suspendTimerFunc
			SetTimer(this.suspendTimerFunc, A_IsSuspended ? 0 : 1000)

		; Post-unsuspend hook (implemented by calling script)
		if !A_IsSuspended { ; Just unsuspended
			if this.afterUnsuspendFunc
				this.afterUnsuspendFunc.Call()
		}
	}
	
	;---------
	; DESCRIPTION:    Check whether we're currently editing the current script in Notepad++.
	; RETURNS:        true if the script is currently open in an active Notepad++ window,
	;                 false otherwise.
	;---------
	static isEditingThisScript(*) {
		if !Config.isWindowActive("VSCode")
			return false

		return WinGetTitle("A").startsWith("AHK - " A_ScriptFullPath)
	}
	
	;---------
	; DESCRIPTION:    Check whether there are any standalone (or test) scripts running.
	; RETURNS:        true if there are no standalone/test scripts running, false if there are.
	;---------
	static noStandaloneScriptsRunning(*) {
		settings := TempSettings().detectHiddenWindows("On")

		standaloneWinId := WinExist(WindowLib.buildTitleString("", "AutoHotkey", Config.path["AHK_ROOT"] "\source\standalone\"))
		testWinId       := WinExist(WindowLib.buildTitleString("", "AutoHotkey", Config.path["AHK_TEST"] "\"))

		settings.restore()
		return !(standaloneWinId || testWinId)
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
