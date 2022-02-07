; Various Epic utility functions.

class EpicLib {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Run Hyperspace locally for the given version and environment.
	; PARAMETERS:
	;  version     (I,REQ) - Dotted Hyperspace version
	;  environment (I,OPT) - EpicComm ID for the environment to connect to.
	;---------
	runHyperspace(version, environment) {
		Run(Config.private["HYPERSPACE_BASE"].replaceTags({"VERSION":version, "VERSION_FLAT": version.remove(".") , "ENVIRONMENT":environment}))
	}
	
	;---------
	; DESCRIPTION:    Open a VDI matching the given ID.
	; PARAMETERS:
	;  vdiId (I,REQ) - The ID of the VDI to open.
	;---------
	runVDI(vdiId) {
		Run(Config.private["VDI_BASE"].replaceTag("VDI_ID", vdiId))
	}
	
	;---------
	; DESCRIPTION:    Split the given server location into tag and routine.
	; PARAMETERS:
	;  serverLocation (I,REQ) - The location in server code to split.
	;  routine        (O,OPT) - The routine
	;  tag            (O,OPT) - The tag. May include offset, see notes below.
	; NOTES:          Any offset from a tag will be included in the tag return value (i.e.
	;                 TAG+3^ROUTINE splits into routine=ROUTINE and tag=TAG+3).
	;---------
	splitServerLocation(serverLocation, ByRef routine := "", ByRef tag := "") {
		serverLocation := serverLocation.clean(["$", "(", ")"])
		locationAry := serverLocation.split("^")
		
		maxIndex := locationAry.MaxIndex()
		if(maxIndex > 1)
			tag := locationAry[1]
		routine := locationAry[maxIndex] ; Always the last piece (works whether there was a tag before it or not)
	}
	
