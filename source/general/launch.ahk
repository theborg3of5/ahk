; Launch various programs, URLs, etc.

; General programs.
#s::       runProgram("Spotify") ; Can't unminimize from tray with any reasonable logic, so re-run to do so.
#f::  activateProgram("Everything")
!+g:: activateProgram("GitHub")
!`::  activateProgram("ProcessExplorer")
^+!g::activateProgram("Chrome")
^+!n::activateProgram("Notepad++")
^+!o::activateProgram("OneNote")
^+!x::activateProgram("Launchy")
^+!y::activateProgram("yEd")
^!#f::     runProgram("FirefoxPortable")
^!#n::     runProgram("Notepad")
^!#z::activateProgram("FileZilla")
^!#/::activateProgram("WinSpy")

#If MainConfig.isMachine(MACHINE_EpicLaptop)
	^+!e::activateProgram("EMC2")
	^+!s::activateProgram("EpicStudio")
	^+!u::activateProgram("Thunder")
	^+!v::activateProgram("VisualStudio")
	^!#e::activateProgram("Outlook")
	^!#v::activateProgram("VB6")
	
	; Selector launchers
	^+!t::doSelect("outlookTLG.tl")
	^+!h::doSelect("epicEnvironments.tl", "DO_HYPERSPACE", "C:\Program Files (x86)\Epic\v8.5\Shared Files\EpicD85.exe")
	^+!i::doSelect("epicEnvironments.tl", "SEND_ENVIRONMENT_ID")
	^+!r::doSelect("epicEnvironments.tl", "DO_THUNDER",    "C:\Program Files (x86)\PuTTY\putty.exe")
	!+v:: doSelect("epicEnvironments.tl", "DO_VDI",        "C:\Program Files (x86)\VMware\VMware Horizon View Client\vmware-view.exe")
	#p::
		phoneSelector() {
			selectedText := cleanupText(getFirstLineOfSelectedText())
			if(isValidPhoneNumber(selectedText)) ; If the selected text is a valid number, go ahead and call it (confirmation included in callNumber)
				callNumber(selectedText)
			else
				doSelect("phone.tl")
		}
	^!#s::
		snapperSelector() {
			selectedText := cleanupText(getFirstLineOfSelectedText())
			splitRecordString(selectedText, ini, id)
			
			; Default data from selection.
			defaultData        := []
			defaultData["INI"] := ini
			defaultData["ID"]  := id
			
			s := new Selector("epicEnvironments.tl")
			guiSettings                    := []
			guiSettings["Icon"]            := "C:\Program Files (x86)\Epic\Snapper\Snapper.exe"
			guiSettings["ShowDataInputs"]  := 1
			guiSettings["ExtraDataFields"] := ["INI", "ID"]
			s.selectGui("DO_SNAPPER", defaultData, guiSettings)
		}
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
	genericSearch() {
		text := getFirstLineOfSelectedText()
		
		filter := MainConfig.getMachineTableListFilter()
		s := new Selector("search.tl", "", filter)
		data := s.selectGui("", {"SEARCH_TERM":text})
		
		searchTerm := escapeDoubleQuotes(data["SEARCH_TERM"], 3) ; 3 quotes per quote - gets us past the windows run command stripping things out.
		searchType := data["SEARCH_TYPE"]
		subTypes   := forceArray(data["SUBTYPE"])
		
		url := ""
		For i,type in subTypes { ; For searching multiple at once.
			if(searchType = "CODESEARCH")
				url := buildCodeSearchURL(type, searchTerm, data["APP_KEY"])
			else if(searchType = "GURU")
				url := buildGuruURL(searchTerm)
			else if(searchType = "WIKI") ; Epic wiki search.
				url := buildEpicWikiSearchURL(subTypes[0], searchTerm)
			else if(searchType = "WEB")
				url := StrReplace(subTypes[0], "%s", searchTerm)
			else if(searchType = "GREPWIN")
				searchWithGrepWin(type, searchTerm)
			else if(searchType = "EVERYTHING")
				searchWithEverything(searchTerm)
			
			if(url)
				Run, % url
		}
	}

; Generic opener - opens a variety of different things based on the selected/clipboard text.
^!#o:: genericOpen(SUBACTION_Web)
^!#+o::genericOpen(SUBACTION_Edit)
genericOpen(subAction) {
	text := getFirstLineOfSelectedText()
	ActionObject.do(text, , ACTION_Run, , subAction)
}

; Generic linker - will allow coming from clipboard or selected text, or input entirely. Puts the link on the clipboard.
^!#l:: genericLink(SUBACTION_Web)
^!#+l::genericLink(SUBACTION_Edit)
genericLink(subAction) {
	text := getFirstLineOfSelectedText()
	link := ActionObject.do(text, , ACTION_Link, , subAction)
	if(link)
		clipboard := link
}

; Sites
^+!a::
	openAllSites() {
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
	}

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
	sendAndLinkStandardOneNoteString() {
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
	}

; Send cleaned-up path:
; - Turn network paths into their drive-mapped equivalents
; - Remove file:///, quotes, and other garbage from around the path.
!+p::
	sendCleanedUpPath() {
		path := getFirstLineOfSelectedText()
		if(!path) ; Fall back to clipboard if nothing selected
			path := clipboard
		
		; Clean out unwanted garbage strings
		path := cleanupText(path, ["file:///", """"])
		
		; Convert paths to use mapped drive letters
		tl := new TableList(findTLFilePath("mappedDrives.tl"))
		table := tl.getFilteredTable("MACHINE", MainConfig.getMachine())
		
		For i,row in table {
			if(stringContains(path, row["PATH"])) {
				path := StrReplace(path, row["PATH"], row["DRIVE_LETTER"] ":", , 1)
				Break ; Just match the first one.
			}
		}
		; DEBUG.popup("Updated path",path, "Table",table)
		
		sendTextWithClipboard(path)
	}
