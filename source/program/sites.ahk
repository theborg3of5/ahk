; Websites to open with global hotkeys.

^+!a::
	sites := Object()
	; sites.Push("https://inbox.google.com/")
	sites.Push("https://mail.google.com/mail/u/0/#inbox")
	sites.Push("http://www.facebook.com/")
	sites.Push("http://www.reddit.com/")
	sites.Push("http://feedly.com/i/latest")
	
	sitesLen := sites.MaxIndex()
	Loop, %sitesLen% {
		Run, % sites[A_Index]
		Sleep, 100
	}
	sitesLen--
	
	Send, {Ctrl Down}{Shift Down}
	Send, {Tab %sitesLen%}
	Send, {Shift Up}{Ctrl Up}
return

; ^+!m::Run, % "https://inbox.google.com/"
^+!m::Run, % "https://mail.google.com/mail/u/0/#inbox"

; ^+!f::Run, % "http://www.facebook.com/"

#If BorgConfig.isMachine(BORG_DESKTOP)
	^+!r::Run, % "http://www.reddit.com/"
#If

^+!f::Run, % "http://feedly.com/i/latest"

#If BorgConfig.isMachine(EPIC_DESKTOP)
	!+c::Run, % "iexplore.exe http://barleywine/xenappqa/"
#If
