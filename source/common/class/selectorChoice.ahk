/* Representation of a single choice within a Selector object.
*/

class SelectorChoice {

; ==============================
; == Public ====================
; ==============================
	;---------
	; DESCRIPTION:    Create a new SelectorChoice instance.
	; PARAMETERS:
	;  data (I,REQ) - Assocative array of data that the choice contains.
	;                 Format:
	;                  data[LABEL] := VALUE
	;                 Special subscripts:
	;                  "ABBREV" - Abbreviation of choice, first one (the display one) later accessible via .abbrev
	;                  "NAME"   - Name of choice, later accessible via .name
	; RETURNS:        Reference to new SelectorChoice object
	;---------
	__New(data) {
		this.dataAry := data
	}
	
	;---------
	; DESCRIPTION:    Determine whether the given string matches any of the abbreviations
	;                 (including those not displayed) for this choice.
	; PARAMETERS:
	;  stringToTest (I,REQ) - String to check against this choice.
	; RETURNS:        true if it matches, false otherwise.
	;---------
	matchesAbbrev(stringToTest) {
		if(stringToTest = "")
			return false
		
		abbrev := this.dataAry["ABBREV"]
		if(isObject(abbrev))
			return arrayContains(abbrev, stringToTest)
		else
			return (stringToTest = abbrev)
	}
	
	;---------
	; DESCRIPTION:    The full data array for this choice.
	;---------
	dataArray[] {
		get {
			return this.dataAry
		}
	}
	
	;---------
	; DESCRIPTION:    The value of the given subscript of the data array.
	; PARAMETERS:
	;  index (I,REQ) - The index of the value in the data array to retrieve.
	;---------
	data[index] {
		get {
			if(index = "")
				return ""
			
			return this.dataAry
		}
	}
	
	;---------
	; DESCRIPTION:    The display name for the given choice.
	;---------
	name[] {
		get {
			return this.dataAry["NAME"]
		}
	}
	
	;---------
	; DESCRIPTION:    The (single) abbreviation to display for this choice. Note that if there were
	;                 multiple abbreviations given as an array, this will just be the first one.
	;---------
	abbrev[] {
		get {
			abbrev := this.dataAry["ABBREV"]
			if(isObject(abbrev))
				return abbrev[1]
			else
				return abbrev
		}
	}
	
	
; ==============================
; == Private ===================
; ==============================
	dataAry := [] ; LABEL => VALUE
	
	; Debug info (used by the Debug class)
	debugName := "SelectorChoice"
	debugToString(debugBuilder) {
		debugBuilder.addLine("Data", this.dataAry)
	}
}