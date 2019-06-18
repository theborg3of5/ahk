; Hotkeys to run/activate various programs.

#e::  MainConfig.activateProgram("Explorer")
#s::  MainConfig.runProgram("Spotify") ; Can't unminimize from tray with any reasonable logic, so re-run to do so.
#f::  MainConfig.activateProgram("Everything")
#t::  MainConfig.runProgram("Telegram")
!+g:: MainConfig.activateProgram("GitHub")
!`::  MainConfig.activateProgram("Process Explorer")
^+!g::MainConfig.activateProgram("Chrome")
^+!n::MainConfig.activateProgram("Notepad++")
^+!o::MainConfig.activateProgram("OneNote")
^+!x::MainConfig.activateProgram("Launchy")
^+!y::MainConfig.activateProgram("YEd")
^!#f::MainConfig.runProgram("Firefox Portable")
^!#n::MainConfig.runProgram("Notepad")
^!#/::MainConfig.activateProgram("AutoHotkey WinSpy")

#If MainConfig.machineIsEpicLaptop
	^+!e::MainConfig.activateProgram("EMC2")
	^+!s::MainConfig.activateProgram("EpicStudio")
	^+!u::MainConfig.activateProgram("Thunder")
	^+!v::MainConfig.runProgram("VB6")
	^!#e::MainConfig.activateProgram("Outlook")
	^!#v::MainConfig.activateProgram("Visual Studio")
#If
