; Send a specific media key, to be executed by external program (like Microsoft keyboard special keys).
#NoTrayIcon

inputKey = %1% ; Input from command line
if(!inputKey)
	ExitApp

Send, {%inputKey%}
