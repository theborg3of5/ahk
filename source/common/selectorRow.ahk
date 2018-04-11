/* Row data structure class for use in Selector.
	
	Important pieces that actions will want to interact with:
		data[]		- Associative array of other data from the choice. Subscripted using the labels set in the input file's model row.
	
*/
class SelectorRow {
	data := []
	
	; Constructor.
	__New(arr = "", name = "", abbrev = "", action = "") {
		if(arr) {
			this.data := arr
			; DEBUG.popup("Constructing", "SelectorRow", "Input array", arr, "Internal data", this.data)
		} else {
			this.data["NAME"] := name
			this.data["ABBREV"] := abbrev
			this.data["DOACTION"] := action
		}
	}
	
	; Deep copy function.
	clone() {
		temp := new SelectorRow()
		For l,d in this.data
			temp.data[l] := d
		return temp
	}
	
	; Debug info
	debugName := "SelectorRow"
	debugToString(debugBuilder) {
		debugBuilder.addLine("Data", this.data)
	}
}