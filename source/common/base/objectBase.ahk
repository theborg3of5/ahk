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
	; DESCRIPTION:    Recursively merge the keys/properties from another object into this one.
	; PARAMETERS:
	;  overrides (I,REQ) - The object to merge data from. The object in this parameter "wins" when
	;                      both this parameter and the instance of this class have the same
	;                      index/property - that is, we'll replace the value on the class instance
	;                      with the value from this parameter.
	; RETURNS:        this
	;---------
	mergeFromObject(objectToAppend) {
		For index,value in objectToAppend {
			if(IsObject(value))
				this[index] := DataLib.mergeObjects(this[index], value)
			else
				this[index] := value
		}
		
		return this
	}
	
	;---------
	; DESCRIPTION:    Add the basic members (not including functions) from the given object into
	;                 this object.
	; PARAMETERS:
	;  objectToAppend (I,REQ) - The object to merge content from.
	; RETURNS:        this
	; NOTES:          If the new object has the same key as this one, the new value will overwrite
	;                 our existing one, even if the new one is blank.
	;---------
	appendObject(objectToAppend) {
		For index,value in objectToAppend
			this[index] := value
		
		return this
	}
	; #END#
}
