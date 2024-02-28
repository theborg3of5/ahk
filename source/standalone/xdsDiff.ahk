; Grab two raw files of XDS content from the server folder, clean them up and diff them.
; Goes with my ;xdsdiff macro.

#Include <includeCommon>

; Read in the raw files of narrative/content.
rawLeft  := FileRead(Config.path["EPIC_NFS_ASK"] "\temp\xdsDiffLeft.txt")
rawRight := FileRead(Config.path["EPIC_NFS_ASK"] "\temp\xdsDiffRight.txt")

; Strip out all HTML tags.
htmlRegEx := "i)<\/?(DIV|SPAN|TABLE|TBODY|TR|TD|A|OL|UL|IMG|H[1-6]|!--)[^>]*>|(\r\n)?<\/?LI[^>]*>" ; i = case-insensitive flag
cleanLeft  := rawLeft.replaceRegEx(htmlRegEx,"")
cleanRight := rawRight.replaceRegEx(htmlRegEx,"")

; Put the cleaned text back in files and diff it.
pathLeft  := A_Temp "\ahkDiffLeft.txt"
pathRight := A_Temp "\ahkDiffRight.txt"
FileLib.replaceFileWithString(pathLeft,  cleanLeft)
FileLib.replaceFileWithString(pathRight, cleanRight)
Config.runProgram("KDiff", pathLeft " " pathRight)

ExitApp
