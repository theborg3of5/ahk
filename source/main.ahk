#NoEnv                                        ; Don't use environment (OS-level) variables.
#SingleInstance, Force                        ; Running this script while it's already running just replaces the existing instance.
#Warn All                                     ; Show warnings, except for:
#Warn UseUnsetLocal, Off                      ; 	Using local variables before they're set (using default values in a function triggers this)
#Warn UseUnsetGlobal, Off                     ; 	Using global variables before they're set
#LTrim                                        ; Trim whitespace from left of continuation sections (so they can be indented as I wish).
#Hotstring *                                  ; Default option: hotstrings do not require an ending character. Use *0 to turn it off for hotstrings that as needed.
#Include <includeCommon>

SendMode, Input                               ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir%                  ; Ensures a consistent starting directory.
DetectHiddenWindows, On                       ; Do search hidden windows
SetTitleMatchMode, % TITLE_MATCH_MODE_Contain ; Match text anywhere inside window titles
SetCapsLockState,   AlwaysOff                 ; Turn off Caps Lock so it can be used as a hotkey.
SetScrollLockState, AlwaysOff                 ; Turn off Scroll Lock so it can be used as a hotkey.
SetNumLockState,    AlwaysOn                  ; Force NumLock to always stay on.
SetDefaultMouseSpeed, 0 ; Fasted mouse speed for mouse commands (MouseMove in particular)
SetMouseDelay, 0 ; Smallest possible delay after mouse movements/clicks


setCommonHotkeysType(HOTKEY_TYPE_Master)
setUpTrayIcons("shellGreen.ico", "shellRed.ico", "AHK: Main Script")


; Standalone scripts. Must be first to execute so they can spin off and be on their own.
runStandaloneScripts()

; === Include other scripts ===
#Include %A_ScriptDir%\general\ ; General hotkeys.
#Include hotstrings.ahk ; Must go after startup, but before hotkeys begin.
#Include input.ahk
#Include launch.ahk
#Include media.ahk
#Include places.ahk
#Include programs.ahk
#Include screen.ahk

#Include %A_ScriptDir%\program\ ; Program-specific hotkeys.
#Include chrome.ahk
#Include ciscoAnyConnect.ahk
#Include ditto.ahk
#Include emc2.ahk
#Include epicStudio.ahk
#Include everything.ahk
#Include excel.ahk
#Include explorer.ahk
#Include fastStoneImageViewer.ahk
#Include games.ahk
#Include greenshot.ahk
#Include hyperspace.ahk
#Include internetExplorer.ahk
#Include kdiff.ahk
#Include launchy.ahk
#Include mattermost.ahk
#Include notepad++.ahk
#Include onenote.ahk
#Include onetastic.ahk
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
#Include telegram.ahk
#Include vb6.ahk
#Include wilma.ahk
#Include word.ahk
#Include yEd.ahk

#Include <commonHotkeys> ; Common hotkeys - should last so it overrides anything else.

runStandaloneScripts() {
	standaloneFolder := A_ScriptDir "\standalone\"
	Run(standaloneFolder "vimBindings\vimBindings.ahk")
	Run(standaloneFolder "windowMoverSizer\windowMoverSizer.ahk")
	if(MainConfig.machineIsEpicLaptop) { ; Not needed except on Epic machine.
		Run(standaloneFolder "killUAC\killUAC.ahk")
		Run(standaloneFolder "dlgNumTracker\dlgNumTracker.ahk")
		Run(standaloneFolder "tortoiseFillerDLG\tortoiseFillerDLG.ahk")
	} else if(MainConfig.machineIsHomeDesktop) {
		; Run(standaloneFolder "psxEmulatorController\psxEmulatorController.ahk")
	}
}