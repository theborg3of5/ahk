﻿#NoEnv                                        ; Don't use environment (OS-level) variables.
#SingleInstance, Force                        ; Running this script while it's already running just replaces the existing instance.
#Warn All                                     ; Show warnings, except for:
#Warn UseUnsetLocal, Off                      ; 	Using local variables before they're set (using default values in a function triggers this)
#Warn UseUnsetGlobal, Off                     ; 	Using global variables before they're set
#LTrim                                        ; Trim whitespace from left of continuation sections (so they can be indented as I wish).
#Hotstring *                                  ; Default option: hotstrings do not require an ending character. Use *0 to turn it off for hotstrings that as needed.

#Include <includeCommon>
ScriptTrayInfo.Init("AHK: Main Script", "shellGreen.ico", "shellRed.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Main)

SendMode, Input                              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir%                 ; Ensures a consistent starting directory.
DetectHiddenWindows, On                      ; Do search hidden windows
SetTitleMatchMode, % TitleMatchMode.Contains ; Match text anywhere inside window titles
SetCapsLockState,   AlwaysOff                ; Turn off Caps Lock so it can be used as a hotkey.
SetScrollLockState, AlwaysOff                ; Turn off Scroll Lock so it can be used as a hotkey.
SetNumLockState,    AlwaysOn                 ; Force NumLock to always stay on.
SetDefaultMouseSpeed, 0                      ; Fasted mouse speed for mouse commands (MouseMove in particular)
SetMouseDelay, 0                             ; Smallest possible delay after mouse movements/clicks
FileEncoding, UTF-8-Raw                      ; Read files using UTF-8 encoding by default, but don't add a mark at the start of saved files to that effect.

; Sub scripts. Must be first to execute so they can spin off and be on their own.
subFolder := A_ScriptDir "\sub\"
Run(subFolder "vimBindings\vimBindings.ahk")
Run(subFolder "windowMoverSizer\windowMoverSizer.ahk")
if(Config.contextIsWork) { ; Work-specific subs
	Run(subFolder "dlgNumTracker\dlgNumTracker.ahk")
	if(Config.machineIsWorkLaptop)
		Run(subFolder "killUAC\killUAC.ahk")
}

; Include other scripts
#Include %A_ScriptDir%\general\ ; General hotkeys.
#Include epic.ahk
#Include hotstrings.ahk ; Must go after startup, but before hotkeys begin.
#Include media.ahk
#Include places.ahk
#Include programs.ahk
#Include selection.ahk
#Include system.ahk
#Include text.ahk
#Include window.ahk

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
#Include greenshot.ahk
#Include hyperspace.ahk
#Include internetExplorer.ahk
#Include kdiff.ahk
#Include launchy.ahk
#Include notepadPlusPlus.ahk
#Include onenote.ahk
#Include onetastic.ahk
#Include outlook.ahk
#Include powerpoint.ahk
#Include putty.ahk
#Include remoteDesktop.ahk
#Include snapper.ahk
#Include spotify.ahk
#Include sumatraPDF.ahk
#Include teams.ahk
#Include telegram.ahk
#Include tortoise.ahk
#Include vb6.ahk
#Include visualStudio.ahk
#Include wilma.ahk
#Include word.ahk
#Include yEd.ahk
#Include zoom.ahk

; Before/after suspend hooks to allow *Lock keys to be hotkeys or ignored while script is active,
; but back to normal when script is suspended.
beforeSuspend() {
	SetCapsLockState,   Off
	SetScrollLockState, Off
	SetNumLockState,    On
}
afterUnsuspend() {
	SetCapsLockState,   AlwaysOff
	SetScrollLockState, AlwaysOff
	SetNumLockState,    AlwaysOn
}
