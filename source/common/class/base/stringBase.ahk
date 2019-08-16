/*
	Base class for strings to extend (technically for their base to extend), so we can add these functions directly to strings.
	
	Example usage:
		str := "abcd"
		result := str.contains("b") ; result = 2
*/

/*
	Do
		Functions to consider moving here
			stringMatches
			stringMatchesAnyOf
			getStringBeforeStr
			getStringAfterStr
			getFirstStringBetweenStr
			getFullStringBetweenStr
			getFirstLine
			cleanupText
			dropWhitespace
			appendPieceToString
			replaceTags
			replaceTag
			removeStringFromStart
			removeStringFromEnd
			prependCharIfMissing
			appendCharIfMissing
			prePadStringToLength
		Functions to replace and remove
			stringContains					=>	.contains
			StrSplit							=>	.split
			stringStartsWith				=>	.startsWith
			stringEndsWith					=>	.endsWith
*/

class StringBase {

; ==============================
; == Public ====================
; ==============================
	
	length() {
		return StrLen(this)
	}
	
	; Wrapper function for whether a string is alphabetic.
	isAlpha() {
		return IfIs(this, "Alpha")
	}

	; Wrapper function for whether a string is numeric.
	isNum() {
		return IfIs(this, "Number")
	}

	; Wrapper function for whether a string is alphanumeric.
	isAlphaNum() {
		return IfIs(this, "AlNum")
	}
	
	contains(needle, fromLastInstance := false) {
		if(fromLastInstance)
			return InStr(this, needle, , 0)
		else
			return InStr(this, needle)
	}
	
	startsWith(startString) {
		return (subStr(this, 1, strLen(startString)) = startString)
	}
	endsWith(endString) {
		return (subStr(this, strLen(this) - strLen(endString) + 1) = endString)
	}
	
	split(delimiters := "", surroundingCharsToDrop := "") { ; Like StrSplit(), but returns an actual array (not an object)
		obj := StrSplit(this, delimiters, surroundingCharsToDrop)
		return convertObjectToArray(obj)
	}
}