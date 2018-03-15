#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
DetectHiddenWindows, On
; #Warn All
#Include <includeCommon>
scriptHotkeyType := HOTKEY_TYPE_Master
setUpTrayIcons("shellGreen.ico", "shellRed.ico")

; Turn off caps lock and scroll lock (mainly so we can use them as hotkeys) and force num lock to stay on.
SetCapsLockState,   AlwaysOff
SetScrollLockState, AlwaysOff
SetNumLockState,    AlwaysOn

; Standalone scripts. Must be first to execute so they can spin off and be on their own.
runStandaloneScripts()

; === Include other scripts ===
#Include %A_ScriptDir%\general\ ; General hotkeys.
#Include hotstrings.ahk ; Must go after startup, but before hotkeys begin.
#Include input.ahk
#Include kdeMoverSizer.ahk
#Include launch.ahk
#Include screen.ahk
#Include volume.ahk

#Include %A_ScriptDir%\program\ ; Program-specific hotkeys.
#Include chrome.ahk
#Include ciscoAnyConnect.ahk
#Include ditto.ahk
#Include emc2.ahk
#Include epicStudio.ahk
#Include excel.ahk
#Include explorer.ahk
#Include fastStoneImageViewer.ahk
#Include games.ahk
#Include githubDesktop.ahk
#Include hyperspace.ahk
#Include kdiff.ahk
#Include launchy.ahk
#Include notepad++.ahk
#Include onenote.ahk
#Include outlook.ahk
#Include oxygenXML.ahk
#Include pidgin.ahk
#Include powerpoint.ahk
#Include putty.ahk
#Include remoteDesktop.ahk
#Include skype.ahk
#Include snapper.ahk
#Include spotify.ahk
#Include sumatraPDF.ahk
#Include vb6.ahk
#Include wilma.ahk
#Include word.ahk
#Include yEd.ahk

#Include <commonHotkeys> ; Common hotkeys - should last so it overrides anything else.

runStandaloneScripts() {
	standaloneFolder := A_ScriptDir "\standalone\"
	Run, % standaloneFolder "vimBindings\vimBindings.ahk"
	if(MainConfig.isMachine(MACHINE_EpicLaptop)) { ; Not needed except on Epic machine.
		Run, % standaloneFolder "killUAC.ahk"
		Run, % standaloneFolder "tortoiseFillerDLG\tortoiseFillerDLG.ahk"
		Run, % standaloneFolder "dlgNumTracker\dlgNumTracker.ahk"
	} else if(MainConfig.isMachine(MACHINE_HomeDesktop)) {
		Run, % standaloneFolder "psxEmulatorController\psxEmulatorController.ahk"
	}
}