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
			StrLen							=>	.length
			stringContains					=>	.contains
			StrSplit							=>	.split
			stringStartsWith				=>	.startsWith
			stringEndsWith					=>	.endsWith
			getStringBeforeStr			=>	.getBeforeString
			getStringAfterStr				=> .getAfterString
			getFirstStringBetweenStr	=> .getFirstBetweenStrings
			getFullStringBetweenStr		=> .getAllBetweenStrings
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
	
	contains(needle, searchFromEnd := false) {
		if(searchFromEnd)
			return InStr(this, needle, , 0)
		else
			return InStr(this, needle)
	}
	
	sub(startPos, length := "") {
		if(length = "")
			return subStr(this, startPos)
		else
			return subStr(this, startPos, length)
	}
	slice(startPos, stopAtPos) {
		return this.sub(startPos, stopAtPos - startPos)
	}
	
	startsWith(startString) {
		return (this.sub(1, startString.length()) = startString)
	}
	endsWith(endString) {
		return (this.sub(this.length() - endString.length() + 1) = endString)
	}
	
	getBeforeString(endString, searchFromEnd := false) {
		endStringPos := this.contains(endString, searchFromEnd)
		if(!endStringPos)
			return this
		
		return this.sub(1, endStringPos - 1)
	}
	getAfterString(startString, searchFromEnd := false) {
		startStringPos := this.contains(startString, searchFromEnd)
		if(!startStringPos)
			return this
		
		return this.sub(startStringPos + startString.length())
	}
	
	getFirstBetweenStrings(startString, endString, upToLastEndString := false) {
		return getFirstStringBetweenStr(this, startString, endString, false)
	}
	getAllBetweenStrings(startString, endString) {
		return getFirstStringBetweenStr(this, startString, endString, true)
	}
	
	split(delimiters := "", surroundingCharsToDrop := "") { ; Like StrSplit(), but returns an actual array (not an object)
		obj := StrSplit(this, delimiters, surroundingCharsToDrop)
		return convertObjectToArray(obj)
	}
	
	
; ==============================
; == Private ===================
; ==============================
	
	getBetweenStrings(startString, endString, upToLastEndString) {
		; Trim off everything before (and including) the first instance of the startString
		outString := this.getBeforeString(startString)
		
		; Trim off everything before (and including) the remaining instance (first or last depending on upToLastEndString) of the endString
		return outString.getBeforeString(endString, upToLastEndString)
	}
}