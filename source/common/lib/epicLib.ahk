; Various Epic utility functions.

class EpicLib {
	;region ==================== PUBLIC ====================
	;---------
	; DESCRIPTION:    Prompt the user to choose an internal Environment using a Selector.
	; PARAMETERS:
	;  selectorTitle (I,REQ) - The title for the Selector.
	; RETURNS:        data array (null if the user didn't accept)
	;---------
	selectEpicEnvironment(selectorTitle) {
		; Set up Selector
		s := new Selector("epicEnvironments.tls")
		if(selectorTitle != "")
			s.setTitle(selectorTitle)
		
		; Show the popup and get user input
		data := s.selectGui()
		if(!data)
			return ""

		; Replace special tags found in some values.
		latestLocalVersion := EpicLib.findLatestInstalledHyperspaceVersion()
		latestLocalVersionFlat := latestLocalVersion.remove(".")

		data["VERSION"]   := data["VERSION"].replaceTag(  "LATEST_LOCAL_VERSION",      latestLocalVersion)
		data["COMM_ID"]   := data["COMM_ID"].replaceTag(  "LATEST_LOCAL_VERSION_FLAT", latestLocalVersionFlat)
		data["HSWEB_URL"] := data["HSWEB_URL"].replaceTag("LATEST_LOCAL_VERSION_FLAT", latestLocalVersionFlat)

		return data
	}
	
	;---------
	; DESCRIPTION:    Run Hyperspace locally for the given version and environment.
	; PARAMETERS:
	;  version     (I,REQ) - Dotted Hyperspace version
	;  environment (I,OPT) - EpicComm ID for the environment to connect to.
	;  timeZone    (I,OPT) - Time zone for the environment.
	;---------
	runHyperspace(version, environment := "", timeZone := "") {
		runString := Config.private["HYPERSPACE_BASE"]
		runString := runString.replaceTag("VERSION",      version)
		runString := runString.replaceTag("VERSION_FLAT", version.remove("."))
		runString := runString.replaceTag("ENVIRONMENT",  environment)
		runString := runString.replaceTag("TIME_ZONE",    timeZone)
		
		Run(runString)
	}
	
	;---------
	; DESCRIPTION:    Launch Hyperdrive for the given environment.
	; PARAMETERS:
	;  environment (I,OPT) - EpicComm ID for the environment to connect to (node in my custom _0Config.json config file).
	;                        If not given, we'll just launch Hyperdrive to select an environment.
	;  timezone    (I,OPT) - Time zone to use.
	;---------
	runHyperdrive(environment := "", timezone := "") {
		; Only specify the file ID (which filters the available environments) if we're launching into a specific environment.
		if(environment != "" && environment != "LAUNCH")
			fileId := "_" Config.private["WORK_ID"]
		
		args := "-- ID=<FILE_ID> env=<ENVIRONMENT>"
		args := args.replaceTag("FILE_ID"    , fileId)
		args := args.replaceTag("ENVIRONMENT", environment)
		
		Config.runProgram("Hyperdrive", args)
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
		
		Loop, Files, C:\EpicSource\*, D ; Don't try to use Config.path stuff here - we call this from inside.
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
	; DESCRIPTION:    Find the latest version of Hyperspace that's currently installed.
	; RETURNS:        Numeric version (i.e. 10.1)
	;---------
	findLatestInstalledHyperspaceVersion() {
		latestVersion := 0.0

		Loop, Files, C:\Program Files (x86)\Epic\v*.*, D
		{
			version := A_LoopFileName.removeFromStart("v")

			; Only consider versions where there's an executable (aka the version is actually installed)
			if(!FileExist(A_LoopFileLongPath "\Shared Files\EpicD" version.remove(".") ".exe"))
				Continue
			
			if(version > latestVersion)
				latestVersion := version
		}

		return latestVersion
	}
	
	;---------
	; DESCRIPTION:    Check whether the given string COULD be an EMC2 record ID - these are numeric except certain DLGs
	;                 that have prefixes (I, T, CS, R, etc).
	; PARAMETERS:
	;  id (I,REQ) - Possible ID to evaluate.
	; RETURNS:        true if possibly an ID, false otherwise.
	;---------
	couldBeEMC2ID(id) {
		; For special DLG IDs (SUs, TDE, searches, etc.), trim off leading letter so we recognize them as a numeric ID.
		if(id.startsWithAnyOf(["I", "T", "CS", "R"], letter))
			id := id.removeFromStart(letter)
		
		; IDs must be numeric (beyond the above special case).
		if(!id.isDigits())
			return false
		
		; No record ID is going to be 3 digits or less.
		return id >= 999
	}
	
	;---------
	; DESCRIPTION:    Checks whether the given INI and ID could plausibly be an EMC2 ID, based on whether we can map the
	;                 INI to one we know, and the ID's format.
	; PARAMETERS:
	;  ini (I,REQ) - INI to consider
	;  id  (I,REQ) - ID to consider
	; RETURNS:        true/false
	;---------
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
		if(ini.isDigits())
			return ""
		
		s := this.getEMC2TypeSelector()
		return s.selectChoice(ini, "SUBTYPE") ; Silent selection - no popup.
	}
	
	;---------
	; DESCRIPTION:    Extract all EMC2 records from the given string and pick the "best" one (that is, the first exact match, then the first possible match).
	; PARAMETERS:
	;  text (I,REQ) - The string to pull EMC2 record references out of.
	; RETURNS:        EpicRecord representing the EMC2 record we picked, or "" if we couldn't find any.
	;---------
	getBestEMC2RecordFromText(text) {
		this.extractEMC2RecordsFromText(text, exacts, possibles)
		
		; Return the first exact match, then the first possible match.
		return DataLib.coalesce(exacts[1], possibles[1])
	}
	
	;---------
	; DESCRIPTION:    Extract all EMC2 records from the given string, prompt the user for which one to use, and put the resulting ID on the clipboard.
	; PARAMETERS:
	;  text (I,REQ) - The string to pull EMC2 record references out of.
	; NOTES:          If there is exactly 1 "exact" match (valid INI and ID), we'll always return it without a popup (even
	;                 if there are other potential matches with only a valid ID).
	;---------
	copyEMC2RecordIDFromText(text) {
		if(!text) {
			Toast.ShowError("Could not copy EMC2 record ID from string", "String is blank")
			return
		}
		
		record := this.selectEMC2RecordFromText(text)
		if(!record) {
			Toast.ShowError("Could not copy EMC2 record ID from string", "No potential EMC2 record IDs found in provided text: " text)
			return
		}
		
		ClipboardLib.setAndToast(record.id, "EMC2 " record.ini " ID")
	}
	
