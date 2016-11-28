; Grabs the command line arguments (which live in %1%, %2%, etc) passed to the script, and puts them in a numeric array.
getScriptArgs(placeholderChar = "") {
	local paramsAry = [] ; This is the array that will hold the arguments at the end, which we'll return. Everything else (namely %1%, %2%, etc) are global.
	
	Loop, %0% { ; For each command line arg. %0% is the count of them.
		if(%A_Index% != placeholderChar) ; If a placeholder character is given, filter out values that match it (that index won't even be set).
			paramsAry[A_Index] := %A_Index% ; %1% is the value of the first command line arg, etc.
	}
	
	return paramsAry
}

scriptArgsToVars(varNames, placeholderChar = "") {
	local argNum,name ; All variables in this function are global except these (and the function parameters), so we can interact with command line arguments (%1%, %2%, etc) and set the named variables directly.
	
	if(!isObject(varNames))
		return
	
	For argNum,name in varNames {
		if(%argNum% = placeholderChar) ; If the argument is just the placeholder character, blank it.
			%name% := ""
		else
			%name% := %argNum% ; Note that we're setting a global variable with this name here.
	}
}

; Indirection of sorts - checks whether the given function exists, then calls it.
; Parameters:
;	functionName    - Function to try and call
;	params*         - Rest of parameters (this is a variadic function), same as if you'd called the function directly.
; Returns:
;		If function exists, return value of that function.
;		If function does not exist, "FUNCTION_DOES_NOT_EXIST"
; For searchability's sake, you should include the function call you'd make normally in a comment.
;
; Simple example:
;		Given this function:
;			popup(string) {
;				MsgBox, %string%
;			}
;
;		Existing call:
;			popup("asdf")
;
;		Using callIfExists():
;			callIfExists("popup", , "asdf") ; popup("asdf")
;
callIfExists(functionName, params*) { ; params is given as discrete arguemnts, but comes in as an array.
	; DEBUG.popup("runCommands", "callIfExists", "Function name", functionName, "Params", params)
	if(isFunc(functionName))
		return functionName.(params*) ; Calling this way sticks the parameters into the function we're calling expanded, not as an array.
	else
		return "FUNCTION_DOES_NOT_EXIST"
}

; Opens the given script in Notepad++.
editScript(script) {
	Run, % BorgConfig.getProgram("Notepad++", "PATH") " " script
}

; Reloads an AHK script.
reloadScript(script, prompt) {
	MsgBox, 4, , Reload now?
	IfMsgBox No
		return
	
	if(script = BORG_CENTRAL_SCRIPT) {
		Run, %ahkRootPath%source\borg.ahk, %ahkRootPath%source\
	} else {
		Reload
	}
}

; Runs something and returns the result from standard out.
RunReturn(command) {
	 fullCommand := comspec . " /c """ . command . """"
    shell := comobjcreate("wscript.shell")
    exec := (shell.exec(fullCommand))
    stdout := exec.stdout.readall()
    return stdout
}

; Runs a command with cmd.exe.
RunCommand(commandToRun = "", stayOpen = false) {
	runString := "C:\Windows\System32\cmd.exe "
	
	; Allow either an array or just a string.
	if(commandToRun.MaxIndex()) {
		For i,c in commandToRun {
			cmdString .= c A_Space
		}
		StringTrimRight, cmdString, cmdString, 1
	} else {
		cmdString := commandToRun
	}
	
	; Set /C or /K (command and close, or command and stay up) based on input.
	if(!cmdString || stayOpen)
		runString .= "/K "
	else
		runString .= "/C "
	
	; Add the command to the run string.
	runString .= cmdString
	; DEBUG.popup("Command string", cmdString, "Run string", runString)
	
	Run, % runString
}

/*
	Adapted from http://www.autohotkey.com/board/topic/79136-run-as-normal-user-not-as-admin-when-user-is-admin/
*/
RunAsUser(command, args = "", workingDir = "") {
   static TASK_TRIGGER_REGISTRATION := 7   ; trigger on registration. 
   static TASK_ACTION_EXEC := 0  ; specifies an executable action. 
   static TASK_CREATE := 2
   static TASK_RUNLEVEL_LUA := 0
   static TASK_LOGON_INTERACTIVE_TOKEN := 3
   objService := ComObjCreate("Schedule.Service") 
   objService.Connect() 

   objFolder := objService.GetFolder("") 
   objTaskDefinition := objService.NewTask(0) 

   principal := objTaskDefinition.Principal 
   principal.LogonType := TASK_LOGON_INTERACTIVE_TOKEN    ; Set the logon type to TASK_LOGON_PASSWORD 
   principal.RunLevel := TASK_RUNLEVEL_LUA  ; Tasks will be run with the least privileges. 

   colTasks := objTaskDefinition.Triggers
   objTrigger := colTasks.Create(TASK_TRIGGER_REGISTRATION) 
   endTime += 1, Minutes  ;end time = 1 minutes from now 
   FormatTime,endTime,%endTime%,yyyy-MM-ddTHH`:mm`:ss
   objTrigger.EndBoundary := endTime
   colActions := objTaskDefinition.Actions 
   objAction := colActions.Create(TASK_ACTION_EXEC) 
   objAction.ID := "7plus run" 
   objAction.Path := command
   objAction.Arguments := args
   objAction.WorkingDirectory := workingDir ? workingDir : A_WorkingDir
   objInfo := objTaskDefinition.RegistrationInfo
   objInfo.Author := "7plus" 
   objInfo.Description := "Runs a program as non-elevated user" 
   objSettings := objTaskDefinition.Settings 
   objSettings.Enabled := True 
   objSettings.Hidden := False 
   objSettings.DeleteExpiredTaskAfter := "PT0S"
   objSettings.StartWhenAvailable := True 
   objSettings.ExecutionTimeLimit := "PT0S"
   objSettings.DisallowStartIfOnBatteries := False
   objSettings.StopIfGoingOnBatteries := False
   objFolder.RegisterTaskDefinition("", objTaskDefinition, TASK_CREATE , "", "", TASK_LOGON_INTERACTIVE_TOKEN ) 
}
