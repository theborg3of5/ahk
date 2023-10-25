; Send a specific media key, to be executed by external program (like Microsoft keyboard special keys).

#Include <includeCommon>
#NoTrayIcon

inputKeys = %1% ; Input from command line
if(!inputKeys)
	ExitApp

For _,key in inputKeys.split(",")
	Send, {%key%}

ExitApp
