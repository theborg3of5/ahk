/* Static class to turn window titles into potential EMC2 objects and interact with them. =--
	
	Example Usage
;		record := WindowTitleToEMC2.selectRecordFromAllWindowTitles() ; Shows popup and asks the user to pick an EMC2Object instance based on all current window titles.
	
	GDB TODO
		Update auto-complete and syntax highlighting notepad++ definitions
		Ideas for more stuff to add:
			Generic !w/!e hotkeys that use the current window title (overridden by program-specific ones as needed)
				!c is used for paths and such, so not that.
		Revisit organization of various EMC2 string parsing code
			Current:
				ActionObjectEMC2.isThisType() => EMC2Record.initFromRecordString()
					MUST be an EMC2 record string
					Only considers beginning of string
				WindowTitleToEMC2.* => Considers all bits of the title, can return multiple matches, currently has ActionObjectEMC2.isThisType() "win" over anything else
					Problem: because we currently make ActionObjectEMC2 "win", we miss any additional IDs in same title
				EpicLib.couldBeEMC2ID() => Used by both of the above
				EMC2Record => pre/post processing + standard EMC2 string
			Desired use cases:
				OneNote
					linkEMC2ObjectInLine() - Used with !+n
					linkDevStructureSectionTitle() - view and edit links
				Outlook
					openEMC2ObjectFromCurrentMessageWeb()/openEMC2ObjectFromCurrentMessageEdit()
					copyEMC2ObjectFromEvent()
					copyEMC2ObjectFromTLG()/openEMC2ObjectFromTLGWeb()/openEMC2ObjectFromTLGEdit()
				Epic
					selectTLGActionObject() - TLG list of EMC2 objects
					sendStandardEMC2ObjectString()
					^!i - insert ID from window titles
						? Actually, do we really want ALL windows? Or should we just identify the useful ones?
							Useful ones would probably be:
								Outlook message titles
								EMC2 (title)
								EpicStudio (title)
								Visual Studio (title)
								VB (sidebar title from project group)
								Explorer (title)
				EMC2
					copyCurrentRecord()/openCurrentRecordWeb()/openCurrentRecordWebBasic()/openCurrentDLGInEpicStudio()
				EpicStudio
					linkRoutineToCurrentDLG()
				New
					Edit/View EMC2 object from current window title (global !e/!w hotkeys)
						Still overridden by program-context hotkeys for special places like EMC2 or Outlook
					TLG selector - special keyword for RECORD that triggers this check (and possibly an extra popup)?
						INI would become a prefix so the TLG logic puts it in the right spot
						"FIND" or "GET" maybe?
			New plan:
				(No functionality that only considers the start of the string anymore)
				1. Is a given bit possibly an EMC2 ID? => EpicLib.couldBeEMC2ID()
				2. Email-subject-specific handling (pretty much all of EMC2Record.preProcess/.postProcess) should move to Outlook class
				3. For a given string (generally a title of some sort), get exact matches only
						Selector between them when 0 or multiple exacts
						Basically #4, just ignore possible matches
				4. For a given string (generally a title of some sort), get exact + possible matches both
						Selector between them when 0 or multiple exacts
				5. From a set of window titles (either all or a trusted few), get exact + possible matches both
						Selector between them when 0 or multiple exacts
						Basically #4 across multiple windows' titles
			Code structure:
				x. EpicLib.couldBeEMC2ID() stays
					Likely used by ActionObjectEMC2 to determine if given ID is EMC2 (for use from ActionObject)
				x. Outlook class gets email-subject-specific handling (.preProcess/.postProcess)
				x. EpicRecord.initFromRecordString() stays, for RECORD string (ini/id/title in specific formats) to INI/ID/title
				x. Standard EMC2 string generation moves into Epic.sendStandardEMC2ObjectString()
					Will call into EpicLib.selectEMC2Records() to get the needed ini/id/title
				x. EpicLib.extractEMC2Records(fromString, possibleIDs) => returns exact matches
					Likely used by ActionObjectEMC2 - only use the first result (exact, then possible)
				x. EpicLib.selectEMC2RecordFromTitle(fromString) => shows popup if multiple + returns choice OR if 1 exact match, return without popup)
					Edit/View EMC2 record from current window title
					TLG selector special "FIND" or "GET" keyword
				x. Update Epic.sendStandardEMC2ObjectString() to use EpicLib.selectEMC2RecordFromTitle
				x. Update ActionObjectEMC2 to use new logic - EpicLib.extractEMC2Records
				x. EMC2 class gets a public getCurrentRecord() function (a la initFromEMC2Title()) that returns an EpicRecord from its current title (or "" if nothing there)
				x. Outlook class gets initFromTLGString() equivalent
				x. Get rid of (now-empty) EMC2Record
				x. EpicLib.selectEMC2RecordsFromUsefulTitles() => compiles all results from "trusted" titles and shows a popup for them (if 1 total match, return that without a popup)
					^!i - insert ID from window titles
					Probably use EpicLib.extractEMC2Records for each title
				. TLG selector "FIND" or "GET" keyword
				. Global edit/view from current window title
				. Switch EpicStudio to use global edit/view from window title, rather than its own getCurrentDLG() (and callers) stuff.
				. Consider adding an ActionObjectEMC2 function for copying + toasting (maybe for ActionObjectBase and other instances that make sense too?)
					Maybe different ones for copying ID, INI ID, and INI ID - TITLE?
						Need at least ID (can use INI/title in toast)
						Callers:
							EMC2
								copyCurrentRecord()
							Outlook
								copyEMC2ObjectFromEvent()
								copyEMC2ObjectFromTLG()
								copyCurrentMessageTitle() (maybe)
				. Consider putting all of the EMC2 record-specific stuff in EpicLib, into a new library (EMC2RecordLib, maybe?)
	
*/ ; --=