	;---------
	; DESCRIPTION:    Extract all EMC2 records from the given string and prompt the user if we find multiple, returning
	;                 the result.
	; PARAMETERS:
	;  text (I,REQ) - The string to pull EMC2 record references out of.
	; RETURNS:        "" if we didn't find any records or the user didn't pick one
	;                 EpicRecord instance representing their choice if they did pick one
	; NOTES:          If there is exactly 1 "exact" match (valid INI and ID), we'll always return it without a popup (even
	;                 if there are other potential matches with only a valid ID).
	;---------
	selectEMC2RecordFromText(text) {
		if(!this.extractEMC2RecordsFromText(text, exacts, possibles)) {
			; No matches at all
			Toast.ShowError("No potential EMC2 record IDs found in string: " text)
			return ""
		}
		; DEBUG.POPUP("text",text, "exacts",exacts, "possibles",possibles)
		
		; Only 1 exact match, just return it directly (ignoring any possibles).
		if(exacts.length() = 1) {
			exacts[1].ini := EpicLib.convertToUsefulEMC2INI(exacts[1].ini) ; Convert INI before we return.
			return exacts[1]
		}
		
		; Prompt the user (even if there's just 1 possible, this gives them the opportunity to enter the INI)
		data := this.selectFromEMC2RecordMatches(exacts, possibles)
		if(!data) ; User didn't pick an option
			return ""
		
		return new EpicRecord(data["INI"], data["ID"], data["TITLE"])
	}
	
	;---------
	; DESCRIPTION:    Check a set of titles (from a hard-coded set of windows) for EMC2 records and give the user the
	;                 option to pick between all of them.
	; PARAMETERS:
	;  ignoreIfNoTitle (I,OPT) - Set to true to only consider results that include a title.
	; RETURNS:        An EpicRecord instance describing the record the user picked, or "" if we couldn't find one or they
	;                 didn't select one.
	;---------
	selectEMC2RecordFromUsefulTitles(ignoreIfNoTitle := false) {
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
		
		this.removeEMC2RecordDuplicates(allExacts, allPossibles)
		
		if(ignoreIfNoTitle) {
			tempAry := allExacts.clone()
			allExacts := []
			For _, record in tempAry {
				if(!StringLib.isNullOrWhitespace(record.title))
					allExacts.push(record)
			}
			tempAry := allPossibles.clone()
			allPossibles := []
			For _, record in tempAry {
				if(!StringLib.isNullOrWhitespace(record.title))
					allPossibles.push(record)
			}
		}

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
		
		return new EpicRecord(data["INI"], data["ID"], data["TITLE"])
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
		delims := ["-", "/", "\", ":"]
		
		; Take INI and ID (and anything in between) out if they're given.
		iniAndID := ini title.firstBetweenStrings(ini, id) id
		title := title.remove(iniAndID).clean(delims)
		
		; The "DBC" prefix isn't helpful when most of my records have it.
		title := title.removeFromStart("DBC")
		
		return title.clean(delims)
	}
	;endregion ==================== PUBLIC ====================
	
	
	;region ==================== PRIVATE ====================
	;region EMC2 Record Extraction/Selection
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
		s.dataTableList.filterOutIfColumnNoMatch("TYPE", ActionObject.Type_EMC2)
		
		this.emc2TypeSelector := s ; Cache for future use
		
		return s
	}
	
	;---------
	; DESCRIPTION:    Get an array of windows that are likely to contain useful EMC2 record IDs.
	; RETURNS:        Array of objects: {windowName: name of window from windows.tl, title: window's title}
	;---------
	getUsefulEMC2RecordWindows() {
		windows := [] ; [ {windowName, title} ]
		
		; Normal titles (none of these can have the record title in them, so don't include that bit)
		For _,windowName in ["EMC2", "EpicStudio", "Visual Studio", "Explorer"] {
			title := Config.windowInfo[windowName].getCurrTitle()
			title := title.removeFromEnd(windowName).clean("-") ; Trim the window name off the end - we're gonna show it at the start anyways.
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
	
	;---------
	; DESCRIPTION:    Certain named windows will never have the EMC2 record title in them.
	; PARAMETERS:
	;  windowName (I,REQ) - The window name to check
	; RETURNS:        true/false - can this window's title contain the EMC2 record title?
	;---------
	canWindowIncludeEMC2RecordTitle(windowName) {
		; Not a named window - we don't know, so allow it.
		if(!windowName)
			return true
		
		; Certain windows will only ever include the INI/ID, never the record title.
		noTitleWindows := ["EMC2", "EpicStudio", "Visual Studio", "Explorer", "VB6"]
		if(noTitleWindows.contains(windowName))
			return false
		
		; It could!
		return true
	}
	
	;---------
	; DESCRIPTION:    Given a string, pull all described EMC2 records out and return them.
	; PARAMETERS:
	;  text       (I,REQ) - The string to extract records from.
	;  exacts     (O,OPT) - "Exact" matches, where we have both a valid INI (or something representing an INI, like "design" or
	;                       "x") and ID (numeric or with a special DLG prefix like "I").
	;  possibles  (O,OPT) - Potential matches, where we only have a valid ID (user can enter the INI).
	;  windowName (I,OPT) - If provided, we'll stamp this window name on EpicRecord.label for all returned matches.
	;                       Can also affect whether we try to actually get the record title out of the given string.
	;---------
	extractEMC2RecordsFromText(text, ByRef exacts := "", ByRef possibles := "", windowName := "") {
		exacts    := []
		possibles := []
		
		; Make sure the text is in a decent state to be parsed.
		text := text.clean()
		
		; "Flatten" any dashed INIs (like PRJ-R) so that they don't get split up below.
		text := this.flattenDashedINIs(text)
		
		; First, give EpicRecord's more-stringent parsing logic a shot - since most titles are close to this format, it gives us the best chance at a nicer title.
		record := new EpicRecord().initFromRecordString(text)
		if(this.couldBeEMC2Record(record.ini, record.id)) {
			record.label := windowName
			record.title := this.cleanEMC2RecordTitle(record.title, record.ini, record.id)
			exacts.push(record)
		}
		
		; Split up the text and look for potential IDs.
		textBits := text.split([" ", ",", "-", "(", ")", "[", "]", "/", "\", ":", ".", "#", "`t"], " ").removeEmpties()
		For i,id in textBits {
			recordTitle := ""
			
			; Extract other potential info
			ini := textBits[i - 1] ; INI is assumed to be the piece just before the ID.
			if(this.canWindowIncludeEMC2RecordTitle(windowName)) ; Certain windows will never contain the record title - filter out the title here so it doesn't potentially "win" when there are duplicates.
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
		
		; Filter out duplicates.
		this.removeEMC2RecordDuplicates(exacts, possibles)
		
		; Convert all exact maches' INIs.
		For i,exact in exacts
			exacts[i].ini := EpicLib.convertToUsefulEMC2INI(exact.ini)
		
		; Debug.popup("textBits",textBits, "exacts",exacts, "possibles",possibles)
		return (exacts.length() + possibles.length()) > 0
	}
	
	;---------
	; DESCRIPTION:    "Flatten" (remove dash) any INIs that contain a dash, so that they don't get split up.
	; PARAMETERS:
	;  text (I,REQ) - The text to consider
	; RETURNS:        Same text, but with the dashes inside any known dashed INIs removed.
	; NOTES:          This is undone by convertToUsefulEMC2INI().
	;---------
	flattenDashedINIs(text) {
		text := text.replace("PRJ-R", "PRJR") ; Project Readiness
		text := text.replace("XDS-I", "XDSI") ; Design Issues
		text := text.replace("DLG-I", "DLGI") ; DLG Issues
		
		return text
	}
	
	;---------
	; DESCRIPTION:    Remove duplicates from the given arrays - there should only contain 1 EpicRecord instance with any
	;                 given ID across both arrays, with exacts winning.
	; PARAMETERS:
	;  exacts    (IO,REQ) - Array of exact matches as EpicRecord instances, will be updated.
	;  possibles (IO,REQ) - Array of potential matches as EpicRecord instances, will be updated.
	; NOTES:          Titles are used to break ID ties - shorter title wins.
	;---------
	removeEMC2RecordDuplicates(ByRef exacts, ByRef possibles) {
		; Filter out duplicates inside exacts.
		exactsToKeep := {} ; {id: indexInExacts} ; We store the index so we can maintain the order (instead of sorting by ID)
		For exactLn,exact in exacts {
			id := exact.id
			
			; New ID, store it off.
			if(!exactsToKeep[id]) {
				exactsToKeep[id] := exactLn
				Continue
			}
			
			; ID already exists - decide whether to keep our stored index or replace it with the new one.
			; Note: we're assuming each ID only goes with 1 INI, chances of the same ID for multiple INIs in the
			; same string seem slim.
			storedExactLn := exactsToKeep[id] ; Line number in exacts[]
			storedExact := exacts[storedExactLn]
			storedTitle := storedExact.title

			; Either way, combine the two window names so we use both in any eventual popups.
			storedExact.label := this.combineWindowNames(storedExact.label, exact.label)
			
			; The new exact only wins if it has a shorter title (and actually has a title).
			title := exact.title
			if(!title)
				Continue
			if(storedTitle && title.length() >= storedTitle.length())
				Continue
			
			; New exact wins, overwrite the old one.
			exact.label := storedExact.label ; Pull the combined window names from the stored exact.
			exactsToKeep[id] := exactLn
		}
		
		; Put the results back into exacts, in the original order (not the ID order found in exactsToKeep).
		exactsTemp := {}
		For _,i in exactsToKeep
			exactsTemp[i] := exacts[i]
		exacts := exactsTemp.toValuesArray()
		
		; Filter out possibles for IDs we already have in exacts (we don't really see duplicates within possibles).
		possiblesTemp := []
		For _,possible in possibles {
			if(!exactsToKeep[possible.id])
				possiblesTemp.push(possible)
		}
		possibles := possiblesTemp
	}

	;---------
	; DESCRIPTION:    Combine two forward-slash-delimited lists of window names.
	; PARAMETERS:
	;  windowNames1 (I,REQ) - First set of window names
	;  windowNames2 (I,REQ) - Second set of window names
	; RETURNS:        Combined (with no duplicates) forward-slash-delimited list of window names.
	;---------
	combineWindowNames(windowNames1, windowNames2) {
		; Combine both into an array and drop duplicates.
		combinedNames := windowNames1.split("/").appendArray(windowNames2.split("/"))
		combinedNames.removeDuplicates()
		
		return combinedNames.join("/")
	}
	
	;---------
	; DESCRIPTION:    Build a Selector and ask the user to pick from the matches we found.
	; PARAMETERS:
	;  exacts    (I,REQ) - Array of confirmed EpicRecord objects, from extractEMC2RecordsFromText.
	;  possibles (I,REQ) - Array of potential EpicRecord objects, from extractEMC2RecordsFromText.
	; RETURNS:        Data array from Selector.selectGui().
	;---------
	selectFromEMC2RecordMatches(exacts, possibles) {
		abbreviations := []
		s := new Selector().setTitle("Select EMC2 Object to use:").addOverrideFields({1:"INI"})
		
		s.addSectionHeader("Full matches")
		For _,record in exacts
			s.addChoice(this.buildChoiceFromEMC2Record(record, abbreviations))
		
		s.addSectionHeader("Potential IDs")
		For _,record in possibles
			s.addChoice(this.buildChoiceFromEMC2Record(record, abbreviations))
		
		data := s.selectGui()
		if(data)
			data["INI"] := EpicLib.convertToUsefulEMC2INI(data["INI"]) ; Convert INI before we return.
		
		return data
	}
	
	;---------
	; DESCRIPTION:    Turn the provided EpicRecord object into a SelectorChoice to show to the user.
	; PARAMETERS:
	;  record         (I,REQ) - EpicRecord object to use.
	;  abbreviations (IO,REQ) - Array of all abbreviations so far, used to avoid duplicates. We'll add the one we generates from
	;                           this choice.
	; RETURNS:        SelectorChoice instance describing the provided record.
	;---------
	buildChoiceFromEMC2Record(record, ByRef abbreviations) {
		ini         := record.ini
		id          := record.id
		title       := record.title
		windowNames := record.label ; Can be a single name, or a /-delimited list.
		
		name := ""
		if(windowNames)
			name .= windowNames " - "
		if(ini)
			name .= ini " "
		name .= id
		if(title)
			name .= " - " title
		
		; Abbreviation comes from window name(s) or INI.
		if(windowNames) {
			abbrev := []
			For _, windowName in windowNames.split("/")
				abbrev.push(StringLower(windowName.sub(1, 2)))
		} else if(ini) {
			abbrev := StringLower(ini.charAt(1))
		} else {
			abbrev := "u"
		}
		
		; Add a counter to the abbreviation if needed.
		while(abbreviations.contains(abbrev)) {
			lastChar := abbrev.charAt(0)
			if(lastChar.isNum()) {
				abbrev := abbrev.removeFromEnd(lastChar)
				counter := lastChar + 1
			} else {
				counter := 2
			}
			abbrev .= counter
		}
		abbreviations.push(abbrev)
		
		return new SelectorChoice({NAME:name, ABBREV:abbrev, INI:ini, ID:id, TITLE:title})
	}
	;endregion EMC2 Record Extraction/Selection
	;endregion ==================== PRIVATE ====================
}


