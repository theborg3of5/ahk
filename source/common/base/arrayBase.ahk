/* Base class to override Array's default base with, so we can add these functions directly to arrays. --=
	
	NOTE: the functions here are only guaranteed to work on numeric arrays (though they technically exist on associative arrays initially created with []).
	
	Example usage:
;		ary := ["a", "b"]
;		str := ary.join() ; str = "a,b"
	
*/ ; =--

class ArrayBase {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Flag that lets us know that this is a proper array (not some other object).
	; RETURNS:        true
	;---------
	static isArray := true ; Flag for when we need to tell the difference between an array and an object.
	
	;---------
	; DESCRIPTION:    Check whether this array contains a particular value.
	; PARAMETERS:
	;  needle (I,REQ) - The value to search the array for.
	; RETURNS:        The first index where we found the value in question.
	;                 "" if we didn't find it at all.
	;---------
	contains(needle) {
		For index,element in this
			if(element = needle)
				return index
		return ""
	}
	
	;---------
	; DESCRIPTION:    Remove the first instance of the given value, if it exists in the array.
	; PARAMETERS:
	;  value (I,REQ) - The value to find and remove from the array.
	;---------
	removeFirstInstanceOf(value) {
		index := this.contains(value)
		if(index)
			this.RemoveAt(index)
	}
	
	;---------
	; DESCRIPTION:    Get the value just after the given index, incrementing that index to match.
	; PARAMETERS:
	;  index (IO,REQ) - The index to increment, then return the value for.
	; RETURNS:        The next value
	;---------
	next(ByRef index) {
		index++
		return this[index]
	}
	
	;---------
	; DESCRIPTION:    Get the value just before the given index, decrementing that index to match.
	; PARAMETERS:
	;  index (IO,REQ) - The index to decrement, then return the value for.
	; RETURNS:        The previous value
	;---------
	previous(ByRef index) {
		index--
		return this[index]
	}
	
	;---------
	; DESCRIPTION:    Append the values from the given array to the end of this array.
	; PARAMETERS:
	;  arrayToAppend (I,REQ) - The array of values to add.
	;---------
	appendArray(arrayToAppend) {
		this.push(arrayToAppend*)
	}
	
	;---------
	; DESCRIPTION:    Removes any duplicate entries from the array, leaving the first instance alone.
	;---------
	removeDuplicates() {
		; Move everything over to a temporary array
		tempAry := []
		For _,value in this
			tempAry.push(value)
		this.clear()
		
		; Add only unique values back in
		For _,value in tempAry {
			if(!this.contains(value))
				this.push(value)
		}
	}
	
	;---------
	; DESCRIPTION:    Removes any empty ("") entries from the array.
	;---------
	removeEmpties() {
		; Move everything over to a temporary array
		tempAry := []
		For _,value in this
			tempAry.push(value)
		this.clear()
		
		; Add only non-empty values back in
		For _,value in tempAry {
			if(value != "")
				this.push(value)
		}
	}
	
	;---------
	; DESCRIPTION:    Combine all array values into a single string.
	; PARAMETERS:
	;  delim (I,OPT) - Delimiter to include between array entries. Defaults to a comma (,).
	; RETURNS:        Combined string
	;---------
	join(delim := ",") {
		outString := ""
		
		For _,value in this {
			if(outString) ; Can't use .appendPiece for this because it ignores empty values (which we want to keep).
				outString .= delim
			outString .= value
		}
		
		return outString
	}
	
	;---------
	; DESCRIPTION:    Remove all entries from this array.
	;---------
	clear() {
		if(this.length() = 0)
			return
		this.removeAt(this.minIndex(), this.length())
	}
	
	; #END#
}
