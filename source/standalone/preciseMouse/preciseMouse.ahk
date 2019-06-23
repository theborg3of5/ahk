/* GDB TODO
	Lock the mouse?
		Until exit?
		Until click?
		Not at all?
	Arrow keys to move cursor
	Maybe modifier keys for bigger jumps, jump to other side of screen, etc.
*/

#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#Include <includeCommon>
setCommonHotkeysType(HOTKEY_TYPE_Standalone)
; setUpTrayIcons("controllerGreen.ico", "controllerRed.ico", "AHK: Controller Emulator")


#Include <commonHotkeys>
