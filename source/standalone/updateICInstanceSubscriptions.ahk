; gdbdoc
#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

; ---- Settings ----
WorkingCopy := "C:\EpicSource\InstanceSubscriptions"
SvnExe      := "svn.exe"            ; or a full path if svn isn't on PATH
TaskName    := "Update InstanceSubscriptions"
RunTime     := "02:00"              ; 24-hour HH:mm
LogFile     := A_ScriptDir . "\InstanceSubscriptionsUpdate.log"

if (A_Args[1] = "/install")
{
    InstallTask()
    ExitApp
}

RunUpdate()
ExitApp

; ---- Does the nightly svn update and logs the result ----
RunUpdate()
{
    global WorkingCopy, SvnExe, LogFile

    FormatTime, stamp, , yyyy-MM-dd HH:mm:ss
    FileAppend, [%stamp%] svn update starting`n, %LogFile%

    ; Extra outer quotes are required when cmd /c is given a quoted command
    cmd := """" . SvnExe . """ update """ . WorkingCopy . """ --non-interactive >> """ . LogFile . """ 2>&1"
    RunWait, % ComSpec . " /c """ . cmd . """", , Hide
    exitCode := ErrorLevel

    FormatTime, stamp, , yyyy-MM-dd HH:mm:ss
    FileAppend, [%stamp%] svn update finished (exit code %exitCode%)`n, %LogFile%
}

; ---- Registers the daily task for the current user ----
InstallTask()
{
    global TaskName, RunTime

    ; Command the task will run: this script
	tr := """" . A_AhkPath . """ """ . A_ScriptFullPath . """"

    ; schtasks needs inner quotes escaped as \"
    trEsc := StrReplace(tr, """", "\""")

    cmd := "schtasks /Create /TN """ . TaskName . """ /SC DAILY /ST " . RunTime . " /TR """ . trEsc . """ /F"
    RunWait, % ComSpec . " /c """ . cmd . """", , Hide
    if (ErrorLevel != 0)
    {
        MsgBox, 16, Install failed, schtasks returned exit code %ErrorLevel%.
        return
    }

    ; schtasks has no switch for "run as soon as possible after a missed start",
    ; so set StartWhenAvailable through PowerShell (helps with sleeping laptops)
    ps := "$t = Get-ScheduledTask -TaskName '" . TaskName . "'; "
        . "$t.Settings.StartWhenAvailable = $true; "
        . "Set-ScheduledTask -InputObject $t | Out-Null"
    RunWait, % "powershell.exe -NoProfile -Command """ . ps . """", , Hide

    MsgBox, 64, Done, Task '%TaskName%' registered to run daily at %RunTime%.
}