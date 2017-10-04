; Launch various programs, URLs, etc.

; General programs.
#f::  activateProgram("Everything")
#b::  activateProgram("Foobar")
!`::  activateProgram("ProcessExplorer")
!+b::      runProgram("VMWarePlayer")
!+o:: activateProgram("OxygenXML")
^+!g::activateProgram("Chrome")
^+!o::
	Sleep, 500
	activateProgram("OneNote")
return
^+!x::activateProgram("Launchy")
^+!n::activateProgram("Notepad++")
^+!s::activateProgram("EpicStudio")
^+!u::activateProgram("Thunder")
^+!e::activateProgram("EMC2")
^+!y::activateProgram("yEd")
^!#e::activateProgram("Outlook")
^!#n::     runProgram("Notepad")
^!#/::activateProgram("WinSpy")
^!#f::     runProgram("FirefoxPortable")

; Special programs/specific params.
!+g::
	progInfo := MainConfig.getProgram("GitHub")
	Run, % wrapInQuotes(progInfo["PATH"])
return
^!#z::
	progInfo := MainConfig.getProgram("FileZilla")
	Run, % wrapInQuotes(progInfo["PATH"]) filezillaSiteCowbox
return

#If !MainConfig.isMachine(MACHINE_EpicLaptop)
	!+l::activateProgram("League")
#If

#If MainConfig.isMachine(MACHINE_EpicLaptop)
	; VB - have to not have shift held down when it actually opens.
	^+!v::
		KeyWait, Shift
		activateProgram("VB6")
	return
	
	; Selector launchers
	#p::  doSelect("local\phone.tl")
	^+!t::doSelect("local\outlookTLG.tl")
	^+!h::doSelect("local\epicEnvironments.tl", "DO_HYPERSPACE", "C:\Program Files (x86)\Epic\v8.3\Shared Files\EpicD83.exe")
	^+!r::doSelect("local\epicEnvironments.tl", "DO_THUNDER",    "C:\Program Files (x86)\PuTTY\putty.exe")
	!+v:: doSelect("local\epicEnvironments.tl", "DO_VDI",        "C:\Program Files (x86)\VMware\VMware Horizon View Client\vmware-view.exe")
	^!#s::
		s := new Selector("local\epicEnvironments.tl")
		guiSettings                    := []
		guiSettings["Icon"]            := "C:\Program Files (x86)\Epic\Snapper\Snapper.exe"
		guiSettings["ShowDataInputs"]  := 1
		guiSettings["ExtraDataFields"] := ["INI", "ID"]
		s.selectGui("DO_SNAPPER", {"ID":getSelectedText()}, guiSettings)
	return
#If

; Resize window
#!r::doSelect("resize.tl")

; Folders
!+a::openFolder("ahkRoot")
!+m::openFolder("music")
!+x::openFolder("ahkConfig")
!+d::openFolder("downloads")

; TrueCrypt
#IfWinNotExist, ahk_class CustomDlg
	^+#o::
	^+#Delete::
		activateProgram("TrueCrypt")
	return
#IfWinExist

; Generic search.
!+f::
	text := getSelectedText()
	
	filter := MainConfig.getMachineTableListFilter()
	s := new Selector("search.tl", "", filter)
	data := s.selectGui("", {"ARG1": text})
	
	searchType := data["SEARCH_TYPE"]
	subTypes   := forceArray(data["SUBTYPE"])
	
	criteria := []
	Loop, 5 {
		arg := data["ARG" A_Index]
		escapedArg := escapeDoubleQuotes(arg, 3) ; 3 quotes per quote - gets us past the windows run command stripping things out.
		criteria[A_Index] := escapedArg
	}
	
	url := ""
	if(searchType = "CODESEARCH")
		For i,st in subTypes ; There could be multiple here?
			url := buildCodeSearchURL(st, criteria, data["APPKEY"])
	else if(searchType = "GURU")
		url := buildGuruURL(criteria[1])
	else if(searchType = "WIKI") ; Epic wiki search.
		url := buildEpicWikiSearchURL(subTypes[0], criteria[1])
	else if(searchType = "WEB")
		url := StrReplace(subTypes[0], "%s", criteria[1])
	
	if(url)
		Run, % url
return

; ; Take the selected number, show a popup that takes what math to do on it (i.e., +25), and put the result back in place.
; !+c::
	; text := getSelectedText()
	; outText := mathPopup(text)
	; if(outText)
		; sendTextWithClipboard(outText)
; return

; Generic opener - opens a variety of different things based on the selected/clipboard text.
^!#o::
	text := getSelectedText()
	ActionObject.do(text, , , , SUBACTION_WEB)
return
^!#+o::
	text := getSelectedText()
	ActionObject.do(text)
return

; Generic linker - will allow coming from clipboard or selected text, or input entirely. Puts the link on the clipboard.
^!#l::
	text := getSelectedText()
	link := ActionObject.do(text, , ACTION_LINK, , SUBACTION_WEB)
	if(link)
		clipboard := link
return
^!#+l::
	text := getSelectedText()
	link := ActionObject.do(text, , ACTION_LINK)
	if(link)
		clipboard := link
return

; Sites
^+!a::
	sites := Object()
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

^+!m::Run, % "https://www.messenger.com"
^+!f::Run, % "http://feedly.com/i/latest"
^!#m::Run, % "https://mail.google.com/mail/u/0/#inbox"

#If MainConfig.isMachine(MACHINE_HomeDesktop)
	^+!r::Run, % "http://www.reddit.com/"
#If
#If MainConfig.isMachine(MACHINE_EpicLaptop)
	!+c::Run, % "iexplore.exe http://barleywine/xenappqa/"
#If

; Folder List - Open
^+!w::openFolder()

; Query this machine's folders TL file (prompt the user if nothing given) and open it.
openFolder(folderName = "") {
	global configFolder
	
	filter := MainConfig.getMachineTableListFilter()
	s := new Selector("folders.tl", "", filter)
	
	if(folderName)
		folderPath := s.selectChoice(folderName)
	else
		folderPath := s.selectGui()
	
	; Replace any special tags with real paths.
	folderPath := StrReplace(folderPath, "<AHKROOT>", SubStr(ahkRootPath, 1, -1)) ; Assuming that global path vars have a \ on the end that we don't want.
	folderPath := StrReplace(folderPath, "<USERROOT>", SubStr(userPath, 1, -1))
	
	if(folderPath && FileExist(folderPath))
		Run, % folderPath
}
