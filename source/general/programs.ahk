; Hotkeys to run/activate various programs.

!`::  Config.activateProgram("Process Explorer")
#e::  Config.activateProgram("Explorer", Explorer.ThisPCFolderUUID) ; Start up at "This PC" folder if we have to run it.
#m::  Config.activateProgram("Chrome Messages", "--profile-directory=Default --app-id=hpfldicfbfomlpcikngkocigghgafkph")
#s::  Config.runProgram("Slack")
^!+g::Config.activateProgram("Chrome")
^!+m::Config.activateProgram("Messenger")
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
	^!#t::Config.runProgram("Teams")
#If

; Some programs are only available on specific machines
#If Config.machineIsHomeDesktop
	^!+s::Config.runProgram("Slack")
	^!#f::
		; Safety check for VPN
		if(Config.doesWindowExist("Cisco AnyConnect VPN")) {
			MsgBox, VPN running!
			return
		}
		Config.runProgram("Firefox Portable")
	return
#If Config.machineIsHomeDesktop || Config.machineIsWorkLaptop || Config.machineIsHomeLaptop
	#f::  Config.activateProgram("Everything")
	#t::  Config.runProgram("Telegram")
	!+g:: Config.activateProgram("GitHub Desktop")
	^!+o::Config.activateProgram("OneNote")
	^!+x::Config.activateProgram("Launchy")
#If Config.machineIsWorkLaptop
	^!+u::Config.activateProgram("Thunder")
	^!#e::Config.activateProgram("Outlook")
#If
