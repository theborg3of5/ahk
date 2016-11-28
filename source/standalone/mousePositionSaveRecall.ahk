#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance force
;#NoTrayIcon

CoordMode,Mouse,Relative
Loop, 9
  Hotkey, ^+%A_Index%, StoreSub  ; get mouse position.
Loop, 9
  Hotkey, ^%A_Index%, UseSub     ; move to prestored position.
Return

StoreSub:
Num := SubStr(A_ThisHotkey, 0, 1)
MouseGetPos, Var_%Num%_X, Var_%Num%_Y
Return

UseSub:
Num := SubStr(A_ThisHotkey, 0, 1)
MouseMove, Var_%Num%_X, Var_%Num%_Y
Return

~+!x::ExitApp			;Shift+Alt+X = Emergency Exit
~!+r::Reload			;Shift+Alt+R = Reload