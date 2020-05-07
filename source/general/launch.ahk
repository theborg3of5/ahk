; Launch miscellaneous actions.

; Generic search for selected text.
!+f::SearchLib.selectedTextPrompt()

; Generic open - open a variety of different things based on the selected text.
^!#o::  new ActionObject(SelectLib.getText()).openWeb()
^!#+o:: new ActionObject(SelectLib.getText()).openEdit()

; Generic copy link - copy links to a variety of different things based on the selected text.
^!#l:: new ActionObject(SelectLib.getText()).copyLinkWeb()
^!#+l::new ActionObject(SelectLib.getText()).copyLinkEdit()

; Generic hyperlinker - get link based on the selected text and then apply it to that same text.
^!#k::  new ActionObject(SelectLib.getText()).linkSelectedTextWeb()
^!#+k:: new ActionObject(SelectLib.getText()).linkSelectedTextEdit()

; Selector to allow easy editing of config or code files that we edit often
!+c::
	selectEditFile() {
		path := new Selector("editFiles.tls").selectGui("PATH")
		if(!path)
			return
		
		path := Config.replacePathTags(path)
		if(!FileExist(path)) {
			new ErrorText("Script does not exist: " path).showMedium()
			return
		}
		
		Config.runProgram("Notepad++", path)
	}


#If Config.contextIsWork
	^!+d::Send, % selectTLGId().removeFromStart("P.")
	^!#d:: selectTLGActionObject().openWeb()
	^!+#d::selectTLGActionObject().openEdit()
	selectTLGId() {
		s := new Selector("tlg.tls").setTitle("Select DLG/PRJ ID").overrideFieldsOff()
		s.dataTableList.filterOutEmptyForColumn("DLG")
		return s.selectGui("DLG")
	}
	selectTLGActionObject() {
		recId := selectTLGId()
		if(!recId)
			return ""
		
		if(recId.startsWith("P.")) {
			recId := recId.removeFromStart("P.")
			recINI := "PRJ"
		} else {
			recINI := "DLG"
		}
		
		return new ActionObjectEMC2(recId, recINI)
	}
	
	^!+h::
		selectHyperspace() {
			data := new Selector("epicEnvironments.tls").setTitle("Launch Hyperspace in Environment").selectGui()
			if(data)
				EpicLib.runHyperspace(data["MAJOR"], data["MINOR"], data["COMM_ID"])
		}
	
	^!+i::
		selectEnvironmentId() {
			envId := new Selector("epicEnvironments.tls").selectGui("ENV_ID")
			if(envId) {
				Send, % envId
				Send, {Enter} ; Submit it too.
			}
		}
	
	^!#s::
		selectSnapper() {
			record := new EpicRecord(SelectLib.getText())
			
			s := new Selector("epicEnvironments.tls").setTitle("Open Record(s) in Snapper in Environment")
			s.addOverrideFields(["INI", "ID"]).setDefaultOverrides({"INI":record.ini, "ID":record.id}) ; Add fields for INI/ID and default in any values that we figured out
			data := s.selectGui()
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just launch Snapper, not any specific environment.
				Config.runProgram("Snapper")
			else
				Run(Snapper.buildURL(data["COMM_ID"], data["INI"], data["ID"])) ; data["ID"] can contain a list or range if that's what the user entered
		}
#If


#If Config.machineIsWorkLaptop
	^!+t::
		selectOutlookTLG() {
			data := new Selector("tlg.tls").selectGui()
			if(!data)
				return
			
			fullName := data["NAME_PREFIX"] data["NAME"]
			combinedMessage := fullName.appendPiece(data["MESSAGE"], " - ")
			
			textToSend := Config.private["OUTLOOK_TLG_BASE"]
			textToSend := textToSend.replaceTag("TLP",      data["TLP"])
			textToSend := textToSend.replaceTag("CUSTOMER", data["CUSTOMER"])
			textToSend := textToSend.replaceTag("DLG",      data["DLG"])
			textToSend := textToSend.replaceTag("MESSAGE",  combinedMessage)
			
			if(Outlook.isTLGCalendarActive()) {
				SendRaw, % textToSend
				Send, {Enter}
			} else {
				ClipboardLib.setAndToastError(textToSend, "event string", "Outlook TLG calendar not focused.")
			}
		}
	
	^!+r::
		selectThunder() {
			data := new Selector("epicEnvironments.tls").setTitle("Launch Thunder Environment").selectGui()
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just show Thunder itself, don't launch an environment.
				Config.activateProgram("Thunder")
			else
				Config.runProgram("Thunder", data["THUNDER_ID"])
		}
	
	!+v::
		selectVDI() {
			data := new Selector("epicEnvironments.tls").setTitle("Launch VDI for Environment").selectGui()
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
			selectedText := SelectLib.getCleanFirstLine()
			
			if(PhoneLib.isValidNumber(selectedText)) {
				PhoneLib.call(selectedText)
			} else {
				data := new Selector("phone.tls").selectGui()
				if(data)
					PhoneLib.call(data["NUMBER"], data["NAME"])
			}
		}
#If
