; Hotkeys to run/activate various programs.

#s::       runProgram("Spotify") ; Can't unminimize from tray with any reasonable logic, so re-run to do so.
#f::  activateProgram("Everything")
#t::       runProgram("Telegram")
!+g:: activateProgram("GitHub")
!`::  activateProgram("ProcessExplorer")
^+!g::activateProgram("Chrome")
^+!n::activateProgram("Notepad++")
^+!o::activateProgram("OneNote")
^+!x::activateProgram("Launchy")
^+!y::activateProgram("yEd")
^!#f::     runProgram("FirefoxPortable")
^!#n::     runProgram("Notepad")
^!#z::activateProgram("FileZilla")
^!#/::activateProgram("WinSpy")

#If MainConfig.isMachine(MACHINE_EpicLaptop)
	^+!e::activateProgram("EMC2")
	^+!s::activateProgram("EpicStudio")
	^+!u::activateProgram("Thunder")
	^+!v::     runProgram("VB6")
	^!#e::activateProgram("Outlook")
	^!#v::activateProgram("VisualStudio")
#If