	;---------
	; DESCRIPTION:    Drop the offset ("+4" in "tag+4^routine", can also be negative) from the
	;                 given server (so we'd return "tag^routine").
	; PARAMETERS:
	;  serverLocation (I,REQ) - The server location to drop the offset from.
	; RETURNS:        The updated server code location.
	;---------
	dropOffsetFromServerLocation(serverLocation) {
		EpicLib.splitServerLocation(serverLocation, routine, tag)
		tag := tag.beforeString("+").beforeString("-")
		return tag "^" routine
	}
	
	;---------
	; DESCRIPTION:    Given a file path, convert it to a "source-relative" path - that is, the relative path between the
	;                 source root folder (DLG-* or App *) and the given location.
	; PARAMETERS:
	;  path (I,REQ) - The path to convert.
	; RETURNS:        Relative path with leading backslash.
	;---------
	convertToSourceRelativePath(path) {
		path := FileLib.cleanupPath(path)
		
		sourceRoot := Config.path["EPIC_SOURCE_CURRENT"] "\"
		if(!path.startsWith(sourceRoot)) {
			ClipboardLib.setAndToastError(path, "path", "Could not copy source-relative path", "Path is not in source root")
			return ""
		}
		path := path.removeFromStart(sourceRoot)
		
		; Strip off one more parent - it's either one of the main folders (App *) or a DLG folder (DLG-*)
		path := "\" path.afterString("\") ; Keep the leading backslash
		
		return path
	}
	
	;---------
	; DESCRIPTION:    Find the source folder of the current version, by looking for the biggest version number we have a
	;                 folder for.
	; RETURNS:        Full path to the current version's source folder (no trailing backslash).
	;---------
	findCurrentVersionSourceFolder() {
		latestVersion := 0.0
		latestPath := ""
		
		Loop, Files, C:\EpicSource\*, D
		{
			; Only consider #[#].# folders
			if(!A_LoopFileName.matchesRegEx("\d{1,2}\.\d"))
				Continue
			
			if(A_LoopFileName > latestVersion) {
				latestVersion := A_LoopFileName
				latestPath := A_LoopFileLongPath
			}
		}
		
		return latestPath
	}
	
	;---------
	; DESCRIPTION:    Finds the current path to the latest installed version of EMC2.
	; RETURNS:        Full filepath (including the EpicD*.exe) for the latest installed version of EMC2.
	;---------
	findCurrentEMC2Path() {
		latestVersion := 0.0
		latestEMC2Folder := ""
		
		Loop, Files, C:\Program Files (x86)\Epic\v*.*, D
		{
			; Only consider versions where there's an EMC2 directory
			if(!FileLib.folderExists(A_LoopFileLongPath "\EMC2"))
				Continue
			
			version := A_LoopFileName.removeFromStart("v")
			if(version > latestVersion) {
				latestVersion := version
				latestEMC2Folder := A_LoopFileLongPath "\EMC2"
			}
		}
			
		return latestEMC2Folder "\Shared Files\EpicD" latestVersion.remove(".") ".exe"
	}
	
	; GDB TODO could we pull in a record title somehow?
	;	- Could use for display in Selector (after INI + ID)
	;  - Could be nice for figuring out where the random # choices came from
	;	- Would probably require different structure for matches/possibles
	selectEMC2RecordFromWindowTitles() { ; Assumption: any given ID will go with exactly 1 INI - I'm unlikely to ever see multiple.
		winTitles := []
		For _,winId in WinGet("List")
			winTitles.push(WinGetTitle("ahk_id " winId))
		
		; Add in titles from a few special spots
		winTitles.appendArray(this.getSpecialTitles())
		
		this.getMatchesFromTitles2(winTitles, matches, possibles)
		Debug.popup("matches",matches, "possibles",possibles)
		; return
		
		if(matches.count() = 0 && possibles.count() = 0) {
			Toast.ShowError("No potential EMC2 record IDs found in window titles")
			return ""
		}
		
		s := new Selector().setTitle("Select EMC2 Object to use:").addOverrideFields({1:"INI"})
		
		s.addSectionHeader("EMC2 Records", 1)
		lastChoiceNum := this.addChoicesToSelector(s, matches)
		
		s.addSectionHeader("Potential IDs", lastChoiceNum + 1)
		this.addChoicesToSelector(s, possibles)
		
		data := s.selectGui()
		if(!data) ; User didn't pick an option
			return ""
		
		record := new EpicRecord()
		record.id  := data["ID"]
		record.ini := data["INI"]
		return record
	}
	
	
	; #PRIVATE#
	
	
	getSpecialTitles() {
		titles := []
		
		; Outlook message titles
		titles.push(Outlook.getMessageTitle(Config.windowInfo["Outlook"].idString))
		
		; Explorer may be minimized to the tray.
		settings := new TempSettings().detectHiddenWindows("On")
		titles.push(WinGetTitle(Config.windowInfo["Explorer"].idString))
		settings.restore()
		
		return titles
	}
	
	
	getMatchesFromTitles(titles, ByRef matches, ByRef possibles) {
		
		; GDB TODO compare this result to getMatchesFromTitles2() once I finish refactoring there.
		
		matches   := {} ; {id: EpicRecord}
		possibles := {} ; {id: EpicRecord} (ini always "")
		
		; matches   := {} ; {id: ini}
		; possibles := {} ; {id: ""}
		
		For _,title in titles {
			
			; First, try EpicRecord's parsing logic to see if we get something useful.
			record := new EpicRecord().initFromRecordString(title)
			if(ActionObjectEMC2.isThisType("", record.ini, record.id)) {
				matches[record.id] := record
				Continue
			}
			
			titleBits := title.split([" ", ",", "-", "(", ")", "[", "]", "/", "\", ":", "."], " ").removeEmpties()
			For i,potentialId in titleBits {
				; Check whether this particular bit could even possibly be an ID.
				if(!this.isPossibleEMC2ID(potentialId))
					Continue
				
				; We've already had a proper match to this ID.
				if(matches[potentialId])
					Continue
				
				; Build the EpicRecord we'll save off. ; GDB TODO should we just combine both loops so we don't have to use this as the data structure?
				record := new EpicRecord()
				record.id    := potentialId
				record.ini   := ""
				record.title := title
				
				; First elements are always possible - they could be an ID, but we don't know the INI that goes with them.
				if(i = 1) {
					possibles[potentialId] := record
					Continue
				}
				
				; Try for a proper match using the potential INI just before our ID.
				ini := titleBits[i-1]
				id  := record.id
				if(!ActionObjectEMC2.isThisType("", ini, id)) {
					possibles[potentialId] := record
					Continue
				}
				
				; Found a proper match, save it off.
				record.ini := ini
				matches[id] := record
				possibles.delete(id) ; If we have the same ID already in possibles, remove it.
			}
		}
	}
	
	
	getMatchesFromTitles2(titles, ByRef matches, ByRef possibles) {
		
		; GDB TODO switch over to using EMC2Record, with its special pre/post-processing handling for email subjects and the like.
		
		
		matches   := {} ; {id: EpicRecord}
		possibles := {} ; {id: EpicRecord} (ini always "")
		
		; matches   := {} ; {id: ini}
		; possibles := {} ; {id: ""}
		
		For _,title in titles {
			
			; First, try EpicRecord's parsing logic to see if we get something useful.
			record := new EpicRecord().initFromRecordString(title)
			if(ActionObjectEMC2.isThisType("", record.ini, record.id)) {
				matches[record.id] := record
				Continue
			}
			
			titleBits := title.split([" ", ",", "-", "(", ")", "[", "]", "/", "\", ":", "."], " ").removeEmpties()
			For i,potentialId in titleBits {
				; Check whether this particular bit could even possibly be an ID.
				if(!this.isPossibleEMC2ID(potentialId))
					Continue
				
				; We've already had a proper match to this ID.
				if(matches[potentialId])
					Continue
				
				; Build the EpicRecord we'll save off. ; GDB TODO should we just combine both loops so we don't have to use this as the data structure?
				record := new EpicRecord()
				record.id    := potentialId
				record.ini   := ""
				record.title := title
				
				; First elements are always possible - they could be an ID, but we don't know the INI that goes with them.
				if(i = 1) {
					possibles[potentialId] := record
					Continue
				}
				
				; Try for a proper match using the potential INI just before our ID.
				ini := titleBits[i-1]
				id  := record.id
				if(!ActionObjectEMC2.isThisType("", ini, id)) {
					possibles[potentialId] := record
					Continue
				}
				
				; Found a proper match, save it off.
				record.ini := ini
				matches[id] := record
				possibles.delete(id) ; If we have the same ID already in possibles, remove it.
			}
		}
	}
	
	
	addChoicesToSelector(s, options) { ; Assumes no overlap in abbreviation letters between different times this is called.
		lastChoiceNum := 0
		
		abbrevNums := {} ; letter: lastUsedNumber
		For id,record in options {
			ini := record.ini
			title := record.title
			
			if(ini = "")
				abbrevLetter := "u" ; Unknown INI
			else
				abbrevLetter := StringLower(ini.charAt(1))
			
			abbrevNum := DataLib.forceNumber(abbrevNums[abbrevLetter]) + 1
			abbrevNums[abbrevLetter] := abbrevNum
			abbrev := abbrevLetter abbrevNum
			
			name := ini.appendPiece(id, " ")
			name .= " - " title
			
			; DEBUG.POPUP("id",id, "record",record, "ini",ini, "title",title, "abbrevNum",abbrevNum, "abbrevNums",abbrevNums, "name",name)
			
			lastChoiceNum := s.addChoice(new SelectorChoice({NAME:name, ABBREV:abbrev, INI:ini, ID:id}))
		}
		
		return lastChoiceNum
	}
	
	;---------
	; DESCRIPTION:    Check whether the given string COULD be an EMC2 record ID - these are numeric except for SUs and TDE
	;                 logs, which start with I and T respectively.
	; PARAMETERS:
	;  id (I,REQ) - Possible ID to evaluate.
	; RETURNS:        true if possibly an ID, false otherwise.
	;---------
	isPossibleEMC2ID(id) {
		; For SU DLG IDs, trim off leading letter so we recognize them as a numeric ID.
		if(id.startsWithAnyOf(["I", "T"], letter))
			id := id.removeFromStart(letter)
		
		return id.isNum()
	}
	
	; #END#
}


