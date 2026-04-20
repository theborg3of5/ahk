/* Extension methods for arrays, installed on Array.Prototype.

	NOTE: the functions here are only guaranteed to work on numeric arrays.

	Example usage:
;		ary := ["a", "b"]
;		str := ary.join() ; str = "a,b"

*/

class _ArrayExt {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Check whether this array contains a particular value.
	; PARAMETERS:
	;  needle (I,REQ) - The value to search the array for.
	; RETURNS:        The first index where we found the value in question.
	;                 "" if we didn't find it at all.
	;---------
	contains(needle) {
		for index, element in this
			if element = needle
				return index
		return ""
	}

	;---------
	; DESCRIPTION:    Remove the first instance of the given value, if it exists in the array.
	; PARAMETERS:
	;  value (I,REQ) - The value to find and remove from the array.
	; RETURNS:        This array
	;---------
	removeFirstInstanceOf(value) {
		index := this.contains(value)
		if index
			this.RemoveAt(index)

		return this
	}

	;---------
	; DESCRIPTION:    Get the value just after the given index, incrementing that index to match.
	; PARAMETERS:
	;  index (IO,REQ) - The index to increment, then return the value for.
	; RETURNS:        The next value
	;---------
	next(&index) {
		index++
		return this[index]
	}

	;---------
	; DESCRIPTION:    Get the value just before the given index, decrementing that index to match.
	; PARAMETERS:
	;  index (IO,REQ) - The index to decrement, then return the value for.
	; RETURNS:        The previous value
	;---------
	previous(&index) {
		index--
		return this[index]
	}

	;---------
	; DESCRIPTION:    Get the first element of this array.
	; RETURNS:        The first element.
	;---------
	first() {
		return this[1]
	}

	;---------
	; DESCRIPTION:    Get the last element of this array.
	; RETURNS:        The last element.
	;---------
	last() {
		return this[this.Length]
	}

	;---------
	; DESCRIPTION:    Append the values from the given array to the end of this array.
	; PARAMETERS:
	;  arrayToAppend (I,REQ) - The array of values to add.
	; RETURNS:        This array
	;---------
	appendArray(arrayToAppend) {
		this.Push(arrayToAppend*)
		return this
	}

	;---------
	; DESCRIPTION:    Removes any duplicate entries from the array, leaving the first instance alone.
	; RETURNS:        This array
	;---------
	removeDuplicates() {
		tempAry := []
		for _, value in this
			tempAry.Push(value)
		this.clear()

		for _, value in tempAry {
			if !this.contains(value)
				this.Push(value)
		}

		return this
	}

	;---------
	; DESCRIPTION:    Removes any empty ("") entries from the array.
	; RETURNS:        This array
	;---------
	removeEmpties() {
		tempAry := []
		for _, value in this
			tempAry.Push(value)
		this.clear()

		for _, value in tempAry {
			if value != ""
				this.Push(value)
		}

		return this
	}

	;---------
	; DESCRIPTION:    Combine all array values into a single string.
	; PARAMETERS:
	;  delim (I,OPT) - Delimiter to include between array entries. Defaults to a comma (,).
	; RETURNS:        Combined string
	;---------
	join(delim := ",") {
		outString := ""

		for _, value in this {
			if outString != ""
				outString .= delim
			outString .= value
		}

		return outString
	}

	;---------
	; DESCRIPTION:    Remove all entries from this array.
	; RETURNS:        This array
	;---------
	clear() {
		this.Length := 0
		return this
	}
	;endregion ------------------------------ PUBLIC ------------------------------
}

; Install all methods onto Array.Prototype
for name in _ArrayExt.Prototype.OwnProps() {
	if SubStr(name, 1, 2) != "__"
		Array.Prototype.DefineProp(name, _ArrayExt.Prototype.GetOwnPropDesc(name))
}
