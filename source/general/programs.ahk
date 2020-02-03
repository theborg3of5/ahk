; Hotkeys to run/activate various programs.

#e::  Config.activateProgram("Explorer", Explorer.ThisPCFolderUUID) ; Start up at "This PC" folder if we have to run it.
!`::  Config.activateProgram("Process Explorer")
^!+g::Config.activateProgram("Chrome")
^!+n::Config.activateProgram("Notepad++")
^!#n::Config.runProgram("Notepad")
^!#/::Config.activateProgram("AutoHotkey WinSpy")

; Some programs are work-specific
#If Config.contextIsWork
	^!+e::Config.activateProgram("EMC2", "EMC2Update env=TRACKAPPTCP") ; EMC2 needs these parameters to start up correctly.
	^!+s::Config.activateProgram("EpicStudio")
	^!+v::Config.runProgram("VB6")
	^!+y::Config.activateProgram("yEd")
	^!#v::Config.runProgram("Visual Studio")
#If

; Some programs are only available on specific machines
#If Config.machineIsHomeDesktop
	^!+s::Config.runProgram("Slack")
	^!#f::Config.runProgram("Firefox Portable")
#If Config.machineIsHomeDesktop || Config.machineIsWorkLaptop || Config.machineIsHomeLaptop
	#s::  Config.runProgram("Spotify") ; Can't unminimize from tray with any reasonable logic, so re-run to do so.
	#f::  Config.activateProgram("Everything")
	#t::  Config.runProgram("Telegram")
	!+g:: Config.activateProgram("GitHub")
	^!+o::Config.activateProgram("OneNote")
	^!+x::Config.activateProgram("Launchy")
#If Config.machineIsWorkLaptop
	^!+u::Config.activateProgram("Thunder")
	^!#e::Config.activateProgram("Outlook")
#If
