/* Extension methods for Maps (associative arrays), installed on Map.Prototype.

	In v1, Object served as both plain objects and associative arrays. In v2, Map is the
	associative container. These methods are installed on Map.Prototype.

	Example usage:
;		obj := Map("A", 1, "B", 2)
;		result := obj.contains(2) ; result = "B"

*/

class _MapExt {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Check whether this map contains a particular value.
	; PARAMETERS:
	;  needle (I,REQ) - The value to search the map for.
	; RETURNS:        The first key where we found the value in question.
	;                 "" if we didn't find it at all.
	;---------
	contains(needle) {
		for index, element in this
			if element = needle
				return index
		return ""
	}

	;---------
	; DESCRIPTION:    Add the entries from the given map/object into this map.
	; PARAMETERS:
	;  objectToAppend (I,REQ) - The map/object to append the contents of.
	; RETURNS:        this
	; NOTES:          If the new map has the same key as this one, the new value will overwrite
	;                 our existing one, even if the new one is blank.
	;---------
	mergeFromObject(objectToAppend) {
		for index, value in objectToAppend
			this[index] := value

		return this
	}

	;---------
	; DESCRIPTION:    Get the keys of this map as an array.
	; RETURNS:        A numerically-indexed array of the keys, in order of those keys.
	;---------
	toKeysArray() {
		ary := []
		for key, _ in this
			ary.Push(key)
		return ary
	}
	;---------
	; DESCRIPTION:    Get the values of this map as an array.
	; RETURNS:        A numerically-indexed array of the values, in order of the original keys.
	;---------
	toValuesArray() {
		ary := []
		for _, value in this
			ary.Push(value)
		return ary
	}
	;endregion ------------------------------ PUBLIC ------------------------------
}

; Install all methods onto Map.Prototype
for propName in _MapExt.Prototype.OwnProps() {
	if SubStr(propName, 1, 2) != "__"
		Map.Prototype.DefineProp(propName, _MapExt.Prototype.GetOwnPropDesc(propName))
}
