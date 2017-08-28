#IfWinActive, ahk_exe Epic.Release.Wilma.exe

^f::
	Send, !m              ; Select Manually
	Send, {Tab}
	Send, 2{Enter}{Tab}   ; APP TRACK-CURRENT DEV
	Send, 130{Enter}{Tab} ; First Stage QA
	Send, 1{Enter}        ; Hyperspace
return

#IfWinActive
