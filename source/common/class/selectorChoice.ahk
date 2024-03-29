; Representation of a single choice within a Selector object.

class SelectorChoice {
	; #PUBLIC#
	
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
			abbrev := this.data["ABBREV"]
			if(isObject(abbrev))
				return abbrev[1]
			else
				return abbrev
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
			return abbrev.contains(stringToTest)
		else
			return (stringToTest = abbrev)
	}
	
	
	; #PRIVATE#
	
	data := {} ; {label: value}
	; #END#
}