class WindowTitleToEMC2 {
	; #PUBLIC#
	
	
	getEMC2RecordFromTitle(title) {
		matches   := {} ; {id: EpicRecord}
		possibles := {} ; {id: EpicRecord} (ini always "")
		
		; First, try ActionObjectEMC2's parsing logic on the full title to see if we get a full match right off the bat.
		if(ActionObjectEMC2.isThisType(title))
			return new EpicRecord().initFromRecordString(title)
		
		; Split up the title and look for potential IDs.
		titleBits := title.split([" ", ",", "-", "(", ")", "[", "]", "/", "\", ":", "."], " ").removeEmpties()
		For i,potentialId in titleBits {
			; Skip: this bit couldn't actually be an ID.
			if(!EpicLib.couldBeEMC2ID(potentialId))
				Continue
			; Skip: already have a proper match for this ID. ; GDB TODO need to also do this at loop level to prevent all-windows duplicates
			if(matches[potentialId])
				Continue
			
			; Possible: first element can't have a preceding INI.
			if(i = 1) {
				possibles[potentialId] := new EpicRecord("", potentialId, title)
				Continue
			}
			
			; Match: confirmed valid INI.
			ini := titleBits[i-1]
			id  := potentialId
			if(ActionObjectEMC2.isThisType("", ini, id)) {
				; Found a proper match, save it off.
				matches[id] := new EpicRecord(ini, id, title)
				possibles.delete(id) ; If we have the same ID already in possibles, remove it.
				Continue
			}
			
			; Possible: no valid INI.
			possibles[potentialId] := new EpicRecord("", potentialId, title)
		}
		
		matchCount := DataLib.forceNumber(matches.count())
		possibleCount := DataLib.forceNumber(possibles.count())
		totalCount := matchCount + possibleCount
		if(totalCount = 0) {
			Toast.ShowError("No potential EMC2 record IDs found in window titles")
			return ""
		}
		; Only 1 match, just return it directly.
		if(totalCount = 1 && matchCount = 1) {
			For _,record in matches
				return record
		}
		
		data := this.selectFromMatches(matches, possibles)
		if(!data) ; User didn't pick an option
			return ""
		
		return new EpicRecord(data["INI"], data["ID"], data["TITLE"])
	}
	
	;---------
	; DESCRIPTION:    Ask the user to select an EpicRecord from the current window titles and send the corresponding ID.
	;---------
	sendIDFromAllWindowTitles() {
		SendRaw, % this.selectRecordFromAllWindowTitles().id
	}
	
	;---------
	; DESCRIPTION:    Look thru all current window titles and ask the user to select from them.
	; RETURNS:        EpicRecord instance describing the EMC2 object we believe the title they picked represents.
	;---------
	selectRecordFromAllWindowTitles() { ; Assumption: any given ID will go with exactly 1 INI - I'm unlikely to ever see multiple.
		titles := this.getUsefulTitles()
		; Debug.popup("titles",titles)
		
		this.getMatchesFromTitles(titles, matches, possibles)
		; Debug.popup("matches",matches, "possibles",possibles)
		
		matchCount := DataLib.forceNumber(matches.count())
		possibleCount := DataLib.forceNumber(possibles.count())
		totalCount := matchCount + possibleCount
		if(totalCount = 0) {
			Toast.ShowError("No potential EMC2 record IDs found in window titles")
			return ""
		}
		; Only 1 match, just return it directly.
		if(totalCount = 1 && matchCount = 1) {
			For _,record in matches
				return record
		}
		
		data := this.selectFromMatches(matches, possibles)
		if(!data) ; User didn't pick an option
			return ""
		
		return new EpicRecord(data["INI"], data["ID"], data["TITLE"])
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Get a list of window titles that might contain EMC2 object references.
	; RETURNS:        Array of window titles.
	;---------
	getUsefulTitles() {
		titles := []
		
		; Make sure to include a few trusted/preferred windows/titles.
		titles.push(Config.windowInfo["EMC2"].getCurrTitle()) ; EMC2
		titles.appendArray(Outlook.getAllMessageTitles()) ; Outlook message titles
		
		; Look thru all windows (hidden included)
		settings := new TempSettings().detectHiddenWindows("On")
		For _,winId in WinGet("List") {
			title := WinGetTitle("ahk_id " winId)
			
			; Empty titles are useless.
			if(title = "")
				Continue
			
			; Filter out useless-but-prolific titles by prefix.
			if(title.startsWithAnyOf([".NET-BroadcastEventWindow.", "CtrlVirtualCursorWin_", "GDI+ Window"]))
				Continue
			
			; Duplicates aren't helpful either.
			if(titles.contains(title))
				Continue
			
			; Trim out some common title bits that end up falsely flagged as possibilities.
			title := title.removeRegEx("AutoHotkey v[\d\.]+")         ; AHK version has lots of numbers in it
			title := title.removeRegEx("\$J:[\d]+")                   ; $J:<pid> from PuTTY windows
			title := title.removeRegEx("\d{1,2}\/\d{1,2}, .+day")     ; Dates (my usual iddate format for OneNote and such)
			title := title.removeRegEx("\d+ Reminder\(s\)")           ; Outlook reminders window
			title := title.removeRegEx("\\EpicSource\\\d{1,2}\.\d\\") ; Hyperspace version number in a path
			
			; Looks useful, add it in.
			titles.push(title)
		}
		settings.restore()
		
		return titles
	}
	
	;---------
	; DESCRIPTION:    Walk thru the provided list of titles and look for EMC2 object references.
	; PARAMETERS:
	;  titles    (I,REQ) - Array of window titles to consider.
	;  matches   (O,REQ) - Confirmed EMC2 objects: associative array of EpicRecord objects, indexed by ID.
	;  possibles (O,REQ) - Potential EMC2 objects: associative array of EpicRecord objects, indexed by ID. INI will always be
	;                      blank for these.
	;---------
	getMatchesFromTitles(titles, ByRef matches, ByRef possibles) {
		matches   := {} ; {id: EpicRecord}
		possibles := {} ; {id: EpicRecord} (ini always "")
		For _,title in titles {
			
			; First, try ActionObjectEMC2's parsing logic on the full title to see if we get a full match right off the bat.
			if(ActionObjectEMC2.isThisType(title)) {
				record := new EpicRecord().initFromRecordString(title)
				matches[record.id] := record
				Continue
			}
			
			; Split up the title and look for potential IDs.
			titleBits := title.split([" ", ",", "-", "(", ")", "[", "]", "/", "\", ":", "."], " ").removeEmpties()
			For i,potentialId in titleBits {
				; Skip: this bit couldn't actually be an ID.
				if(!EpicLib.couldBeEMC2ID(potentialId))
					Continue
				; Skip: already have a proper match for this ID.
				if(matches[potentialId])
					Continue
				
				; Possible: first element can't have a preceding INI.
				if(i = 1) {
					possibles[potentialId] := new EpicRecord("", potentialId, title)
					Continue
				}
				
				; Match: confirmed valid INI.
				ini := titleBits[i-1]
				id  := potentialId
				if(ActionObjectEMC2.isThisType("", ini, id)) {
					; Found a proper match, save it off.
					matches[id] := new EpicRecord(ini, id, title)
					possibles.delete(id) ; If we have the same ID already in possibles, remove it.
					Continue
				}
				
				; Possible: no valid INI.
				possibles[potentialId] := new EpicRecord("", potentialId, title)
			}
		}
	}
	
	;---------
	; DESCRIPTION:    Build a Selector and ask the user to pick from the matches we found.
	; PARAMETERS:
	;  matches   (I,REQ) - Associative array of confirmed EpicRecord objects, from getMatchesFromTitles.
	;  possibles (I,REQ) - Associative array of potential EpicRecord objects, from getMatchesFromTitles.
	; RETURNS:        Data array from Selector.selectGui().
	;---------
	selectFromMatches(matches, possibles) {
		s := new Selector().setTitle("Select EMC2 Object to use:").addOverrideFields({1:"INI"})
		
		abbrevNums := {} ; {letter: lastUsedNumber}
		s.addSectionHeader("EMC2 Records")
		For _,record in matches
			s.addChoice(this.buildChoice(record, abbrevNums))
		
		s.addSectionHeader("Potential IDs")
		For _,record in possibles
			s.addChoice(this.buildChoice(record, abbrevNums))
		
		return s.selectGui()
	}
	
	;---------
	; DESCRIPTION:    Turn the provided EpicRecord object into a SelectorChoice to show to the user.
	; PARAMETERS:
	;  record      (I,REQ) - EpicRecord object to use.
	;  abbrevNums (IO,REQ) - Associative array of abbreviation letters to counts, used to generate unique abbreviations. {letter: lastUsedNumber}
	; RETURNS:        SelectorChoice instance describing the provided record.
	;---------
	buildChoice(record, ByRef abbrevNums) {
		ini   := record.ini
		id    := record.id
		title := record.title
		
		name := ini.appendPiece(id, " ") " - " title
			
		; Abbreviation is INI first letter + a counter.
		ini := ini
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
