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
	runCommand(commandToRun, workingDirectory := "", stayOpen := false) {
		; Set /C or /K (command and close, or command and stay up) based on input.
		if(stayOpen)
			runString := A_ComSpec " /K " commandToRun
		else
			runString := A_ComSpec " /C " commandToRun
		
		; Debug.popup("Command string", commandToRun, "Run string", runString)
		Run(runString, workingDirectory)
	}

	;---------
	; DESCRIPTION:    Run the given command as a non-elevated user, even if the script is running as admin.
	; PARAMETERS:
	;  cmd  (I,REQ) - The command to run.
	;  args (I,OPT) - Parameters to pass (if this is a filepath to a program).
	;---------
	runAsUser(cmd, args := "") {
		RunLib.shellRun(cmd, args)
	}

	;---------
	; DESCRIPTION:    Run the given command and return the output.
	; PARAMETERS:
	;  command (I,REQ) - Command to run.
	; RETURNS:        The output from the command, as passed to standard out.
	;---------
	runReturn(command) {
		fullCommand := A_ComSpec . " /c """ . command . """"
		shell := comobjcreate("wscript.shell")
		exec := (shell.exec(fullCommand))
		stdout := exec.stdout.readall()
		return stdout
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	/*
		ShellRun by Lexikos
			requires: AutoHotkey_L
			license: http://creativecommons.org/publicdomain/zero/1.0/

		Credit for explaining this method goes to BrandonLive:
		http://brandonlive.com/2008/04/27/getting-the-shell-to-run-an-application-for-you-part-2-how/

		Shell.ShellExecute(File [, Arguments, Directory, Operation, Show])
		http://msdn.microsoft.com/en-us/library/windows/desktop/gg537745

		Function found here:
		https://autohotkey.com/board/topic/108434-run-ahk-as-admin-or-not-dilemma/#entry648428

		Parameters
			1 application to launch
			2 command line parameters
			3 working directory for the new process
			4 "Verb" (For example, pass "RunAs" to run as administrator)
			5 Suggestion to the application about how to show its window - see the msdn link for possible values
	*/
	shellRun(prms*) {
		shellWindows := ComObjCreate("{9BA05972-F6A8-11CF-A442-00A0C90A8F39}")
		
		desktop := shellWindows.Item(ComObj(19, 8)) ; VT_UI4, SCW_DESKTOP
		
		; Retrieve top-level browser object.
		SID_STopLevelBrowser := "{4C96BE40-915C-11CF-99D3-00AA004AE837}"
		IID_IShellBrowser    := "{000214E2-0000-0000-C000-000000000046}"
		
		if(ptlb := ComObjQuery(desktop, SID_STopLevelBrowser, IID_IShellBrowser)) {
			; IShellBrowser.QueryActiveShellView -> IShellView
			if(DllCall(NumGet(NumGet(ptlb + 0) + 15 * A_PtrSize), "ptr", ptlb, "ptr*", psv := 0) = 0) {
				; Define IID_IDispatch.
				VarSetCapacity(IID_IDispatch, 16)
				NumPut(0x46000000000000C0, NumPut(0x20400, IID_IDispatch, "int64"), "int64")
				
				; IShellView.GetItemObject -> IDispatch (object which implements IShellFolderViewDual)
				DllCall(NumGet(NumGet(psv + 0) + 15 * A_PtrSize), "ptr", psv, "uint", 0, "ptr", &IID_IDispatch, "ptr*", pdisp := 0)
				
				; Get Shell object.
				shell := ComObj(9, pdisp, 1).Application
				
				; IShellDispatch2.ShellExecute
				shell.ShellExecute(prms*)
				
				ObjRelease(psv)
			}
			ObjRelease(ptlb)
		}
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}