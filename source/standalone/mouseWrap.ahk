#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance force
;#NoTrayIcon

T = 2

CoordMode, Mouse, Screen
SetDefaultMouseSpeed, 0
WinGetPos,,,Xtot,Ytot,ahk_class Progman

Xedge := Xtot - T
Yedge := Ytot - T

loop
{
    MouseGetPos, Cx, Cy

    if (Cy < T)
        MouseMove, Cx, Yedge-T

    if (Cy > Yedge)
        MouseMove, Cx, T

    if (Cx < T)
        MouseMove, Xedge-T, Cy

    if (Cx > Xedge)
        MouseMove, T, Cy
}

~+!x::ExitApp			;Shift+Alt+X = Emergency Exit
~!+r::Reload			;Shift+Alt+R = Reload