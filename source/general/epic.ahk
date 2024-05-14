; Work-specific hotkeys

; Universal open of EMC2 objects from title.
; Note that some programs override this if they have special ways of providing the record string or INI/ID/title.
$!e::getEMC2ObjectFromCurrentTitle().openEdit()
$!w::getEMC2ObjectFromCurrentTitle().openWeb()
	getEMC2ObjectFromCurrentTitle() {
		; We have to check this directly instead of putting it under an #If directive, so that the various program-specific #If directives win.
		if(!Config.contextIsWork) {
			HotkeyLib.waitForRelease()
			Send, % A_ThisHotkey.removeFromStart("$")
			return ""
		}
		
		record := EpicLib.selectEMC2RecordFromText(WinGetTitle("A"))
		if(!record)
			return ""
		
		return new ActionObjectEMC2(record.id, record.ini)
	}

#If Config.contextIsWork ; Any work machine
	^!+d:: Send, % selectTLGId("Select EMC2 Record to Send").removeFromStart("P.").removeFromStart("Q.")
	^!#d:: selectTLGActionObject("Select EMC2 Record to View").openWeb()
	^!+#d::selectTLGActionObject("Select EMC2 Record to Edit").openEdit()
	selectTLGId(title) {
		s := new Selector("tlg.tls").setTitle(title).overrideFieldsOff()
		s.dataTableList.filterOutIfColumnBlank("RECORD")
		s.dataTableList.filterOutIfColumnMatch("RECORD", "GET") ; Special keyword used for searching existing windows, can search for that with ^!i instead.
		return s.selectGui("RECORD")
	}
	selectTLGActionObject(title) {
		recId := selectTLGId(title)
		if(!recId)
			return ""
		
		if(recId.startsWith("P.")) {
			recId := recId.removeFromStart("P.")
			recINI := "PRJ"
		} else if(recId.startsWith("Q.")) {
			recId := recId.removeFromStart("Q.")
			recINI := "QAN"
		} else if(recId.startsWith("S.")) {
			recId := recId.removeFromStart("S.")
			recINI := "SLG"
		} else {
			recINI := "DLG"
		}
		
		return new ActionObjectEMC2(recId, recINI)
	}
	
	^+!#h::
		selectHyperspace() {
			data := EpicLib.selectEpicEnvironment("Launch Classic Hyperspace in Environment")
			if(data)
				EpicLib.runHyperspace(data["VERSION"], data["COMM_ID"], data["TIME_ZONE"])
		}
		
	^!#h::
		selectHSWeb() {
			data := EpicLib.selectEpicEnvironment("Launch Standalone HSWeb in Environment")
			if(data["HSWEB_URL"])
				Run(data["HSWEB_URL"])
		}
	
	^!+h::
		selectHyperdrive() {
			data := EpicLib.selectEpicEnvironment("Launch Hyperdrive in Environment")
			if(data)
				EpicLib.runHyperdrive(data["COMM_ID"], data["TIME_ZONE"])
		}
	
	^!+i::
		selectEnvironmentId() {
			data := EpicLib.selectEpicEnvironment("Insert ID for Environment")
			if(data["ENV_ID"]) {
				Send, % data["ENV_ID"]
				Send, {Enter} ; Submit it too.
			}
		}
	
	^!#s::
		selectSnapper() {
			selectedText := SelectLib.getText()
			record := new EpicRecord().initFromRecordString(selectedText)
			
			; Don't include invalid INIs (anything that's not 3 characters)
			if(record.ini && record.ini.length() != 3)
				record := ""
			
			s := new Selector("epicEnvironments.tls").setTitle("Open Record(s) in Snapper in Environment")
			s.addOverrideFields(["INI", "ID"]).setDefaultOverrides({"INI":record.ini, "ID":record.id}) ; Add fields for INI/ID and default in any values that we figured out
			data := s.selectGui()
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just launch Snapper, not any specific environment.
				Config.runProgram("Snapper")
			else
				Snapper.addRecords(data["COMM_ID"], data["INI"], data["ID"]) ; data["ID"] can contain a list or range if that's what the user entered
		}
	
	; Turn clipboard into standard EMC2 string and send it.
	!+n:: sendStandardEMC2ObjectString()
	!+#n::sendStandardEMC2ObjectString(true) ; ID only
	sendStandardEMC2ObjectString(idOnly := false) {
		HotkeyLib.waitForRelease()
		
		record := EpicLib.selectEMC2RecordFromText(clipboard)
		if(!record)
			return
		ini := record.ini
		id  := record.id
		
		if(idOnly)
			Send, % id
		else if(Config.isWindowActive("Chrome Workplans"))
			ClipboardLib.send(EpicLib.buildEMC2ObjectString(record, true)) ; Put title first for workplans
		else
			ClipboardLib.send(EpicLib.buildEMC2ObjectString(record)) ; Must send with clipboard because it can contain hotkey chars
		
		; Special case for OneNote: link the INI/ID as well.
		if(Config.isWindowActive("OneNote"))
			OneNote.linkEMC2ObjectInLine(ini, id)
	}

	; Pull EMC2 record IDs from currently open window titles and prompt the user to send one.
	^!i::
		sendEMC2RecordID() {
			record := EpicLib.selectEMC2RecordFromUsefulTitles()
			if(record)
				SendRaw, % record.id
		}

#If Config.machineIsWorkDesktop ; Main work desktop only
	^!+r::
		selectThunder() {
			data := EpicLib.selectEpicEnvironment("Launch Thunder for Environment", Config.getProgramPath("Thunder"))
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just show Thunder itself, don't launch an environment.
				Config.activateProgram("Thunder")
			else
				EpicLib.runThunderForEnvironment(data["ENV_ID"])
		}
	
	^!+v::
		selectVDI() {
			data := EpicLib.selectEpicEnvironment("Launch VDI for Environment")
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
				
				monitorWorkArea := MonitorLib.getWorkAreaForWindow(titleString)
				new VisualWindow("A").resizeMove("100%", "100%", VisualWindow.X_Centered, VisualWindow.Y_Centered)
			}
		}
#If
