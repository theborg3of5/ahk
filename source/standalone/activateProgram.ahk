; Activate (or run if not already open) a specific program, to be executed by external program (like Microsoft keyboard special keys).
#NoTrayIcon
#Include <includeCommon>

progName = %1% ; Input from command line
if(!progName)
	ExitApp
	
MainConfig.activateProgram(progName)

ExitApp
