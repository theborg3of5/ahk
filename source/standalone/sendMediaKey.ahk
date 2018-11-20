; Send a specific media key, to be executed by external program (like Microsoft keyboard special keys).
#NoTrayIcon
#Include <includeCommon>

inputKey = %1% ; Input from command line
if(!inputKey)
	ExitApp

inputKeyAry := StrSplit(inputKey, ",")

For i,inputKey in inputKeyAry
	sendMediaKey(inputKey)

ExitApp
