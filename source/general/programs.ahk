; Hotkeys to run/activate various programs.

#e::  MainConfig.activateProgram("Explorer", Explorer.ThisPCFolderUUID) ; Start up at "This PC" folder if we have to run it.
!`::  MainConfig.activateProgram("Process Explorer")
^+!g::MainConfig.activateProgram("Chrome")
^+!n::MainConfig.activateProgram("Notepad++")
^!#n::MainConfig.runProgram("Notepad")
^!#/::MainConfig.activateProgram("AutoHotkey WinSpy")

; Some programs are work-specific
#If MainConfig.contextIsWork
	^+!e::MainConfig.activateProgram("EMC2", "EMC2Update env=TRACKAPPTCP") ; EMC2 needs these parameters to start up correctly.
	^+!s::MainConfig.activateProgram("EpicStudio")
	^+!v::MainConfig.runProgram("VB6")
	^+!y::MainConfig.activateProgram("yEd")
	^!#v::MainConfig.activateProgram("Visual Studio")
#If

; Some programs are only available on specific machines
#If MainConfig.machineIsHomeDesktop
	^!#f::MainConfig.runProgram("Firefox Portable")
#If MainConfig.machineIsHomeDesktop || MainConfig.machineIsEpicLaptop
	#s::  MainConfig.runProgram("Spotify") ; Can't unminimize from tray with any reasonable logic, so re-run to do so.
	#f::  MainConfig.activateProgram("Everything")
	#t::  MainConfig.runProgram("Telegram")
	!+g:: MainConfig.activateProgram("GitHub")
	^+!o::MainConfig.activateProgram("OneNote")
	^+!x::MainConfig.activateProgram("Launchy")
#If MainConfig.machineIsEpicLaptop
	^+!u::MainConfig.activateProgram("Thunder")
	^!#e::MainConfig.activateProgram("Outlook")
#If
