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
	^+!t::
		selectOutlookTLG() {
			data := doSelect("outlookTLG.tl")
			tlp      := data["TLP"]
			message  := data["MSG"]
			prjId    := data["PRJ"]
			dlgId    := data["DLG"]
			customer := data["CUST"]
			
			; DLG ID overrides PRJ if given, but either way only one comes through into string.
			if(dlgId)
				recId := dlgId
			else if(prjId)
				recId := "P." prjId
			
			; Sanity check - if the message is an EMC2 ID (or P.emc2Id) and the DLG is not, swap them.
			if(!isEMC2Id(recId) && (SubStr(recId, 1, 2) != "P.") ) {
				if(isEMC2Id(message)) {
					newDLG  := message
					message := recId
					recId   := newDLG
				}
			}
			textToSend := tlp "/" customer "///" recId ", " message
			
			SendRaw, % textToSend
			Send, {Enter}
		}
	^+!h::
		selectHyperspace() {
			data := doSelect("epicEnvironments.tl", MainConfig.getProgram("Hyperspace", "PATH"))
			environment  := data["COMM_ID"]
			versionMajor := data["MAJOR"]
			versionMinor := data["MINOR"]
			
			; Build run path.
			runString := buildHyperspaceRunString(versionMajor, versionMinor, environment)
			
			Run(runString)
		}
	^+!i::
		selectEnvironmentId() {
			data := doSelect("epicEnvironments.tl")
			environmentId := data["ENV_ID"]
	
			Send, % environmentId
			Send, {Enter} ; Submit it too.
		}
	^+!r::
		selectThunder() {
			data := doSelect("epicEnvironments.tl", MainConfig.getProgram("Putty", "PATH"))
			if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just show Thunder itself, don't launch an environment.
				activateProgram("Thunder")
			
			thunderId := data["THUNDER_ID"]
			runString := MainConfig.getProgram("Thunder", "PATH") " " thunderId
			
			Run(runString)
		}
	!+v::
		selectVDI() {
			data := doSelect("epicEnvironments.tl", MainConfig.getProgram("VMWareView", "PATH"))
			vdiId := data["VDI_ID"]
			
			runString := buildVDIRunString(vdiId)
			
			if(data["COMM_ID"] = "LAUNCH") { ; Special keyword - just show VMWare itself, don't launch a specific VDI.
				runProgram("VMWareView")
			} else {
				if(!vdiId) ; Safety check - don't try to launch with no VDI specified (that's what the "LAUNCH" COMM_ID is for).
					return
				
				Run(runString)
				
				; Also fake-maximize the window once it shows up.
				WinWaitActive, ahk_exe vmware-view.exe, , 10, VMware Horizon Client ; Ignore the loading-type popup that happens initially with excluded title.
				if(ErrorLevel) ; Set if we timed out or if somethign else went wrong.
					return
				fakeMaximizeWindow()
			}
		}
	#p::
		phoneSelector() {
			selectedText := cleanupText(getFirstLineOfSelectedText())
			if(isValidPhoneNumber(selectedText)) ; If the selected text is a valid number, go ahead and call it (confirmation included in callNumber)
				callNumber(selectedText)
			else
				data := doSelect("phone.tl")
				num := data["NUMBER"]
				name := data["NAME"]
				
				callNumber(num, name)
		}
	^!#s::
		snapperSelector() {
			selectedText := cleanupText(getFirstLineOfSelectedText())
			splitRecordString(selectedText, ini, id)
			
			; Default data from selection.
			defaultOverrideData        := []
			defaultOverrideData["INI"] := ini
			defaultOverrideData["ID"]  := id
			
			s := new Selector("epicEnvironments.tl")
			guiSettings                       := []
			guiSettings["Icon"]               := MainConfig.getProgram("Snapper", "PATH")
			guiSettings["ShowOverrideFields"] := true
			guiSettings["ExtraDataFields"] := ["INI", "ID"]
			data := s.selectGui(defaultOverrideData, guiSettings)
			if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just launch Snapper, not any specific environment.
				runProgram("Snapper")
			
			environment := data["COMM_ID"]
			ini         := data["INI"]
			idList      := data["ID"]
			
			url := buildSnapperURL(environment, ini, idList)
			Run(url)
		}
	#+p::
		prjSelector() {
			s := new Selector("outlookTLG.tl")
			data := s.selectGui({"ShowOverrideFields":false})
			
			prjId := data["PRJ"]
			if(prjId)
				Send, % prjId
		}
#If

; Resize window
#+r::
	selectResize() {
		data := doSelect("resize.tl")
		width  := data["WIDTH"]
		height := data["HEIGHT"]
		ratioW := data["WRATIO"]
		ratioH := data["HRATIO"]
		
		if(ratioW)
			width  *= ratioW
		if(ratioH)
			height *= ratioH
		
		WinMove, A, , , , width, height
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
	genericSearch() {
		text := cleanupText(getFirstLineOfSelectedText())
		
		filter := MainConfig.getMachineTableListFilter()
		s := new Selector("search.tl", "", filter)
		data := s.selectGui({"SEARCH_TERM":text})
		
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
		sites := Object()
		sites.Push("https://mail.google.com/mail/u/0/#inbox")
		sites.Push("http://www.facebook.com/")
		sites.Push("http://www.reddit.com/")
		sites.Push("http://feedly.com/i/latest")
		
		sitesLen := sites.MaxIndex()
		Loop, %sitesLen% {
			Run(sites[A_Index])
			Sleep, 100
		}
		sitesLen--
		
		Send, {Ctrl Down}{Shift Down}
		Send, {Tab %sitesLen%}
		Send, {Shift Up}{Ctrl Up}
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
	folderSelector() {
		folderPath := selectFolder()
		if(folderPath && FileExist(folderPath))
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
	configSelector() {
		data := doSelect("configs.tl")
		path := data["PATH"]
		path := MainConfig.replacePathTags(path)
		if(path && FileExist(path))
			Run(path)
	}
