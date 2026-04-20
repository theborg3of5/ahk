/* Extension methods for arrays, installed on Array.Prototype.

	NOTE: the functions here are only guaranteed to work on numeric arrays.

	Example usage:
;		ary := ["a", "b"]
;		str := ary.join() ; str = "a,b"

*/

class _ArrayExt {
	;region ------------------------------ PUBLIC ------------------------------
	contains(needle) {
		for index, element in this
			if element = needle
				return index
		return ""
	}

	removeFirstInstanceOf(value) {
		index := this.contains(value)
		if index
			this.RemoveAt(index)

		return this
	}

	next(&index) {
		index++
		return this[index]
	}

	previous(&index) {
		index--
		return this[index]
	}

	first() {
		return this[1]
	}

	last() {
		return this[this.Length]
	}

	appendArray(arrayToAppend) {
		this.Push(arrayToAppend*)
		return this
	}

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

	join(delim := ",") {
		outString := ""

		for _, value in this {
			if outString != ""
				outString .= delim
			outString .= value
		}

		return outString
	}

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
