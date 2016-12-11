#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance force
; #NoTrayIcon

#Include <autoInclude>

; Mute the remote computer (this one)'s volume.
startMuteState := VA_GetMasterMute()
VA_SetMasterMute(1)

; Switch vimkeys config to use F8/F9 instead of F6 (different keyboard).
startVimCloseKey := MainConfig.getSetting("VIM_CLOSE_KEY")
MainConfig.setSetting("VIM_CLOSE_KEY", ["F8", "F9"], true)


; Restore settings and exit.
^+x::
	VA_SetMasterMute(startMuteState)
	MainConfig.setSetting("VIM_CLOSE_KEY", startVimCloseKey, true)
	
	ExitApp
return
