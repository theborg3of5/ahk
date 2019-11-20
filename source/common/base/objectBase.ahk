/* Base class to override Object's default base with, so we can add these functions directly to objects. --=
	
	Example usage:
		obj := {"A":1, "B":2}
		result := obj.contains(2) ; result = "B"
	
*/ ; =--

class ObjectBase {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Temporary override for built-in .count() function, until everywhere I use AHK
	;                 is updated to at least 1.1.29.00.
	; RETURNS:        Number of key/element pairs in the object
	;---------
	count() {
		functionName := "ObjCount"
		if(IsFunc(functionName))
			return %functionName%(this)
		
		; The below is to support prior to AHK v1.1.29.00 (where ObjCount()/.count() did not yet exist).
		keyCount := 0
		For _,_ in this
			keyCount++
		
		return keyCount
	}
	
	;---------
	; DESCRIPTION:    Check whether this object contains a particular value.
	; PARAMETERS:
	;  needle (I,REQ) - The value to search the object for.
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
	; DESCRIPTION:    Add the basic members (not including functions) from the given object into
	;                 this object.
	; PARAMETERS:
	;  objectToAppend (I,REQ) - The object to append the contents of.
	; RETURNS:        this
	; NOTES:          If the new object has the same key as this one, the new value will overwrite
	;                 our existing one, even if the new one is blank.
	;---------
	mergeFromObject(objectToAppend) {
		For index,value in objectToAppend
			this[index] := value
		
		return this
	}
	; #END#
}
