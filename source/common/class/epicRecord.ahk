/* Class to represent a record in Epic.
	
	Example Usage
		***
	
	GDB TODO
		Can initialize from various inputs
			Programmatic string (possibly used by constructor if a string given there)
			EMC2 title (which uses clipboard method)
			In general, initialization should include:
				Breaking apart bits
				Cleaning out leftovers (like processEMC2ObjectInfo() does now)
		Properties for INI/ID/title
		Can output in various formats
			Standard EMC2 object string
				Include INI verification/replacement
					Could this absorb/replace getTrueEMC2INI()?
						Currently only used by processEMC2ObjectInfo() and ActionObjectEMC2.__New(), most likely possible
				Including special handling for OneNote linking?
					Maybe just make this more generic, method/parameter for linking the record INI/ID
			"R " INI " " ID
				Maybe with title as well if we have it, "<title> [R INI ID]"?
		Should we handle recordString and recordStringWithTitle formats as inputs?
			Could probably identify based on "[R " and "]" both existing
			What about stuff with just [INI ID] in it?
*/

class EpicRecord {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	; Properties of the record.
	ini   := ""
	id    := ""
	title := ""
	
	; Constructed strings representing the record.
	recordString { ; R INI ID
		get {
			return "R " this.ini " " this.id
		}
	}
	recordStringWithTitle { ; TITLE [R INI ID]
		get {
			return this.title " [" this.recordString "]"
		}
	}
	standardEMC2String { ; INI ID - TITLE
		get {
			return this.ini " " this.id " - " this.title
		}
	}
	
	
	__New(recordString := "") {
		if(recordString != "")
			this.initFromRecordString(recordString)
	}
	
	initFromRecordString(recordString) {
		recordString := cleanupText(recordString, ["R "]) ; Clean any funky characters off of string edges, plus the record prefix if it's there.
		if(recordString = "")
			return
		
		DEBUG.popup("recordString",recordString)
		
		
	}
	
	initFromEMC2Title() {
		title := WinGetTitle(MainConfig.windowInfo["EMC2"].titleString)
		title := removeStringFromEnd(title, " - EMC2")
		
		; If no info available, bail.
		if(title = "EMC2")
			return
		
		this.initFromRecordString(title)
	}
	
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	
}






; Split "INI ID" string into INI and ID (assume it's just the ID if no space included).
; Also does cleaning around the string so leading/trailing spaces, bullets, etc. don't make it fail.
splitRecordString2(recordString, ByRef ini := "", ByRef id := "") {
	recordString := cleanupText(recordString)
	recordPartsAry := StrSplit(recordString, " ")
	
	maxIndex := recordPartsAry.MaxIndex()
	if(maxIndex > 1)
		ini := recordPartsAry[1]
	id := recordPartsAry[maxIndex] ; Always the last piece (works whether there was an INI before it or not)
}




; line = title of EMC2 email, or title from top of web view.
extractEMC2ObjectInfo2(line) {
	infoAry := extractEMC2ObjectInfoRaw(line)
	return processEMC2ObjectInfo(infoAry)
}
extractEMC2ObjectInfoRaw2(line) {
	line := cleanupText(line, ["["]) ; Remove any odd leading/trailing characters (and also remove open brackets)
	
	; INI is first characters up to the first delimiter
	delimPos := stringMatchesAnyOf(line, [" ", "#"])
	if(delimPos) {
		ini  := subStr(line, 1, delimPos - 1)
		line := subStr(line, delimPos + 1) ; +1 to drop delimiter too
	}
	
	; ID is remaining up to the next delimiter
	delimPos := stringMatchesAnyOf(line, [" ", ":", "-", "]"])
	if(!delimPos) { ; If the string ended before the next delimiter (so no title), make sure to still get the ID.
		id := subStr(line, 1, strLen(line))
		line := ""
	} else {
		id := subStr(line, 1, delimPos - 1)
		line := subStr(line, delimPos + 1) ; +1 to drop delimiter too
	}
	
	; Title is everything left
	title := line
	
	return {"INI":ini, "ID":id, "TITLE":title}
}
processEMC2ObjectInfo2(infoAry) {
	ini   := infoAry["INI"]
	id    := infoAry["ID"]
	title := infoAry["TITLE"]
	
	; INI
	s := new Selector("actionObject.tls")
	ini := s.select(ini, "SUBTYPE") ; Turn any not-really-ini strings (like "Design") into actual INI (and ask user if we don't have one)
	if(!ini)
		return ""
	
	; ID
	id := cleanupText(id)
	
	; Title
	stringsToRemove := ["-", "/", "\", ":", ",", "(Developer has reset your status)", "(Stage 1 QAer is Waiting for Changes)", "(Stage 2 QAer is Waiting for Changes)", "(A Reviewer Approved)"] ; Odd characters and non-useful strings that should come off
	title := cleanupText(title, stringsToRemove)
	
	if(ini = "DLG") {
		title := removeStringFromStart(title, "DBC") ; Drop from start - most of my DLGs are DBC, no reason to include that.
		title := cleanupText(title, stringsToRemove) ; Remove anything that might have been after the "DBC"
	}
	if(ini = "SLG") {
		; "--Assigned to: USER" might be on the end for SLGs - trim it off.
		title := getStringBeforeStr(title, "--Assigned To:")
	}
	
	return {"INI":ini, "ID":id, "TITLE":title}
}

; Returns standard string for OneNote use.
buildStandardEMC2ObjectString2(ini, id, title) {
	return ini " " id " - " title
}

; Turn descriptors that aren't real INIs (like "Design") into the corresponding EMC2 INI.
getTrueEMC2INI2(iniString) {
	if(!iniString)
		return ""
	
	s := new Selector("actionObject.tls")
	return s.selectChoice(iniString, "SUBTYPE")
}


getObjectInfoFromEMC22(ByRef ini := "", ByRef id := "") {
	title := WinGetTitle(MainConfig.windowInfo["EMC2"].titleString)
	title := removeStringFromEnd(title, " - EMC2")
	
	; If no info available, finish here.
	if((title = "") or (title = "EMC2"))
		return
	
	; Split the input.
	splitRecordString(title, ini, id)
	; DEBUG.popup("getObjectInfoFromEMC2","Finish", "INI",ini, "ID",id)
}







