; Work-specific hotkeys

; Universal open of EMC2 objects from title.
; Note that some programs override this if they have special ways of providing the record string or INI/ID/title.
$!e::getEMC2ObjectFromCurrentTitle().openEdit()
$!w::getEMC2ObjectFromCurrentTitle().openWeb()
	getEMC2ObjectFromCurrentTitle() {
		; We have to check this directly instead of putting it under an #If directive, so that the various program-specific #If directives win.
		if (!Config.contextIsWork) {
			HotkeyLib.waitForRelease()
			Send, % A_ThisHotkey.removeFromStart("$")
			return ""
		}
		
		record := EpicLib.selectEMC2RecordFromText(WinGetTitle("A"))
		if (!record)
			return ""
		
		return new ActionObjectEMC2(record.id, record.ini)
	}

#If Config.contextIsWork ; Any work machine
	;region TLG record IDs
	^!+d::
		sendTLGRecId() {
			idList := ""
			For _, recId in selectTLGRecIDs("Select EMC2 Record to Send")
				idList := idList.appendPiece(", ", recId.removeFromStart("P.").removeFromStart("Q."))
			Send, % idList
		}
	^!#d::
		webTLGRecs() {
			For _, ao in selectTLGActionObjects("Select EMC2 Record to View")
				ao.openWeb()
		}
	^!+#d::
		editTLGRecs() {
			For _, ao in selectTLGActionObjects("Select EMC2 Record to Edit")
				ao.openEdit()
		}
	
	selectTLGRecIDs(title) {
		emc2Path := Config.getProgramPath("EMC2")
		icon := FileLib.getParentFolder(emc2Path, 2) "\en-US\Images\emc2.ico" ; Icon is separate from the executable so we have to jump to it.

		s := new Selector("tlg.tls").setTitle(title).setIcon(icon).overrideFieldsOff()
		s.dataTableList.filterOutIfColumnBlank("RECORD")
		s.dataTableList.filterOutIfColumnMatch("RECORD", "GET") ; Special keyword used for searching existing windows, can search for that with ^!i instead.
		return s.promptMulti("RECORD")
	}
	selectTLGActionObjects(title) {
		actionObjects := []
		For _, recId in selectTLGRecIDs(title) {
			if (recId.startsWith("P."))
				actionObjects.push(new ActionObjectEMC2(recId.removeFromStart("P."), "PRJ"))
			else if (recId.startsWith("Q."))
				actionObjects.push(new ActionObjectEMC2(recId.removeFromStart("Q."), "QAN"))
			else if (recId.startsWith("S."))
				actionObjects.push(new ActionObjectEMC2(recId.removeFromStart("S."), "SLG"))
			else
				actionObjects.push(new ActionObjectEMC2(recId, "DLG"))
		}
		
		return actionObjects
	}
	;endregion TLG record IDs

	!+e::
		openEpicSourceFolder() {
			path := EpicLib.selectEpicSourceFolder("Select branch folder to open:", Config.getProgramPath("Explorer"))
			if(path)
				Run(path)
		}
	
	^!#r::
		openTerminalInEpicSourceFolder() {
			path := EpicLib.selectEpicSourceFolder("Select branch folder to open in terminal:", "C:\Program Files\Git\git-bash.exe")
			if(!path)
				return

			if(path = "LAUNCH")
				path := Config.path["EPIC_SOURCE_CURRENT"]
			
			Config.activateProgram("Windows Terminal", "--profile ""Git Bash"" --startingDirectory " path)
			
		}
	
	^+!#h::
		selectHyperspace() {
			environments := EpicLib.selectEpicEnvironments("Launch Classic Hyperspace in Environment")
			For _, env in environments
				EpicLib.runHyperspace(env["VERSION"], env["COMM_ID"], env["TIME_ZONE"])
		}
		
	^!#h::
		selectHSWeb() {
			environments := EpicLib.selectEpicEnvironments("Launch Standalone HSWeb in Environment", Config.getProgramPath("Chrome"))
			For _, env in environments
				Run(env["HSWEB_URL"])
		}
	
	^!+h::
		selectHyperdrive() {
			environments := EpicLib.selectEpicEnvironments("Launch Hyperdrive in Environment", Config.getProgramPath("Hyperdrive"))
			For _, env in environments
				EpicLib.runHyperdrive(env["COMM_ID"], env["TIME_ZONE"])
		}
	
	^!+i::
		selectEnvironmentId() {
			environments := EpicLib.selectEpicEnvironments("Insert ID for Environment")
			For _, env in environments {
				Send, % env["ENV_ID"]
				Send, {Enter} ; Submit it too.
			}
		}
	
	^!#s::
		selectSnapper() {
			selectedText := SelectLib.getText()
			record := new EpicRecord().initFromRecordString(selectedText)
			
			; Don't include invalid INIs (anything that's not 3 characters)
			if (record.ini && record.ini.length() != 3)
				record := ""
			
			s := new Selector("epicEnvironments.tls").setTitle("Open Record(s) in Snapper in Environment").setIcon(Config.getProgramPath("Snapper"))
			s.addOverrideFields(["INI", "ID"]).setDefaultOverrides({"INI":record.ini, "ID":record.id}) ; Add fields for INI/ID and default in any values that we figured out
			environments := s.promptMulti() ; Each individual element is for a specific environment, which also includes any specified records.
			For _, env in environments {
				if (env["COMM_ID"] = "LAUNCH") ; Special keyword - just launch Snapper, not any specific environment.
					Config.runProgram("Snapper")
				else
					Snapper.addRecords(env["COMM_ID"], env["INI"], env["ID"]) ; env["ID"] can contain a list or range if that's what the user entered
			}
		}
	
	; Turn clipboard into standard EMC2 string and send it.
	!+n:: sendStandardEMC2ObjectString()
	!+#n::sendStandardEMC2ObjectString(true) ; ID only
	sendStandardEMC2ObjectString(idOnly := false) {
		HotkeyLib.waitForRelease()
		
		record := EpicLib.selectEMC2RecordFromText(clipboard)
		if (!record)
			return
		ini := record.ini
		id  := record.id
		
		if (idOnly)
			Send, % id
		else if (Config.isWindowActive("Chrome Workplans"))
			ClipboardLib.send(EpicLib.buildEMC2ObjectString(record, true)) ; Put title first for workplans
		else
			ClipboardLib.send(EpicLib.buildEMC2ObjectString(record)) ; Must send with clipboard because it can contain hotkey chars
		
		; Special case for OneNote: link the INI/ID as well.
		if (Config.isWindowActive("OneNote"))
			OneNote.linkEMC2ObjectInLine(ini, id)
	}

	; Pull EMC2 record IDs from currently open window titles and prompt the user to send one.
	^!i::
		sendEMC2RecordID() {
			record := EpicLib.selectEMC2RecordFromUsefulTitles()
			if (record)
				SendRaw, % record.id
		}

