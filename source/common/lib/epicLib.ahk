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
		this.splitServerLocation(serverLocation, routine, tag)
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
	
	;---------
	; DESCRIPTION:    Check whether the given string COULD be an EMC2 record ID - these are numeric except certain DLGs
	;                 that have prefixes (I, T, CS, etc).
	; PARAMETERS:
	;  id (I,REQ) - Possible ID to evaluate.
	; RETURNS:        true if possibly an ID, false otherwise.
	;---------
	couldBeEMC2ID(id) {
		; For special DLG IDs (SUs, TDE, searches, etc.), trim off leading letter so we recognize them as a numeric ID.
		if(id.startsWithAnyOf(["I", "T", "CS"], letter))
			id := id.removeFromStart(letter)
		
		return id.isNum()
	}
	
	
	couldBeEMC2Record(ini, id) { ; Checks whether this is PLAUSIBLY an EMC2 INI/ID, based on INI and ID format - no guarantee that it exists.
		; Need both INI and ID.
		if(ini = "" || id = "")
			return false
		
		; ID format check
		if(!this.couldBeEMC2ID(id))
			return false
		
		; INI check
		tempINI := this.convertToUsefulEMC2INI(ini)
		if(tempINI = "")
			return false
		
		return true
	}
	
	;---------
	; DESCRIPTION:    Convert the given "INI" into the useful version of itself.
	; PARAMETERS:
	;  ini (I,REQ) - The ini to convert, can be any of:
	;                 - Normal INI (DLG, zdq)
	;                 - Special INI that we want a different version of (ZQN => QAN)
	;                 - Word that describes an INI (Design, log, development log)
	; RETURNS:        The useful form of the INI, or "" if we couldn't match the input to one.
	;---------
	convertToUsefulEMC2INI(ini) {
		; Don't allow numeric "INIs" - they're just picking choices from the Selector, not converting a valid value.
		if(ini.isNum())
			return ""
		
		s := this.getEMC2TypeSelector()
		return s.selectChoice(ini, "SUBTYPE") ; Silent selection - no popup.
	}
	
	
	getBestEMC2RecordFromText(text) {
		this.extractEMC2RecordsFromText(text, exacts, possibles)
		
		; Return the first exact match, then the first possible match.
		return DataLib.coalesce(exacts[1], possibles[1])
	}
	
	
	copyEMC2RecordIDFromText(text) {
		if(!text) {
			Toast.ShowError("Could not copy EMC2 record ID from string", "String is blank")
			return ""
		}
		
		record := this.selectEMC2RecordFromText(text)
		if(!record) {
			Toast.ShowError("Could not copy EMC2 record ID from string", "No potential EMC2 record IDs found in provided text: " text)
			return ""
		}
		
		ClipboardLib.setAndToast(record.id, "EMC2 " record.ini " ID")
	}
	
	
	selectEMC2RecordFromText(text) {
		if(!this.extractEMC2RecordsFromText(text, exacts, possibles)) {
			; No matches at all
			Toast.ShowError("No potential EMC2 record IDs found in string: " text)
			return ""
		}
		; DEBUG.POPUP("text",text, "exacts",exacts, "possibles",possibles)
		
		; Only 1 exact match, just return it directly (ignoring any possibles).
		if(exacts.length() = 1)
			return exacts[1]
		
		; Prompt the user (even if there's just 1 possible, this gives them the opportunity to enter the INI)
		data := this.selectFromEMC2RecordMatches(exacts, possibles)
		if(!data) ; User didn't pick an option
			return ""
		
		return new EpicRecord(data["INI"], data["ID"], data["TITLE"])
	}
	
	
	selectEMC2RecordFromUsefulTitles() {
		windows := this.getUsefulEMC2RecordWindows()
		; Debug.popup("windows",windows)
		
		allExacts    := []
		allPossibles := []
		For _,window in windows {
			if(this.extractEMC2RecordsFromText(window.title, exacts, possibles, window.windowName)) {
				allExacts.appendArray(exacts)
				allPossibles.appendArray(possibles)
			}
		}
		; Debug.popup("allExacts",allExacts, "allPossibles",allPossibles)
		
		; No exacts or possibles
		if(allExacts.length() + allPossibles.length() = 0) {
			Toast.ShowError("No potential EMC2 record IDs found.")
			return ""
		}
		
		; Only 1 exact match, just return it directly (ignoring any possibles).
		if(allExacts.length() = 1)
			return allExacts[1]
		
		; Prompt the user (even if there's just 1 possible, this gives them the opportunity to enter the INI)
		data := this.selectFromEMC2RecordMatches(allExacts, allPossibles)
		if(!data) ; User didn't pick an option
			return ""
		
		return new EpicRecord(ini, data["ID"], data["TITLE"])
	}
	
	;---------
	; DESCRIPTION:    Clean up and trim an EMC2 record's title.
	; PARAMETERS:
	;  title (I,REQ) - The title to clean.
	;  ini   (I,OPT) - INI of the record if we should remove it.
	;  id    (I,OPT) - ID  of the record if we should remove it.
	; RETURNS:        The title, but with extraneous bits (like the INI, ID, and "DBC" prefix) removed.
	;---------
	cleanEMC2RecordTitle(title, ini := "", id := "") {
		; Take INI and ID (and anything in between) out if they're given.
		iniAndID := ini title.firstBetweenStrings(ini, id) id
		title := title.remove(iniAndID)
		
		; The "DBC" prefix isn't helpful when most of my records have it.
		title := title.removeFromStart("DBC")
		
		return title.clean(["-", "/", "\", ":"])
	}
	
	
	; #PRIVATE#
	
	emc2TypeSelector := "" ; Selector instance (performance cache)
	
	;---------
	; DESCRIPTION:    Get a Selector instance you can use to map various INI-like strings to actual EMC2 INIs.
	; RETURNS:        Selector instance
	;---------
	getEMC2TypeSelector() {
		if(this.emc2TypeSelector)
			return this.emc2TypeSelector
		
		; Use ActionObject's TLS (filtered to EMC2-type types) for mapping INIs
		s := new Selector("actionObject.tls")
		s.dataTableList.filterByColumn("TYPE", ActionObject.Type_EMC2)
		
		this.emc2TypeSelector := s ; Cache for future use
		
		return s
	}
	
	
	getUsefulEMC2RecordWindows() {
		windows := [] ; [ {windowName, title} ]
		
		; Normal titles
		For _,windowName in ["EMC2", "EpicStudio", "Visual Studio", "Explorer"] {
			title := Config.windowInfo[windowName].getCurrTitle()
			windows.push({windowName:windowName, title:title})
		}
		
		; Special "titles" that are further cleaned, or extracted from inside the window(s)
		For i,title in Chrome.getAllWindowTitles() ; Chrome window titles
			windows.push({windowName:"Chrome", title:title})
		For i,title in Outlook.getAllMessageTitles() ; Outlook message titles
			windows.push({windowName:"Outlook", title:title})
		windows.push({windowName:"VB6", title:"DLG " VB6.getDLGIdFromProject()}) ; VB6 (sidebar title from project group)
		
		return windows
	}
	
	
	extractEMC2RecordsFromText(text, ByRef exacts := "", ByRef possibles := "", windowName := "") {
		exacts    := []
		possibles := []
		
		; Make sure the text is in a decent state to be parsed.
		text := text.clean()
		
		; First, give EpicRecord's parsing logic a shot - since most titles are close to this format, it gives us the best chance at a nicer title.
		record := new EpicRecord().initFromRecordString(text)
		if(this.couldBeEMC2Record(record.ini, record.id)) {
			record.label := windowName
			record.title := this.cleanEMC2RecordTitle(record.title, record.ini, record.id)
			exacts.push(record)
		}
		
		; Split up the text and look for potential IDs.
		textBits := text.split([" ", ",", "-", "(", ")", "[", "]", "/", "\", ":", ".", "#"], " ").removeEmpties()
		For i,id in textBits {
			; Extract other potential info
			ini := textBits[i - 1] ; INI is assumed to be the piece just before the ID.
			recordTitle := this.cleanEMC2RecordTitle(text, ini, id)
			
			; Match: Valid INI + ID.
			if(this.couldBeEMC2Record(ini, id)) {
				exacts.push(new EpicRecord(ini, id, recordTitle, windowName))
				Continue
			}
			
			; Possible: ID has potential, but no valid INI.
			if(this.couldBeEMC2ID(id))
				possibles.push(new EpicRecord("", id, recordTitle, windowName))
		}
		
		; origExacts := exacts.clone() ; GDB TODO remove
		; origPossibles := possibles.clone()
		
		; GDB TODO consider handling these two with a Functor object approach - a DataLib function for removing duplicates, and a reference to a function that returns whether/which element to remove.
		; Remove duplicate entries.
		For i,exact1 in exacts.clone() {
			For j,exact2 in exacts.clone() {
				; Same element.
				if(i = j)
					Continue
				
				if(exact1.id = exact2.id) {
					; If the titles (or title lengths) match too, just drop the later one.
					if(exact1.title = exact2.title || exact1.title.length() = exact2.title.length())
						exacts.removeAt(max(i, j))
					
					; Otherwise, keep the one with the shorter (and presumably nicer) title.
					else if(exact1.title.length() > exact2.title.length())
						exacts.removeAt(i)
					else
						exacts.removeAt(j)
				}
			}
		}
		; Filter out possibles for IDs we already have in exacts.
		For _,exact in exacts.clone() {
			For j,possible in possibles.clone() {
				if(exact.id = possible.id)
					possibles.removeAt(j)
			}
		}
		; Debug.popup("textBits",textBits, "origExacts",origExacts, "origPossibles",origPossibles, "exacts",exacts, "possibles",possibles)
		
		; Convert all exact maches' INIs.
		For i,exact in exacts
			exacts[i].ini := EpicLib.convertToUsefulEMC2INI(exact.ini)
		
		; Debug.popup("textBits",textBits, "exacts",exacts, "possibles",possibles)
		return (exacts.length() + possibles.length()) > 0
	}
	
	;---------
	; DESCRIPTION:    Build a Selector and ask the user to pick from the matches we found.
	; PARAMETERS:
	;  exacts   (I,REQ) - Associative array of confirmed EpicRecord objects, from extractEMC2RecordsFromText.
	;  possibles (I,REQ) - Associative array of potential EpicRecord objects, from extractEMC2RecordsFromText.
	; RETURNS:        Data array from Selector.selectGui().
	;---------
	selectFromEMC2RecordMatches(exacts, possibles) {
		s := new Selector().setTitle("Select EMC2 Object to use:").addOverrideFields({1:"INI"})
		
		abbrevNums := {} ; {letter: lastUsedNumber}
		s.addSectionHeader("Full matches")
		For _,record in exacts
			s.addChoice(this.buildChoiceFromEMC2Record(record, abbrevNums))
		
		s.addSectionHeader("Potential IDs")
		For _,record in possibles
			s.addChoice(this.buildChoiceFromEMC2Record(record, abbrevNums))
		
		return s.selectGui()
	}
	
	;---------
	; DESCRIPTION:    Turn the provided EpicRecord object into a SelectorChoice to show to the user.
	; PARAMETERS:
	;  record      (I,REQ) - EpicRecord object to use.
	;  abbrevNums (IO,REQ) - Associative array of abbreviation letters to counts, used to generate unique abbreviations. {letter: lastUsedNumber}
	; RETURNS:        SelectorChoice instance describing the provided record.
	;---------
	buildChoiceFromEMC2Record(record, ByRef abbrevNums) {
		ini        := record.ini
		id         := record.id
		title      := record.title
		windowName := record.label
		
		name := ""
		if(windowName)
			name .= windowName " - "
		if(ini)
			name .= ini " "
		name .= id
		if(title)
			name .= " - " title
		
		; Abbreviation is INI first letter + a counter.
		if(ini = "")
			abbrevLetter := "u" ; Unknown INI
		else
			abbrevLetter := StringLower(ini.charAt(1))
		abbrevNum := DataLib.forceNumber(abbrevNums[abbrevLetter]) + 1
		abbrevNums[abbrevLetter] := abbrevNum
		abbrev := abbrevLetter abbrevNum
		
		return new SelectorChoice({NAME:name, ABBREV:abbrev, INI:ini, ID:id, TITLE:title})
	}
	; #END#
}


