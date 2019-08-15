/*
	Base class to override Array's default base with, so we can add these functions directly to arrays.
	
	NOTE: the functions here are only guaranteed to work on numeric arrays (though they technically exist on associative arrays initially created with []).
	
	Example usage:
		ary := ["a", "b"]
		str := ary.join() ; str = "a,b"
*/

class ArrayBase {
	static isArray := true
	
	contains(needle) { ; Returns index of FIRST instance found
		For index,element in this
			if(element = needle)
				return index
		return ""
	}
	
	appendArray(arrayToAppend) {
		this.push(arrayToAppend*)
	}
	
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
	
	join(delim := ",") {
		outString := ""
		
		For _,value in this {
			if(outString)
				outString .= delim
			outString .= value
		}
		
		return outString
	}
	
	clear() {
		this.removeAt(this.minIndex(), this.length())
	}
}