; Hotkeys to run/activate various programs.

!`::  Config.runProgram("Process Explorer")
#b::  Config.runProgram("Beeper")
#e::  Config.activateProgram("Explorer", Explorer.ThisPCFolderUUID) ; Start up at "This PC" folder if we have to run it.
#s::  Config.runProgram("Slack")
^!+g::Config.activateProgram("Chrome")
^!+n::Config.activateProgram("Notepad++")
^!+t::Config.activateProgram("TickTick")
^!#m::Config.activateProgram("Chrome Messages")
^!#n::Config.runProgram("Notepad")
^!#t::Config.runProgram("Teams")
^!#v::Config.activateProgram("VSCode", "--profile Default")
^!#/::Config.activateProgram("AutoHotkey WinSpy")

; Some programs are work-specific
#If Config.contextIsWork
	^!+e:: Config.activateProgram("EMC2", "EMC2Update env=TRACKAPPTCP") ; EMC2 needs these parameters to start up correctly.
	^!+s:: Config.activateProgram("EpicStudio")
	^!+u:: Config.activateProgram("Thunder")
	^!#+v::Config.runProgram("VB6")
#If

; Some programs are only available on specific machines
#If Config.machineIsHomeDesktop
	^!#f::
		; Safety check for VPN
		if(Config.doesWindowExist("Cisco AnyConnect VPN")) {
			MsgBox, VPN running!
			return
		}
		Config.runProgram("Firefox Portable")
	return
#If Config.machineIsHomeDesktop || Config.machineIsWorkDesktop || Config.machineIsHomeLaptop
	#f::  Config.activateProgram("Everything")
	#t::  Config.runProgram("Telegram")
	^!+o::Config.activateProgram("OneNote")
	^!#g::Config.activateProgram("GitHub Desktop")
#If Config.machineIsWorkDesktop
	^!#e::Config.activateProgram("Outlook")
#If
