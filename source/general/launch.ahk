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
		
		path := Config.replacePathTags(path)
		if(FileExist(path))
			Run(path)
	}


#If Config.contextIsWork
	^+!#t::
		selectDLG() {
			s := new Selector("outlookTLG.tls").OverrideFieldsOff()
			s.dataTL.filterOutEmptyForColumn("DLG")
			dlgId := s.selectGui("DLG")
			if(!dlgId)
				return
			
			dlgId := dlgId.removeFromStart("P.")
			addToClipboardHistory(dlgId)
			Send, % dlgId
		}
	
	^+!h::
		selectHyperspace() {
			data := new Selector("epicEnvironments.tls").SetTitle("Launch Hyperspace in Environment").selectGui()
			if(data)
				EpicLib.runHyperspace(data["MAJOR"], data["MINOR"], data["COMM_ID"])
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
			
			s := new Selector("epicEnvironments.tls").SetTitle("Open Record(s) in Snapper in Environment")
			s.AddOverrideFields(["INI", "ID"]).SetDefaultOverrides({"INI":record.ini, "ID":record.id}) ; Add fields for INI/ID and default in values if we figured them out
			data := s.selectGui()
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just launch Snapper, not any specific environment.
				Config.runProgram("Snapper")
			else
				Run(Snapper.buildURL(data["COMM_ID"], data["INI"], data["ID"])) ; data["ID"] can contain a comma-delimited list if that's what the user entered
		}
#If


#If Config.machineIsWorkLaptop
	^+!t::
		selectOutlookTLG() {
			data := new Selector("outlookTLG.tls").selectGui()
			if(!data)
				return
			
			combinedMessage := data["BASE_MESSAGE"]
			if(data["BASE_MESSAGE"] && data["MESSAGE"])
				combinedMessage .= " - " ; Hyphen in between base message and normal message
			combinedMessage .= data["MESSAGE"]
			
			textToSend := Config.private["OUTLOOK_TLG_BASE"]
			textToSend := textToSend.replaceTag("TLP",      data["TLP"])
			textToSend := textToSend.replaceTag("CUSTOMER", data["CUSTOMER"])
			textToSend := textToSend.replaceTag("DLG",      data["DLG"])
			textToSend := textToSend.replaceTag("MESSAGE",  combinedMessage)
			
			if(Config.isWindowActive("Outlook Calendar TLG")) {
				SendRaw, % textToSend
				Send, {Enter}
			} else {
				setClipboardAndToastError(textToSend, "", "Outlook TLG calendar not focused.")
			}
		}
	
	^+!r::
		selectThunder() {
			data := new Selector("epicEnvironments.tls").SetTitle("Launch Thunder Environment").selectGui()
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just show Thunder itself, don't launch an environment.
				Config.activateProgram("Thunder")
			else
				Config.runProgram("Thunder", data["THUNDER_ID"])
		}
	
	!+v::
		selectVDI() {
			data := new Selector("epicEnvironments.tls").SetTitle("Launch VDI for Environment").selectGui()
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") { ; Special keyword - just show VMWare itself, don't launch a specific VDI.
				Config.runProgram("VMware Horizon Client")
			} else {
				EpicLib.runVDI(data["VDI_ID"])
				
				; Also fake-maximize the window once it shows up.
				WinWaitActive, ahk_exe vmware-view.exe, , 10, VMware Horizon Client ; Ignore the loading-type popup that happens initially with excluded title.
				if(ErrorLevel) ; Set if we timed out or if somethign else went wrong.
					return
				WindowLib.fakeMaximize()
			}
		}
	
	#p::
		selectPhone() {
			selectedText := getSelectedText().firstLine().clean()
			
			if(PhoneLib.isValidNumber(selectedText)) {
				PhoneLib.call(selectedText)
			} else {
				data := new Selector("phone.tls").selectGui()
				if(data)
					PhoneLib.call(data["NUMBER"], data["NAME"])
			}
		}
#If
