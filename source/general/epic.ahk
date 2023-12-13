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

#If Config.contextIsWork ; Any work machine =--
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

#If Config.machineIsWorkDesktop ; Main work desktop only (not other work machines) ---
	^!+t::
		selectOutlookTLG() {
			s := new Selector("tlg.tls").setTitle("Select EMC2 Record ID")
			s.dataTableList.filterOutIfColumnNoMatch("IS_OLD", "") ; Filter out old records (have a value in the OLD column)
			data := s.selectGui()
			if(!data)
				return
			
			; We can do an additional Selector popup to grab ID (and potentially title) from various window titles.
			recId := data["RECORD"]
			if(recId = "GET") {
				record := EpicLib.selectEMC2RecordFromUsefulTitles(true) ; true - only want options with a title.
				if(!record)
					return
				
				recId := record.id
				if(["PRJ", "QAN", "SLG"].contains(record.ini))
					recId := record.ini.charAt(1) "." recId ; Add on the INI prefix so the ID goes in the right position.
				
				if(record.title)
					data["NAME"] := record.title
			}
			if(recId = "-") ; Placeholder I can manually enter to force a blank value.
				recId := ""
			
			; Message is a combination of a few things
			message := data["NAME_OUTPUT_PREFIX"] ; Start with any given prefix
			if(data["IS_GENERIC"]) 
				message .= data["MESSAGE"] ? data["MESSAGE"] : data["NAME"] ; Generic TLPs - use add the message, defaulting to the name.
			else ; Everything else: 
				message .= data["NAME"].appendPiece(" - ", data["MESSAGE"]) ; Everything else: add name + message.
			
			; Record field can contain DLG (no prefix), PRJ (P.), QAN (Q.), or SLG (S.) IDs.
			if(recId.startsWith("P."))
				prjId := recId.removeFromStart("P.")
			else if(recId.startsWith("Q."))
				qanId := recId.removeFromStart("Q.")
			else if(recId.startsWith("S."))
				slgId := recId.removeFromStart("S.")
			else
				dlgId := recId
			
			; Build the event title string
			eventTitle := Config.private["OUTLOOK_TLG_BASE"]
			eventTitle := eventTitle.replaceTag("MESSAGE",  message) ; Replace the message first in case it contains any of the following tags
			eventTitle := eventTitle.replaceTag("TLP",      data["TLP"])
			eventTitle := eventTitle.replaceTag("CUSTOMER", data["CUSTOMER"])
			eventTitle := eventTitle.replaceTag("SLG",      slgId)
			eventTitle := eventTitle.replaceTag("DLG",      dlgId)
			eventTitle := eventTitle.replaceTag("PRJ",      prjId)
			eventTitle := eventTitle.replaceTag("QAN",      qanId)
			
			replaceExtraEventTitleSlashes(eventTitle)
			
			if(Outlook.isTLGCalendarActive()) {
				SendRaw, % eventTitle
				Send, {Enter}
			} else {
				ClipboardLib.setAndToastError(eventTitle, "event string", "Outlook TLG calendar not focused.")
			}
		}
		; We only need slashes before the last non-blank element before the comma (i.e. always 1 after the
		; TLP, but after that we only need enough to put the last element in the right spot). Remove the
		; extras to clean up the display.
		replaceExtraEventTitleSlashes(ByRef title) {
			idString := title.beforeString(", ")
			message := title.afterString(", ")
			
			Loop {
				if(!idString.endsWith("/")) ; Should only remove trailing slashes, not anything at the start or in the middle.
					Break
				if(idString.countMatches("/") <= 1) ; Keep at least one slash (after the TLP) for conditional formatting to use.
					Break
				idString := idString.removeFromEnd("/")
			}
			
			; String it back together to return.
			title := idString ", " message
		}
	
	^!+r::
		selectThunder() {
			data := EpicLib.selectEpicEnvironment("Launch Thunder for Environment")
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just show Thunder itself, don't launch an environment.
				Config.activateProgram("Thunder")
			else
				Config.runProgram("Thunder", data["THUNDER_ID"])
		}
	
	!+v::
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
				new VisualWindow("A").resizeMove(VisualWindow.Width_Full, VisualWindow.Height_Full, VisualWindow.X_Centered, VisualWindow.Y_Centered)
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
#If ; --=
