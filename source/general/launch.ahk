; Launch miscellaneous actions.

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
	if(link) {
		clipboard := link
		Toast.showForTime("Clipboard set to link: " clipboard, 2)
	}
}

; Generic hyperlinker - get link for selection and apply it to the selected text.
^!#k:: genericHyperlink(SUBACTION_Web)
^!#+k::genericHyperlink(SUBACTION_Edit)
genericHyperlink(subAction) {
	text := getFirstLineOfSelectedText()
	link := ActionObject.do(text, , ACTION_Link, , subAction)
	if(!link)
		return
	
	if(!linkSelectedText(link)) {
		; If we failed to add the link to the selected text, at least put the link on the clipboard and notify the user.
		clipboard := link
		Toast.showForTime("Clipboard set to link: " clipboard, 2)
	}
}

; Generic search.
!+f::
	selectSearch() {
		text := cleanupText(getFirstLineOfSelectedText())
		
		filter := MainConfig.getMachineTableListFilter()
		s := new Selector("search.tl", filter)
		data := s.selectGui("", "", {"SEARCH_TERM":text})
		if(!data)
			return
		
		searchTerm := data["SEARCH_TERM"]
		subTypes   := forceArray(data["SUBTYPE"])
		
		For i,subType in subTypes { ; For searching multiple at once.
			url := ""
			
			if(data["SEARCH_TYPE"] = "WEB") {
				searchTerm := escapeCharUsingRepeat(data["SEARCH_TERM"], DOUBLE_QUOTE, 2) ; Escape quotes twice - extra to get us past the windows run command stripping them out.
				url := StrReplace(subTypes[0], "%s", searchTerm)
			} else if(data["SEARCH_TYPE"] = "CODESEARCH") {
				searchTerm := escapeCharUsingRepeat(data["SEARCH_TERM"], DOUBLE_QUOTE, 2) ; Escape quotes twice - extra to get us past the windows run command stripping them out.
				url := buildCodeSearchURL(subType, searchTerm, data["APP_KEY"])
			} else if(data["SEARCH_TYPE"] = "GURU") {
				searchTerm := escapeCharUsingRepeat(data["SEARCH_TERM"], DOUBLE_QUOTE, 2) ; Escape quotes twice - extra to get us past the windows run command stripping them out.
				url := buildGuruURL(searchTerm)
			} else if(data["SEARCH_TYPE"] = "WIKI") { ; Epic wiki search.
				searchTerm := escapeCharUsingRepeat(data["SEARCH_TERM"], DOUBLE_QUOTE, 2) ; Escape quotes twice - extra to get us past the windows run command stripping them out.
				url := buildEpicWikiSearchURL(subTypes[0], searchTerm)
			
			} else if(data["SEARCH_TYPE"] = "GREPWIN") {
				searchWithGrepWin(subType, searchTerm)
			} else if(data["SEARCH_TYPE"] = "EVERYTHING") {
				searchWithEverything(searchTerm)
			}
			
			if(url)
				Run(url)
		}
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

; Epic-specific actions
#If MainConfig.isMachine(MACHINE_EpicLaptop)
	^+!t::
		selectOutlookTLG() {
			s := new Selector("outlookTLG.tl")
			data := s.selectGui()
			if(!data)
				return
			
			textToSend := MainConfig.getPrivate("OUTLOOK_TLG_BASE")
			textToSend := replaceTag(textToSend, "TLP",      data["TLP"])
			textToSend := replaceTag(textToSend, "CUSTOMER", data["CUSTOMER"])
			textToSend := replaceTag(textToSend, "DLG",      data["DLG"])
			textToSend := replaceTag(textToSend, "MESSAGE",  data["MESSAGE"])
			
			if(MainConfig.isWindowActive("Outlook Calendar TLG")) {
				SendRaw, % textToSend
				Send, {Enter}
			} else {
				clipboard := textToSend
				Toast.showForTime("Clipboard set to link: " clipboard, 2)
			}
		}
	^+!#t::
		selectDLG() {
			filter := {COLUMN:"DLG", VALUE:"", INCLUDE_BLANKS:false}
			s := new Selector("outlookTLG.tl", filter)
			dlgId := s.selectGui("DLG", "", "", true)
			if(!dlgId)
				return
			
			dlgId := removeStringFromStart(dlgId, "P.")
			Send, % dlgId
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
				MainConfig.activateProgram("Thunder")
			else
				Run(MainConfig.getProgramPath("Thunder") " " data["THUNDER_ID"])
		}
	
	!+v::
		selectVDI() {
			s := new Selector("epicEnvironments.tl")
			data := s.selectGui("", "Launch VDI for Environment")
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") { ; Special keyword - just show VMWare itself, don't launch a specific VDI.
				MainConfig.runProgram("VMware Horizon Client")
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
			s.addExtraOverrideFields(["INI", "ID"])
			
			defaultOverrideData        := []
			defaultOverrideData["INI"] := ini
			defaultOverrideData["ID"]  := id
			data := s.selectGui("", "Open Record(s) in Snapper in Environment", defaultOverrideData)
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just launch Snapper, not any specific environment.
				MainConfig.runProgram("Snapper")
			else
				Run(buildSnapperURL(data["COMM_ID"], data["INI"], data["ID"])) ; data["ID"] can contain a comma-delimited list if that's what the user entered
		}
#If
