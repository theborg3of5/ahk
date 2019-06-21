/* Class to represent a record in Epic.
	
	Example Usage
		***
	
	GDB TODO
		Filter actionObject selector down to EMC2-Type choices (for both silent and gui selections)
		Use this in places:
			Callers to getObjectInfoFromEMC2() (which is the only caller to splitRecordString())
				Various in EMC2 (mostly opening current record elsewhere)
					EMC2
			Callers to extractEMC2ObjectInfo()
				input > sendStandardEMC2ObjectString()
					EMC2
					Remember special case for OneNote
			Callers to extractEMC2ObjectInfoRaw()
				launch > selectSnapper()
					Generic record
				actionObjectRedirector > tryProcessAsRecord()
					EMC2 or HDR
				actionObjectEMC2 > __New()
					EMC2
			ActionObjectEMC2
		Remove unused functions from epic.ahk
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
			this.selectMissingInfo()
			if(this.title != "")
				return this.title " [R " this.ini " " this.id "]"
			else
				return "R " this.ini " " this.id
		}
	}
	standardEMC2String { ; INI ID - TITLE
		get {
			this.selectMissingInfo()
			return this.ini " " this.id " - " this.title
		}
	}
	
	
	__New(recordString := "") {
		if(recordString != "")
			this.initFromRecordString(recordString)
	}
	
	initFromRecordString(recordString) {
		if(recordString = "")
			return
		
		this.processRecordString(recordString)
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
	
	
	processRecordString(recordString) {
		recordString := cleanupText(recordString) ; Clean any funky characters off of string edges
		if(recordString = "")
			return
		
		this.extractBitsFromString(recordString)
		this.processBits()
		; DEBUG.popup("recordString",recordString, "this",this)
	}
	
	extractBitsFromString(recordString) {
		; 1) Title [R INI ID]
		if(stringContains(recordString, "[R ") && stringContains(recordString, "]")) {
			; Title is everything up to the opening square bracket
			this.title := getStringBeforeStr(recordString, "[R ")
			
			; In the square brackets should be "R INI ID"
			iniId := getFirstStringBetweenStr(recordString, "[R ", "]")
			this.ini := getStringBeforeStr(iniId, " ")
			this.id  := getStringAfterStr(iniId, " ")
			
			return
		}
		
		; 2) #ID - Title
		if(stringStartsWith(recordString, "#")) {
			this.id := getFirstStringBetweenStr(recordString, "#", " - ")
			this.title := getStringAfterStr(recordString, " - ")
			
			return
		}
		
		; 3) {R } + INI ID + {space} + {: or -} + {title}
		recordString := removeStringFromStart(recordString, "R ") ; Trim off "R " at start if it's there.
		this.ini := getStringBeforeStr(recordString, " ")
		if(stringMatchesAnyOf(recordString, [":", "-"], , matchedDelim)) {
			; ID is everything up to the first delimiter
			this.id := getFirstStringBetweenStr(recordString, " ", matchedDelim)
			; Title is everything after
			this.title := getStringAfterStr(recordString, matchedDelim)
		} else {
			; ID is the rest of the string
			this.id := getStringAfterStr(recordString, " ")
		}
	}
	
	processBits() {
		; INI - clean up, and try to turn it into the "real" EMC2 one if it's one of those.
		this.ini := cleanupText(this.ini)
		if(this.ini != "") {
			s := new Selector("actionObject.tls")
			tempIni := s.selectChoice(this.ini, "SUBTYPE")
			if(tempIni) {
				this.ini := tempIni
				isEMC2Ini := true
			}
		}
		
		; ID - clean up.
		this.id := cleanupText(this.id)
		
		; Title - clean up, drop anything extra that we don't need.
		removeAry := ["-", "/", "\", ":", ","]
		if(isEMC2Ini) {
			removeAry.push("DBC") ; Don't need "DBC" on the start of every EMC2 title.
			
			; INI-specific strings to remove
			if(this.ini = "DLG")
				removeAry := arrayAppend(removeAry, ["(Developer has reset your status)", "(Stage 1 QAer is Waiting for Changes)", "(Stage 2 QAer is Waiting for Changes)"])
			if(this.ini = "XDS")
				removeAry := arrayAppend(removeAry, ["(A Reviewer Approved)"])
			if(this.ini = "SLG")
				removeAry := arrayAppend(removeAry, ["--Assigned To:"])
		}
		this.title := cleanupText(this.title, removeAry)
	}
	
	selectMissingInfo() {
		if(this.ini != "" && this.id != "") ; Nothing required is missing.
			return
		
		s := new Selector("actionObject.tls")
		data := s.selectGui("", "Enter INI and ID", {"SUBTYPE":this.ini, "VALUE":this.id})
		if(!data)
			return
		
		this.ini := data["SUBTYPE"]
		this.id  := data["VALUE"]
	}
	
}
