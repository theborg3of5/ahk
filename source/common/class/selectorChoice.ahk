; Representation of a single choice within a Selector object.

class SelectorChoice {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    The full data object for this choice.
	;---------
	dataObject {
		get {
			return this.data
		}
	}
	
	;---------
	; DESCRIPTION:    The display name for the given choice.
	;---------
	name {
		get {
			return this.data["NAME"]
		}
	}
	
	;---------
	; DESCRIPTION:    The (first) abbreviation for the choice (the one we'll display next to the choice). Note that if
	;                 there were multiple abbreviations given as an array, this will just be the first one.
	;---------
	displayAbbrev {
		get {
			return (this.allAbbrevs)[1]
		}
	}

	;---------
	; DESCRIPTION:    All abbreviations for the given choice. Always an array, even if there's just
	;                 a single abbreviation.
	;---------
	allAbbrevs {
		get {
			return DataLib.forceArray(this.data["ABBREV"])
		}
		set {
			this.data["ABBREV"] := DataLib.forceArray(value)
		}
	}
	
	;---------
	; DESCRIPTION:    Create a new SelectorChoice instance.
	; PARAMETERS:
	;  dataIn (I,REQ) - Assocative array of data that the choice contains.
	;                 Format:
	;                  dataIn[LABEL] := VALUE
	;                 Special subscripts:
	;                  "ABBREV" - Abbreviation of choice, can also be an array.
	;                             The first one (the display one) will be available via .displayAbbrev
	;                  "NAME"   - Name of choice, later available via .name
	; RETURNS:        Reference to new SelectorChoice object
	;---------
	__New(dataIn) {
		this.data := dataIn
		this.data["ABBREV"] := DataLib.forceArray(this.data["ABBREV"]) ; Force abbreviations to be an array internally
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
		
		abbrev := this.data["ABBREV"]
		if(isObject(abbrev))
			return stringToTest.isAnyOf(abbrev)
		else
			return (stringToTest = abbrev)
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	data := {} ; {label: value}
	;endregion ------------------------------ PRIVATE ------------------------------
}
