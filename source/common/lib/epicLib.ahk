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
	; DESCRIPTION:    Check whether the given string COULD be an EMC2 record ID - these are numeric except for SUs and TDE
	;                 logs, which start with I and T respectively.
	; PARAMETERS:
	;  id (I,REQ) - Possible ID to evaluate.
	; RETURNS:        true if possibly an ID, false otherwise.
	;---------
	couldBeEMC2ID(id) {
		; For SU DLG IDs, trim off leading letter so we recognize them as a numeric ID.
		if(id.startsWithAnyOf(["I", "T"], letter))
			id := id.removeFromStart(letter)
		
		return id.isNum()
	}
	
	
	couldBeEMC2Record(ByRef ini, id) { ; Checks whether this is PLAUSIBLY an EMC2 INI/ID, based on INI and ID format - no guarantee that it exists. Also converts INI to "proper" one.
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
		
		ini := tempINI ; Return "proper" INI
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
	
	
	extractEMC2RecordsFromTitle(title, ByRef possibles := "") { ; GDB TODO go over all of this logic again for further cleanup.
		; GDB TODO call out in header that there may be duplicate IDs + filter them out somewhere (maybe an extra parameter here to filter duplicates?)
		; GDB TODO consider combining matches and possibles into one array, with parameter that filters out possibles
		matches   := []
		possibles := []
		
		; GDB TODO do we want to use EpicRecord's record-string-parsing to clean up titles, or even give it first dibs on adding a match/possible?
		
		; Split up the title and look for potential IDs.
		titleBits := title.split([" ", ",", "-", "(", ")", "[", "]", "/", "\", ":", "."], " ").removeEmpties()
		For i,potentialId in titleBits {
			; Skip: this bit couldn't actually be an ID.
			if(!this.couldBeEMC2ID(potentialId))
				Continue
			
			; Possible: first element can't have a preceding INI.
			if(i = 1) {
				possibles.push(new EpicRecord("", potentialId, title))
				Continue
			}
			
			; Match: confirmed valid INI.
			ini := titleBits[i-1]
			id  := potentialId
			if(this.couldBeEMC2Record(ini, id)) {
				matches.push(new EpicRecord(ini, id, title))
				Continue
			}
			
			; Possible: no valid INI.
			possibles.push(new EpicRecord("", potentialId, title))
		}
		
		; Clean up title (remove INI/ID where possible) ; GDB TODO should we just be more aggressive removing the INI/ID + all separators, even from middle of string? Or at least doing this cleaner?
		For _,record in matches {
			tempRecord := new EpicRecord().initFromRecordString(record.title)
			record.title := tempRecord.title
		}
		For _,record in possibles {
			tempRecord := new EpicRecord().initFromRecordString(record.title)
			record.title := tempRecord.title
		}
		
		; Debug.popup("titleBits",titleBits, "matches",matches, "possibles",possibles)
		return matches
	}
	
	
	selectEMC2RecordFromTitle(title) {
		matches := this.extractEMC2RecordsFromTitle(title, possibles)
		
		; No matches or possibles
		if(matches.length() + possibles.length() = 0) {
			Toast.ShowError("No potential EMC2 record IDs found in window title: " title)
			return ""
		}
		
		; Only 1 exact match, just return it directly (ignoring any possibles).
		if(matches.length() = 1)
			return matches[1]
		
		; Prompt the user (even if there's just 1 possible, this gives them the opportunity to enter the INI)
		data := this.selectFromEMC2RecordMatches(matches, possibles)
		if(!data) ; User didn't pick an option
			return ""
		
		ini := this.convertToUsefulEMC2INI(data["INI"]) ; GDB TODO probably move this and the conversion to EpicRecord into selectFromEMC2RecordMatches()
		return new EpicRecord(ini, data["ID"], data["TITLE"])
	}
	
	
	selectEMC2RecordFromUsefulTitles() {
		titles := this.getUsefulEMC2RecordTitles()
		; Debug.popup("titles",titles)
		
		allMatches   := []
		allPossibles := []
		For windowName,title in titles {
			matches := this.extractEMC2RecordsFromTitle(title, possibles)
			For _,record in matches {
				record.windowName := windowName
				allMatches.push(record)
			}
			For _,record in possibles {
				record.windowName := windowName
				allMatches.push(record)
			}
		}
		Debug.popup("allMatches",allMatches, "allPossibles",allPossibles)
		
		; No matches or possibles
		if(allMatches.length() + allPossibles.length() = 0) {
			Toast.ShowError("No potential EMC2 record IDs found.")
			return ""
		}
		
		; Only 1 exact match, just return it directly (ignoring any possibles).
		if(allMatches.length() = 1)
			return allMatches[1]
		
		; Prompt the user (even if there's just 1 possible, this gives them the opportunity to enter the INI)
		data := this.selectFromEMC2RecordMatches(allMatches, allPossibles)
		if(!data) ; User didn't pick an option
			return ""
		
		ini := this.convertToUsefulEMC2INI(data["INI"])
		return new EpicRecord(ini, data["ID"], data["TITLE"])
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
	
	
	getUsefulEMC2RecordTitles() {
		titles := {} ; {windowName: title}
		
		; Normal titles
		titles["EMC2"]          := Config.windowInfo["EMC2"].getCurrTitle()
		titles["EpicStudio"]    := Config.windowInfo["EpicStudio"].getCurrTitle()
		titles["Visual Studio"] := Config.windowInfo["Visual Studio"].getCurrTitle()
		titles["Explorer"]      := Config.windowInfo["Explorer"].getCurrTitle()
		
		; Special "titles" extracted from inside the window(s)
		For i,title in Outlook.getAllMessageTitles() ; Outlook message titles
			titles["Outlook " i] := title ; GDB TODO store the windowName at the title level somehow so titles doesn't have to be associative and we don't need this counter.
		titles["VB6"] := "DLG " VB6.getDLGIdFromProject() ; VB6 (sidebar title from project group)
		
		return titles
	}
	
	;---------
	; DESCRIPTION:    Build a Selector and ask the user to pick from the matches we found.
	; PARAMETERS:
	;  matches   (I,REQ) - Associative array of confirmed EpicRecord objects, from getMatchesFromTitles.
	;  possibles (I,REQ) - Associative array of potential EpicRecord objects, from getMatchesFromTitles.
	; RETURNS:        Data array from Selector.selectGui().
	;---------
	selectFromEMC2RecordMatches(matches, possibles) {
		s := new Selector().setTitle("Select EMC2 Object to use:").addOverrideFields({1:"INI"})
		
		abbrevNums := {} ; {letter: lastUsedNumber}
		s.addSectionHeader("EMC2 Records")
		For _,record in matches
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
		windowName := record.windowName
		
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
	
	; /* GDB TODO =--
		
		; Example Usage
	; ;		GDB TODO
		
		; GDB TODO
			; Update auto-complete and syntax highlighting notepad++ definitions
		
	; */ ; --=

	; class EMC2RecordFromTitle { ; GDB TODO would it be helpful to have this extend EpicRecord to use its record-string-parsing more directly?
		; ; #PUBLIC#
		
		; ;  - Constants
		; ;  - staticMembers
		; ;  - nonStaticMembers
		; ini        := ""
		; id         := ""
		; title      := ""
		; windowName := ""
		
		; ;  - properties
		; ;  - __New()
		; __New(ini := "", id := "", title := "", windowName := "") {
			; this.ini        := ini
			; this.id         := id
			; this.title      := title
			; this.windowName := windowName
		; }
		
		; ;  - otherFunctions
		
		
		; ; #INTERNAL#
		
		; ;  - Constants
		; ;  - staticMembers
		; ;  - nonStaticMembers
		; ;  - functions
		
		
		; ; #PRIVATE#
		
		; ;  - Constants
		; ;  - staticMembers
		; ;  - nonStaticMembers
		; ;  - functions
		; ; #END#
	; }
	; #END#
}


