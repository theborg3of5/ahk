; Launch various programs, URLs, etc.

; General programs.
#s::       runProgram("Spotify") ; Can't unminimize from tray with any reasonable logic, so re-run to do so.
#f::  activateProgram("Everything")
#t::       runProgram("Telegram")
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
	^+!v::activateProgram("VB6")
	^!#e::activateProgram("Outlook")
	^!#v::activateProgram("VisualStudio")
	
	; Selector launchers
	^+!t::
		selectOutlookTLG() {
			s := new Selector("outlookTLG.tl")
			data := s.selectGui()
			if(!data)
				return
			
			; Record ID comes from either DLG ID, or PRJ (with P.)
			if(data["DLG"])
				recId := data["DLG"]
			else if(data["PRJ"])
				recId := "P." data["PRJ"]
			
			textToSend := data["TLP"] "/" data["CUST"] "///" recId ", " data["MSG"]
			SendRaw, % textToSend
			Send, {Enter}
		}
	^+!h::
		selectHyperspace() {
			s := new Selector("epicEnvironments.tl")
			data := s.selectGui("", "Launch Hyperspace in Environment")
			if(data)
				Run(buildHyperspaceRunString(data["MAJOR"], data["MINOR"], data["COMM_ID"]))
		}
	^+!i::
		selectEnvironmentId() {
			s := new Selector("epicEnvironments.tl")
			envId := s.selectGui("ENV_ID")
			if(envId) {
				Send, % envId
				Send, {Enter} ; Submit it too.
			}
		}
	^+!r::
		selectThunder() {
			s := new Selector("epicEnvironments.tl")
			data := s.selectGui("", "Launch Thunder Environment")
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just show Thunder itself, don't launch an environment.
				activateProgram("Thunder")
			else
				Run(MainConfig.getProgram("Thunder", "PATH") " " data["THUNDER_ID"])
		}
	!+v::
		selectVDI() {
			s := new Selector("epicEnvironments.tl")
			data := s.selectGui("", "Launch VDI for Environment")
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") { ; Special keyword - just show VMWare itself, don't launch a specific VDI.
				runProgram("VMWareView")
			} else {
				Run(buildVDIRunString(data["VDI_ID"]))
				
				; Also fake-maximize the window once it shows up.
				WinWaitActive, ahk_exe vmware-view.exe, , 10, VMware Horizon Client ; Ignore the loading-type popup that happens initially with excluded title.
				if(ErrorLevel) ; Set if we timed out or if somethign else went wrong.
					return
				fakeMaximizeWindow()
			}
		}
	#p::
		selectPhone() {
			selectedText := cleanupText(getFirstLineOfSelectedText())
			if(isValidPhoneNumber(selectedText)) ; If the selected text is a valid number, go ahead and call it (confirmation included in callNumber)
				callNumber(selectedText)
			else
				s := new Selector("phone.tl")
				data := s.selectGui()
				if(data)
					callNumber(data["NUMBER"], data["NAME"])
		}
	^!#s::
		selectSnapper() {
			selectedText := cleanupText(getFirstLineOfSelectedText())
			splitRecordString(selectedText, ini, id)
			
			s := new Selector("epicEnvironments.tl")
			s.addExtraDataFields(["INI", "ID"])
			
			defaultOverrideData        := []
			defaultOverrideData["INI"] := ini
			defaultOverrideData["ID"]  := id
			data := s.selectGui("", "Open Record(s) in Snapper in Environment", defaultOverrideData)
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just launch Snapper, not any specific environment.
				runProgram("Snapper")
			else
				Run(buildSnapperURL(data["COMM_ID"], data["INI"], data["ID"])) ; data["ID"] can contain a comma-delimited list if that's what the user entered
		}
	#+p::
		selectPRJ() {
			s := new Selector("outlookTLG.tl")
			prjId := s.selectGui("PRJ", "", "", true)
			if(prjId)
				Send, % prjId
		}
#If

; Resize window
#+r::
	selectResize() {
		s := new Selector("resize.tl")
		data := s.selectGui()
		if(data)
			WinMove, A, , , , data["WIDTH"], data["HEIGHT"]
	}

; Folders
!+a::openFolder("AHK_ROOT")
!+m::openFolder("MUSIC")
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
	selectSearch() {
		text := cleanupText(getFirstLineOfSelectedText())
		
		filter := MainConfig.getMachineTableListFilter()
		s := new Selector("search.tl", filter)
		data := s.selectGui("", "", {"SEARCH_TERM":text})
		if(!data)
			return
		
		searchTerm := escapeDoubleQuotes(data["SEARCH_TERM"], 3) ; 3 quotes per quote - gets us past the windows run command stripping things out.
		subTypes   := forceArray(data["SUBTYPE"])
		
		For i,type in subTypes { ; For searching multiple at once.
			url := ""
			
			if(data["SEARCH_TYPE"] = "CODESEARCH")
				url := buildCodeSearchURL(type, searchTerm, data["APP_KEY"])
			else if(data["SEARCH_TYPE"] = "GURU")
				url := buildGuruURL(searchTerm)
			else if(data["SEARCH_TYPE"] = "WIKI") ; Epic wiki search.
				url := buildEpicWikiSearchURL(subTypes[0], searchTerm)
			else if(data["SEARCH_TYPE"] = "WEB")
				url := StrReplace(subTypes[0], "%s", searchTerm)
			else if(data["SEARCH_TYPE"] = "GREPWIN")
				searchWithGrepWin(type, searchTerm)
			else if(data["SEARCH_TYPE"] = "EVERYTHING")
				searchWithEverything(searchTerm)
			
			if(url)
				Run(url)
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
		Run("https://mail.google.com/mail/u/0/#inbox")
		Sleep, 100
		Run("http://www.facebook.com/")
		Sleep, 100
		Run("http://www.reddit.com/")
		Sleep, 100
		Run("http://feedly.com/i/latest")
	}

^+!m::Run("https://www.messenger.com")
^+!f::Run("http://feedly.com/i/latest")
^!#m::Run("https://mail.google.com/mail/u/0/#inbox")
!+o:: Run("https://www.onenote.com/notebooks?auth=1&nf=1&fromAR=1")
!+t:: Run(MainConfig.getPrivate("ONENOTE_ONLINE_DO_SECTION"))

#If MainConfig.isMachine(MACHINE_HomeDesktop)
	^+!r::Run("http://www.reddit.com/")
#If

; Folder List - Open
^+!w::
	doSelectFolder() {
		folderPath := selectFolder()
		if(FileExist(folderPath))
			Run(folderPath)
	}

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
		
		path := cleanupPath(path)
		path := mapPath(path)
		sendTextWithClipboard(path)
	}
!+#p::sendCleanedUpPathFolder()
	sendCleanedUpPathFolder() {
		path := getFirstLineOfSelectedText()
		if(!path) ; Fall back to clipboard if nothing selected
			path := clipboard
		
		path := cleanupPath(path)
		path := mapPath(path)
		folder := reduceFilepath(path, 1) "\" ; Add trailing slash
		sendTextWithClipboard(folder)
	}

; Selector to allow easy editing of config TL files that don't show a popup
!+c::
	selectConfig() {
		s := new Selector("configs.tl")
		path := s.selectGui("PATH")
		if(!path)
			return
		
		path := MainConfig.replacePathTags(path)
		if(FileExist(path))
			Run(path)
	}
