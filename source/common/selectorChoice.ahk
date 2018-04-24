/* Row data structure class for use in Selector.
	
	Important pieces that actions will want to interact with:
		data[]		- Associative array of other data from the choice. Subscripted using the labels set in the input file's model row.
	
*/
class SelectorChoice {
	data := []
	
	; Constructor.
	__New(arr = "", name = "", abbrev = "", value = "") {
		if(arr) {
			this.data := arr
			; DEBUG.popup("Constructing", "SelectorRow", "Input array", arr, "Internal data", this.data)
		} else {
			this.data["NAME"]   := name
			this.data["ABBREV"] := abbrev
			this.data["VALUE"]  := value
		}
	}
	
	; Deep copy function.
	clone() {
		temp := new SelectorChoice()
		For l,d in this.data
			temp.data[l] := d
		return temp
	}
	
	; Debug info
	debugName := "SelectorChoice"
	debugToString(debugBuilder) {
		debugBuilder.addLine("Data", this.data)
	}
}