#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
; #NoTrayIcon
#SingleInstance force
; #Warn All


#Include <autoInclude>

commandLineArg = %1%
if(commandLineArg) {
	differences := gitZipUnzip(commandLineArg)
	if(differences.maxIndex() && (commandLineArg = "s"))
		DEBUG.popup("AHK zipfiles that have changed", differences)
	
	ExitApp
}

^+s::
	differences := gitZipUnzip("s")
	; if(differences.maxIndex())
		; DEBUG.popup("AHK zipfiles that have changed", differences)
	
	ExitApp
return

^z::
	gitZipUnzip("z")
	ExitApp
return

^u::
	gitZipUnzip("u")
	ExitApp
return

~!+x::ExitApp
