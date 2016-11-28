SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance force  ; Ensures that if this script is running, running it again replaces the first instance.
; #NoTrayIcon  ; Uncomment to hide the tray icon.

; Constants
METHOD_NONE				:= 0
METHOD_WASD_ARROWS 	:= 1
METHOD_ARROWS_WASD 	:= 2
DIRECTION_NORMAL 		:= 0
DIRECTION_REVERSE 	:= 1

; Defaults
method 		:= METHOD_WASD_ARROWS
direction 	:= DIRECTION_NORMAL

; Decide on which method:
; 		Arrows -> WASD
; 		WASD -> Arrows

; Decide on which direction:
; 		Normal
; 		Reversed

; Respective mappings
#If (method = METHOD_ARROWS_WASD) && (direction = DIRECTION_NORMAL)
	Up::w
	Left::a
	Down::s
	Right::d
#If
#If (method = METHOD_ARROWS_WASD) && (direction = DIRECTION_REVERSE)
	Up::s
	Left::d
	Down::w
	Right::a
#If
#If (method = METHOD_WASD_ARROWS) && (direction = DIRECTION_NORMAL)
	w::Up
	a::Left
	s::Down
	d::Right
#If
#If (method = METHOD_WASD_ARROWS) && (direction = DIRECTION_REVERSE)
	s::Up
	d::Left
	w::Down
	a::Right
#If






; Exit, reload, and suspend.
~!+x::ExitApp
~#!x::Suspend
^!r::
	Suspend, Permit
	Reload
return