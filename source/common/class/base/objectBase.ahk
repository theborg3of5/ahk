/*
	Base class to override Object's default base with, so we can add these functions directly to objects.
	
	Example usage:
		obj := {"A":1, "B":2}
		result := obj.contains(2) ; result = "B"
*/

class ObjectBase {

; ==============================
; == Public ====================
; ==============================
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
}