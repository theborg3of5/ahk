; Grab two raw files of XDS content from the server folder, clean them up and diff them.
; Goes with my ;xdsdiff macro.
#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>

; Read in the raw files of narrative/content.
rawLeft  := FileRead(Config.path["EPIC_NFS_ASK"] "\Diff\xdsDiffLeft.txt")
rawRight := FileRead(Config.path["EPIC_NFS_ASK"] "\Diff\xdsDiffRight.txt")

; Strip out all HTML tags.
htmlRegEx := "<\/?(DIV|SPAN|A|OL|UL|IMG|H[1-6]|!--)[^>]*>|(\r\n)?<\/?LI[^>]*>"
cleanLeft  := rawLeft.replaceRegEx(htmlRegEx,"")
cleanRight := rawRight.replaceRegEx(htmlRegEx,"")

; Put the cleaned text back in files and diff it.
pathLeft  := A_Temp "\ahkDiffLeft.txt"
pathRight := A_Temp "\ahkDiffRight.txt"
FileLib.replaceFileWithString(pathLeft,  cleanLeft)
FileLib.replaceFileWithString(pathRight, cleanRight)
Config.runProgram("KDiff", pathLeft " " pathRight)

ExitApp
