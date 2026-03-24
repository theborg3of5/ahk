; Activate (or run if not already open) a specific program, to be executed by external program (like Microsoft keyboard special keys).

#Include <includeCommon>

progName := A_Args.RemoveAt(1) ; Argument 1: program name
; Remaining arguments: to be passed to the program we're running (loop in case there are spaces,
;  which split up into multiple arguments here)
Loop, % A_Args.Length() {
	progArgs := progArgs.appendPiece(" ", A_Args[A_Index])
}

progName = %1% ; Input from command line
if(!progName)
	ExitApp
	
Config.runProgram(progName, progArgs)

ExitApp
