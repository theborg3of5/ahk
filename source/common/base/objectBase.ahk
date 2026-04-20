/* Extension methods for Maps (associative arrays), installed on Map.Prototype.

	In v1, Object served as both plain objects and associative arrays. In v2, Map is the
	associative container. These methods are installed on Map.Prototype.

	Example usage:
;		obj := Map("A", 1, "B", 2)
;		result := obj.contains(2) ; result = "B"

*/

class _MapExt {
	;region ------------------------------ PUBLIC ------------------------------
	contains(needle) {
		for index, element in this
			if element = needle
				return index
		return ""
	}

	mergeFromObject(objectToAppend) {
		for index, value in objectToAppend
			this[index] := value

		return this
	}

	toKeysArray() {
		ary := []
		for key, _ in this
			ary.Push(key)
		return ary
	}

	toValuesArray() {
		ary := []
		for _, value in this
			ary.Push(value)
		return ary
	}
	;endregion ------------------------------ PUBLIC ------------------------------
}

; Install all methods onto Map.Prototype
for name in _MapExt.Prototype.OwnProps() {
	if SubStr(name, 1, 2) != "__"
		Map.Prototype.DefineProp(name, _MapExt.Prototype.GetOwnPropDesc(name))
}
