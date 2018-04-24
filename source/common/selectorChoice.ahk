/* Representation of a single choice within a Selector object.
*/

class SelectorChoice {
	data := [] ; LABEL => VALUE
	
	;---------
	; DESCRIPTION:    Create a new SelectorChoice instance.
	; PARAMETERS:
	;  data (I,REQ) - Assocative array of data that the choice contains.
	;                 Format:
	;                  data[LABEL] := VALUE
	;                 Special subscripts:
	;                  "ABBREV" - Abbreviation of choice, later accessible via .getAbbrev
	;                  "NAME"   - Name of choice, later accessible via .getName
	; RETURNS:        Reference to new SelectorChoice object
	;---------
	__New(data) {
		this.data := data
	}
	
	; Getter functions
	getData() {
		return this.data
	}
	getName() {
		return this.data["NAME"]
	}
	getAbbrev() {
		return this.data["ABBREV"]
	}
	
	; Debug info
	debugName := "SelectorChoice"
	debugToString(debugBuilder) {
		debugBuilder.addLine("Data", this.data)
	}
}