/* Static class to turn window titles into potential EMC2 objects and interact with them. =--
	
	Example Usage
;		record := WindowTitleToEMC2.selectRecordFromAllWindowTitles() ; Shows popup and asks the user to pick an EMC2Object instance based on all current window titles.
	
	GDB TODO
		Update auto-complete and syntax highlighting notepad++ definitions
		Ideas for more stuff to add:
			Generic !w/!e hotkeys that use the current window title (overridden by program-specific ones as needed)
				!c is used for paths and such, so not that.
	
*/ ; --=

class WindowTitleToEMC2 {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Ask the user to select an EMC2Record from the current window titles and send the corresponding ID.
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
		; Look thru all windows (hidden included)
		settings := new TempSettings().detectHiddenWindows("On")
		titles := []
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
		
		; Add in Outlook message titles (not actually window titles, but useful)
		titles.push(Outlook.getMessageTitle(Config.windowInfo["Outlook"].idString))
		
		return titles
	}
	
	;---------
	; DESCRIPTION:    Walk thru the provided list of titles and look for EMC2 object references.
	; PARAMETERS:
	;  titles    (I,REQ) - Array of window titles to consider.
	;  matches   (O,REQ) - Confirmed EMC2 objects: associative array of EMC2Record objects, indexed by ID.
	;  possibles (O,REQ) - Potential EMC2 objects: associative array of EMC2Record objects, indexed by ID. INI will always be
	;                      blank for these.
	;---------
	getMatchesFromTitles(titles, ByRef matches, ByRef possibles) {
		matches   := {} ; {id: EMC2Record}
		possibles := {} ; {id: EMC2Record} (ini always "")
		For _,title in titles {
			
			; First, try ActionObjectEMC2's parsing logic on the full title to see if we get a full match right off the bat.
			if(ActionObjectEMC2.isThisType(title)) {
				record := new EMC2Record().initFromRecordString(title)
				matches[record.id] := record
				Continue
			}
			
			; Split up the title and look for potential IDs.
			titleBits := title.split([" ", ",", "-", "(", ")", "[", "]", "/", "\", ":", "."], " ").removeEmpties()
			For i,potentialId in titleBits {
				; Skip: this bit couldn't actually be an ID.
				if(!this.isPossibleEMC2ID(potentialId))
					Continue
				; Skip: already have a proper match for this ID.
				if(matches[potentialId])
					Continue
				
				; Possible: first element can't have a preceding INI.
				if(i = 1) {
					possibles[potentialId] := new EMC2Record("", potentialId, title)
					Continue
				}
				
				; Match: confirmed valid INI.
				ini := titleBits[i-1]
				id  := potentialId
				if(ActionObjectEMC2.isThisType("", ini, id)) {
					; Found a proper match, save it off.
					matches[id] := new EMC2Record(ini, id, title)
					possibles.delete(id) ; If we have the same ID already in possibles, remove it.
					Continue
				}
				
				; Possible: no valid INI.
				possibles[potentialId] := new EMC2Record("", potentialId, title)
			}
		}
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
	
	;---------
	; DESCRIPTION:    Build a Selector and ask the user to pick from the matches we found.
	; PARAMETERS:
	;  matches   (I,REQ) - Associative array of confirmed EMC2Record objects, from getMatchesFromTitles.
	;  possibles (I,REQ) - Associative array of potential EMC2Record objects, from getMatchesFromTitles.
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
	; DESCRIPTION:    Turn the provided EMC2Record object into a SelectorChoice to show to the user.
	; PARAMETERS:
	;  record      (I,REQ) - EMC2Record object to use.
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
