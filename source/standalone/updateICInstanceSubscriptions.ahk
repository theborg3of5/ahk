; Update the InstanceSubscriptions SVN working copy, logging the result.
;  Run with /install to register a daily scheduled task that runs this script.
#Include <includeCommon>
ScriptTrayInfo.Init("AHK: Update IC URL SVN repo", Config.getProgramPath("TortoiseSVN"))

global TASK_NAME    := "Update InstanceSubscriptions"
global RUN_TIME     := "02:00" ; 24-hour HH:mm
global WORKING_COPY := Config.path["EPIC_INSTANCE_SUBSCRIPTIONS"]
global LOG_FILE     := FileLib.getParentFolder(WORKING_COPY) "\InstanceSubscriptionsUpdate.log"

; Install the task if requested; otherwise do the update (the task calls this script too).
if (A_Args[1] = "/install") {
	installTask()
} else {
	runUpdate()
}
ExitApp

;---------
; DESCRIPTION:    Run an SVN update on the working copy, logging the output and result.
;---------
runUpdate() {
	writeToLog("SVN update starting")

	command := """" Config.getProgramPath("SVN") """ update """ WORKING_COPY """ --non-interactive"
	output := RunLib.runReturn(command, errorOutput, exitCode)
	writeToLog(output.appendLine(errorOutput).clean(), false)

	writeToLog("SVN update finished (exit code " exitCode ")")
}

;---------
; DESCRIPTION:    Register (or replace) a daily scheduled task for the current user that runs this script.
; NOTES:          The task is set to run as soon as possible after a missed start (helps with
;                 sleeping laptops).
;---------
installTask() {
	psCommand := "Register-ScheduledTask -TaskName '" TASK_NAME "'"
	; The \" escapes are for the command line, so that PowerShell ends up with literal quotes around the
	; script path (in case it has spaces).
	psCommand .= " -Action (New-ScheduledTaskAction -Execute '" A_AhkPath "' -Argument '\""" A_ScriptFullPath "\""')"
	psCommand .= " -Trigger (New-ScheduledTaskTrigger -Daily -At '" RUN_TIME "')"
	psCommand .= " -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable)"
	psCommand .= " -Force" ; Replaces any existing task with the same name

	RunLib.runReturn("powershell.exe -NoProfile -Command """ psCommand """", errorOutput, exitCode)
	if (exitCode != 0) {
		writeToLog("Failed to register scheduled task '" TASK_NAME "' (exit code " exitCode "): " errorOutput.clean())
		Toast.BlockAndShowError("Failed to register scheduled task", errorOutput.clean())
		return
	}

	writeToLog("Registered scheduled task '" TASK_NAME "' to run daily at " RUN_TIME)
	Toast.BlockAndShowMedium("Task '" TASK_NAME "' registered to run daily at " RUN_TIME)
}

;---------
; DESCRIPTION:    Add a line to the log file. Blank messages are skipped.
; PARAMETERS:
;  message      (I,REQ) - The message to log.
;  addTimestamp (I,OPT) - Set to false to write the message as-is, without a timestamp prefix (useful for multi-line
;                         output, like from a command).
;---------
writeToLog(message, addTimestamp := true) {
	if (message = "")
		return

	if (addTimestamp)
		message := "[" FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") "] " message

	FileAppend, % message "`n", % LOG_FILE
}
