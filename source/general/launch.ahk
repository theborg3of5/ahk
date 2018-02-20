; Launch various programs, URLs, etc.

; General programs.
#b::  activateProgram("Foobar")
#s::  activateProgram("Spotify")
#f::  activateProgram("Everything")
!+g:: activateProgram("GitHub")
!`::  activateProgram("ProcessExplorer")
^+!e::activateProgram("EMC2")
^+!g::activateProgram("Chrome")
^+!n::activateProgram("Notepad++")
^+!o::activateProgram("OneNote")
^+!s::activateProgram("EpicStudio")
^+!u::activateProgram("Thunder")
^+!x::activateProgram("Launchy")
^+!y::activateProgram("yEd")
^!#e::activateProgram("Outlook")
^!#f::     runProgram("FirefoxPortable")
^!#n::     runProgram("Notepad")
^!#z::activateProgram("FileZilla")
^!#/::activateProgram("WinSpy")

#If MainConfig.isMachine(MACHINE_EpicLaptop)
	; VB - have to not have shift held down when it actually opens.
	^+!v::activateProgram("VB6")
	
	; Selector launchers
	#p::  doSelect("local\phone.tl")
	^+!t::doSelect("local\outlookTLG.tl")
	^+!h::doSelect("local\epicEnvironments.tl", "DO_HYPERSPACE", "C:\Program Files (x86)\Epic\v8.4\Shared Files\EpicD84.exe")
	^+!i::doSelect("local\epicEnvironments.tl", "SEND_ENVIRONMENT_ID")
	^+!r::doSelect("local\epicEnvironments.tl", "DO_THUNDER",    "C:\Program Files (x86)\PuTTY\putty.exe")
	!+v:: doSelect("local\epicEnvironments.tl", "DO_VDI",        "C:\Program Files (x86)\VMware\VMware Horizon View Client\vmware-view.exe")
	^!#s::
		text := getFirstLineOfSelectedText()
		
		s := new Selector("local\epicEnvironments.tl")
		guiSettings                    := []
		guiSettings["Icon"]            := "C:\Program Files (x86)\Epic\Snapper\Snapper.exe"
		guiSettings["ShowDataInputs"]  := 1
		guiSettings["ExtraDataFields"] := ["INI", "ID"]
		s.selectGui("DO_SNAPPER", {"ID":text}, guiSettings)
	return
#If

; Resize window
#+r::doSelect("resize.tl")

; Folders
!+a::openFolder("AHK_ROOT")
!+m::openFolder("MUSIC")
!+c::openFolder("AHK_CONFIG")
!+d::openFolder("DOWNLOADS")
!+u::openFolder("USER_ROOT")

; TrueCrypt
#IfWinNotExist, ahk_class CustomDlg
	^+#o::
	^+#Delete::
		activateProgram("TrueCrypt")
	return
#IfWinExist

; Generic search.
!+f::
	text := getFirstLineOfSelectedText()
	
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
	For i,type in subTypes { ; For searching multiple at once.
		if(searchType = "CODESEARCH")
			url := buildCodeSearchURL(type, criteria, data["APPKEY"])
		else if(searchType = "GURU")
			url := buildGuruURL(criteria[1])
		else if(searchType = "WIKI") ; Epic wiki search.
			url := buildEpicWikiSearchURL(subTypes[0], criteria[1])
		else if(searchType = "WEB")
			url := StrReplace(subTypes[0], "%s", criteria[1])
		else if(searchType = "GREPWIN")
			searchWithGrepWin(type, criteria[1])
		else if(searchType = "EVERYTHING")
			searchWithEverything(criteria[1])
		
		if(url)
			Run, % url
	}
	
return

; Generic opener - opens a variety of different things based on the selected/clipboard text.
^!#o::
	text := getFirstLineOfSelectedText()
	ActionObject.do(text, , ACTION_RUN, , SUBACTION_WEB)
return
^!#+o::
	text := getFirstLineOfSelectedText()
	ActionObject.do(text, , ACTION_RUN)
return

; Generic linker - will allow coming from clipboard or selected text, or input entirely. Puts the link on the clipboard.
^!#l::
	text := getFirstLineOfSelectedText()
	link := ActionObject.do(text, , ACTION_LINK, , SUBACTION_WEB)
	if(link)
		clipboard := link
return
^!#+l::
	text := getFirstLineOfSelectedText()
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
!+o:: Run, % "https://www.onenote.com/notebooks?auth=1&nf=1&fromAR=1"
!+t:: Run, % onenoteOnlinePersonalDoSection

#If MainConfig.isMachine(MACHINE_HomeDesktop)
	^+!r::Run, % "http://www.reddit.com/"
#If

; Folder List - Open
^+!w::openFolder()

; Turn selected text or clipboard into standard string for OneNote use.
!+n::
	line := getFirstLineOfSelectedText()
	if(!line) ; Fall back to clipboard if nothing selected
		line := clipboard
	
	infoAry := extractEMC2ObjectInfo(line)
	ini   := infoAry["INI"]
	id    := infoAry["ID"]
	title := infoAry["TITLE"]
	
	standardString := buildStandardEMC2ObjectString(ini, id, title)
	sendTextWithClipboard(standardString)
	
	; Try to link the ini/id as well where applicable.
	if(WinActive(getWindowTitleString("OneNote"))) {
		standardStringLen := strLen(standardString)
		Send, {Left %standardStringLen%} ; Get to start of line
		
		iniIdLen := strLen(ini) + 1 + strLen(id)
		Send, {Shift Down}{Right %iniIdLen%}{Shift Up} ; Select INI/ID
		
		linkSelectedText(buildEMC2Link(ini, id))
	}
return

; Turn the selected text into a link to the URL on the clipboard.
^+k::
	linkSelectedText(clipboard)
return
