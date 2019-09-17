; Launch miscellaneous actions.

; Generic open - open a variety of different things based on the selected text.
^!#o:: new ActionObjectRedirector(getSelectedText()).openWeb()
^!#+o::new ActionObjectRedirector(getSelectedText()).openEdit()

; Generic copy link - copy links to a variety of different things based on the selected text.
^!#l:: new ActionObjectRedirector(getSelectedText()).copyLinkWeb()
^!#+l::new ActionObjectRedirector(getSelectedText()).copyLinkEdit()

; Generic hyperlinker - get link based on the selected text and then apply it to that same text.
^!#k:: new ActionObjectRedirector(getSelectedText()).linkSelectedTextWeb()
^!#+k::new ActionObjectRedirector(getSelectedText()).linkSelectedTextEdit()

; Selector to allow easy editing of config TL files that don't show a popup
!+c::
	selectConfig() {
		path := new Selector("configs.tls").selectGui("PATH")
		if(!path)
			return
		
		path := MainConfig.replacePathTags(path)
		if(FileExist(path))
			Run(path)
	}


#If MainConfig.contextIsWork
	^+!#t::
		selectDLG() {
			s := new Selector("outlookTLG.tls")
			s.dataTL.filterOutEmptyForColumn("DLG")
			dlgId := s.selectGui("DLG", "", "", true)
			if(!dlgId)
				return
			
			dlgId := dlgId.removeFromStart("P.")
			addToClipboardHistory(dlgId)
			Send, % dlgId
		}
	
	^+!h::
		selectHyperspace() {
			data := new Selector("epicEnvironments.tls").selectGui("", "Launch Hyperspace in Environment")
			if(data)
				Run(buildHyperspaceRunString(data["MAJOR"], data["MINOR"], data["COMM_ID"]))
		}
	
	^+!i::
		selectEnvironmentId() {
			envId := new Selector("epicEnvironments.tls").selectGui("ENV_ID")
			if(envId) {
				Send, % envId
				Send, {Enter} ; Submit it too.
			}
		}
	
	^!#s::
		selectSnapper() {
			record := new EpicRecord(getSelectedText())
			
			s := new Selector("epicEnvironments.tls")
			s.addExtraOverrideFields(["INI", "ID"])
			
			defaultOverrideData        := {}
			defaultOverrideData["INI"] := record.ini
			defaultOverrideData["ID"]  := record.id
			data := s.selectGui("", "Open Record(s) in Snapper in Environment", defaultOverrideData)
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just launch Snapper, not any specific environment.
				MainConfig.runProgram("Snapper")
			else
				Run(Snapper.buildURL(data["COMM_ID"], data["INI"], data["ID"])) ; data["ID"] can contain a comma-delimited list if that's what the user entered
		}
#If


#If MainConfig.machineIsWorkLaptop
	^+!t::
		selectOutlookTLG() {
			data := new Selector("outlookTLG.tls").selectGui()
			if(!data)
				return
			
			combinedMessage := data["BASE_MESSAGE"]
			if(data["BASE_MESSAGE"] && data["MESSAGE"])
				combinedMessage .= " - " ; Hyphen in between base message and normal message
			combinedMessage .= data["MESSAGE"]
			
			textToSend := MainConfig.private["OUTLOOK_TLG_BASE"]
			textToSend := textToSend.replaceTag("TLP",      data["TLP"])
			textToSend := textToSend.replaceTag("CUSTOMER", data["CUSTOMER"])
			textToSend := textToSend.replaceTag("DLG",      data["DLG"])
			textToSend := textToSend.replaceTag("MESSAGE",  combinedMessage)
			
			if(MainConfig.isWindowActive("Outlook Calendar TLG")) {
				SendRaw, % textToSend
				Send, {Enter}
			} else {
				setClipboardAndToastError(textToSend, "", "Outlook TLG calendar not focused.")
			}
		}
	
	^+!r::
		selectThunder() {
			data := new Selector("epicEnvironments.tls").selectGui("", "Launch Thunder Environment")
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just show Thunder itself, don't launch an environment.
				MainConfig.activateProgram("Thunder")
			else
				MainConfig.runProgram("Thunder", data["THUNDER_ID"])
		}
	
	!+v::
		selectVDI() {
			data := new Selector("epicEnvironments.tls").selectGui("", "Launch VDI for Environment")
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
			selectedText := getSelectedText().firstLine().clean()
			if(isValidPhoneNumber(selectedText)) ; If the selected text is a valid number, go ahead and call it (confirmation included in callNumber)
				callNumber(selectedText)
			else
				data := new Selector("phone.tls").selectGui()
				if(data)
					callNumber(data["NUMBER"], data["NAME"])
		}
#If
