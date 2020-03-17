#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
ScriptTrayInfo.Init("AHK: Kill UAC", "shieldGreen.ico", "shieldRed.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Sub)

disableUserAccountControl() ; Do it once immediately.
SetTimer, MainLoop, 1800000 ; 30m, timer toggled by CommonHotkeys' suspend hotkey.
return

MainLoop:
	disableUserAccountControl()
return

disableUserAccountControl() {
	RegWrite, REG_DWORD, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System, EnableLUA, 0x00000000
}