#If Config.machineIsWorkDesktop ; Main work desktop only
	^!+r::
		selectThunder() {
			environments := EpicLib.selectEpicEnvironments("Launch Thunder for Environment", Config.getProgramPath("Thunder"))
			For _, env in environments {
				if (env["COMM_ID"] = "LAUNCH") ; Special keyword - just show Thunder itself, don't launch an environment.
					Config.activateProgram("Thunder")
				else
					EpicLib.runThunderForEnvironment(env["ENV_ID"])
			}
		}
	
	^!+v::
		selectVDI() {
			environments := EpicLib.selectEpicEnvironments("Launch VDI for Environment", Config.getProgramPath("VMware Horizon Client"))
			For _, env in environments {
				if (env["COMM_ID"] = "LAUNCH") { ; Special keyword - just show VMWare itself, don't launch a specific VDI.
					Config.runProgram("VMware Horizon Client")
				} else {
					EpicLib.runVDI(env["VDI_ID"])
					
					; Also fake-maximize the window once it shows up.
					if (environments.length() = 1) { ; But don't bother if we're dealing with multiple windows - just launch them all at once and I'll fix the size manually.
						WinWaitActive, ahk_exe vmware-view.exe, , 10, VMware Horizon Client ; Ignore the loading-type popup that happens initially with excluded title.
						if (!ErrorLevel) ; Set if we timed out or if somethign else went wrong.
							WindowPositions.fixWindow()
					}
				}
			}
		}
#If
