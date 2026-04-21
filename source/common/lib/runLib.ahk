; Utility functions for running scripts, commands, and other programs.

class RunLib {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Run a command with cmd.exe.
	; PARAMETERS:
	;  commandToRun     (I,REQ) - The command to run.
	;  workingDirectory (I,OPT) - The working directory to run the command in.
	;  stayOpen         (I,OPT) - Set to true if you want the window to stay open after the command has run.
	;---------
	static runCommand(commandToRun, workingDirectory := "", stayOpen := false) {
		if stayOpen
			runString := A_ComSpec " /K " commandToRun
		else
			runString := A_ComSpec " /C " commandToRun
		
		; Debug.popup("Command string", commandToRun, "Run string", runString)
		Run(runString, workingDirectory)
	}

	;---------
	; DESCRIPTION:    Run the given command and return the output.
	; PARAMETERS:
	;  command (I,REQ) - Command to run.
	; RETURNS:        The output from the command, as passed to standard out.
	;---------
	static runReturn(command) {
		fullCommand := A_ComSpec . ' /c "' . command . '"'
		shell := ComObject("wscript.shell")
		exec := shell.exec(fullCommand)
		stdout := exec.stdout.readall()
		return stdout
	}

	;---------
	; DESCRIPTION:    Check if the current script is running as admin, and re-run it as admin if not.
	;                 Adapted from https://www.autohotkey.com/docs/v1/lib/Run.htm#RunAs
	;---------
	static forceCurrScriptAdmin() {
		runString := DllCall("GetCommandLine", "str")

		if A_IsAdmin
			return

		if RegExMatch(runString, " /restart(?!\S)")
			return

		try {
			if A_IsCompiled
				Run('*RunAs "' A_ScriptFullPath '" /restart')
			else
				Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"')
		}

		ExitApp()
	}
	;endregion ------------------------------ PUBLIC ------------------------------
}