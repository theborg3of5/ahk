/*
	Base class for strings to extend (technically for their base to extend), so we can add these functions directly to strings.
	
	Note: this does not allow you to manipulate the string itself - all functions return the result of the operation.
		For example: appendPiece() returns the new string, so you must capture the return value instead of just calling it (i.e. str := str.appendPiece() instead of just str.appendPiece())
	
	Example usage:
		str := "abcd"
		result := str.contains("b") ; result = 2
*/

class StringBase {

; ==============================
; == Public ====================
; ==============================
	
	;---------
	; DESCRIPTION:    Wrapper for StrLen().
	; RETURNS:        Length of string
	;---------
	length() {
		return StrLen(this)
	}
	
	;---------
	; DESCRIPTION:    Wrapper functions for whether a string is alphabetic, numeric, or alphanumeric.
	; RETURNS:        True if the string is, False otherwise.
	;---------
	isAlpha() {
		return IfIs(this, "Alpha")
	}
	isNum() {
		return IfIs(this, "Number")
	}
	isAlphaNum() {
		return IfIs(this, "AlNum")
	}
	
	;---------
	; DESCRIPTION:    Wrapper for InStr() - check if a string contains a search string.
	; PARAMETERS:
	;  needle        (I,REQ) - String to search for
	;  searchFromEnd (I,OPT) - Whether to reverse search (start from end and return the position of the last match)
	; RETURNS:        The position of the match we found (first or last, depending on searchFromEnd parameter)
	;                 0 if nothing found
	;---------
	contains(needle, searchFromEnd := false) {
		if(searchFromEnd)
			return InStr(this, needle, , 0)
		else
			return InStr(this, needle)
	}
	;---------
	; DESCRIPTION:    Wrapper for RegExMatch() - check if a string contains a search regex.
	; PARAMETERS:
	;  needleRegEx (I,REQ) - RegEx to search for
	;  outputVar   (O,OPT) - Output variable - can be the matched string, position+length, or a
	;                        match object (depending on the mode specified in needleRegEx, see
	;                        RegExMatch() for details).
	; RETURNS:        The position of the first match, 0 if nothing found.
	; SIDE EFFECTS:   
	; NOTES:          
	;---------
	containsRegEx(needleRegEx, ByRef outputVar := "") {
		return RegExMatch(this, needleRegEx, outputVar)
	}
	
	;---------
	; DESCRIPTION:    Count how many times a search string occurs in this string.
	; PARAMETERS:
	;  needle (I,REQ) - The search string
	; RETURNS:        How many times the search string appears.
	;---------
	countMatches(needle) {
		StrReplace(this, needle, , matchCount, -1)
		return matchCount
	}
	
	;---------
	; DESCRIPTION:    Wrapper for .contains() which takes an array of search strings.
	; PARAMETERS:
	;  needlesAry    (I,REQ) - The array of strings to search for
	;  matchedNeedle (O,OPT) - The needle that we matched
	; RETURNS:        The position of the first occurrence of any needle.
	;---------
	containsAnyOf(needlesAry, ByRef matchedNeedle := "") {
		earliestMatchedPos := 0
		
		For i,needle in needlesAry {
			matchedPos := this.contains(needle)
			if(matchedPos) {
				if(!earliestMatchedPos || (matchedPos < earliestMatchedPos)) {
					earliestMatchedPos := matchedPos
					matchedNeedle := needle
				}
			}
		}
		
		return earliestMatchedPos
	}
	
	;---------
	; DESCRIPTION:    Check whether this string starts/ends with the provided string.
	; PARAMETERS:
	;  checkString (I,REQ) - The string to check whether this string starts/ends with.
	; RETURNS:        True if it does, False otherwise.
	;---------
	startsWith(checkString) {
		return (this.sub(1, checkString.length()) = checkString)
	}
	endsWith(checkString) {
		return (this.sub(this.length() - checkString.length() + 1) = checkString)
	}
	
	;---------
	; DESCRIPTION:    Wrapper for .startsWith() that takes an array of strings to check.
	; PARAMETERS:
	;  needlesAry (I,REQ) - Array of strings to check.
	; RETURNS:        True if this string starts with any of the provided check strings, False otherwise.
	;---------
	startsWithAnyOf(needlesAry) {
		For i,needle in needlesAry {
			if(this.startsWith(needle))
				return true
		}
		
		return false
	}
	
	;---------
	; DESCRIPTION:    Wrapper for SubStr() - returns a chunk of this string.
	; PARAMETERS:
	;  startPos (I,REQ) - Position to start at (first character is position 1). Can be negative to count from end of string.
	;  length   (I,OPT) - Number of characters to include. If left blank, we'll return the entire rest of the string.
	; RETURNS:        The chunk of this string specified.
	;---------
	sub(startPos, length := "") {
		if(length = "")
			return SubStr(this, startPos)
		else
			return SubStr(this, startPos, length)
	}
	
	;---------
	; DESCRIPTION:    Return a chunk of this string, given starting and ending positions.
	; PARAMETERS:
	;  startPos  (I,REQ) - Starting position
	;  stopAtPos (I,REQ) - Ending position - return up to here, non-inclusive.
	; RETURNS:        Chunk of this string specified.
	;---------
	slice(startPos, stopAtPos) {
		return this.sub(startPos, stopAtPos - startPos)
	}
	
	;---------
	; DESCRIPTION:    Get the portion of this string before/after the given string.
	; PARAMETERS:
	;  checkString   (I,REQ) - The string to return before/after. Will not be included in the result (unless there are multiple)
	;  searchFromEnd (I,OPT) - Set to True to start searching from the end of the string instead of the start.
	; RETURNS:        The requested portion of this string.
	;---------
	beforeString(checkString, searchFromEnd := false) {
		checkStringPos := this.contains(checkString, searchFromEnd)
		if(!checkStringPos)
			return this
		
		return this.sub(1, checkStringPos - 1)
	}
	afterString(checkString, searchFromEnd := false) {
		checkStringPos := this.contains(checkString, searchFromEnd)
		if(!checkStringPos)
			return this
		
		return this.sub(checkStringPos + checkString.length())
	}
	
	;---------
	; DESCRIPTION:    Get the portion of the string that is between the two provided strings. This
	;                 is the non-greedy function - it will go from the first instance of startString
	;                 to the first instance of endString.
	; PARAMETERS:
	;  startString (I,REQ) - String to start matching at
	;  endString   (I,REQ) - String to finish matching at
	; RETURNS:        Requested chunk of this string.
	;---------
	firstBetweenStrings(startString, endString) {
		return this.getBetweenStrings(startString, endString, false)
	}
	
	;---------
	; DESCRIPTION:    Get the portion of the string that is between the two provided strings. This
	;                 is the greedy function - it will go from the first instance of startString
	;                 to the LAST instance of endString.
	; PARAMETERS:
	;  startString (I,REQ) - String to start matching at
	;  endString   (I,REQ) - String to finish matching at
	; RETURNS:        Requested chunk of this string.
	;---------
	allBetweenStrings(startString, endString) {
		return this.getBetweenStrings(startString, endString, true)
	}
	
	;---------
	; DESCRIPTION:    Remove a string (if it exists) from the start/end of this string.
	; PARAMETERS:
	;  toRemove (I,REQ) - The string to remove from the start or end of this string.
	; RETURNS:        The updated string, after removing toRemove.
	;---------
	removeFromStart(toRemove) {
		if(!this.startsWith(toRemove))
			return this
		
		return this.sub(toRemove.length() + 1)
	}
	removeFromEnd(toRemove) {
		if(!this.endsWith(toRemove))
			return this
		
		return this.sub(1, this.length() - toRemove.length())
	}
	
	;---------
	; DESCRIPTION:    Add a string to the beginning/end of this string, but only if that string is
	;                 not already in place.
	; PARAMETERS:
	;  strToAdd (I,REQ) - String to add at the beginning/end.
	; RETURNS:        Updated string.
	;---------
	prependIfMissing(strToAdd) {
		if(this.sub(1, strToAdd.length()) != strToAdd)
			return strToAdd this
		
		return this
	}
	appendIfMissing(strToAdd) {
		if(this.sub(- (strToAdd.length() - 1) ) != strToAdd)
			return this strToAdd
		
		return this
	}
	
	;---------
	; DESCRIPTION:    Get the first line of this string.
	; RETURNS:        The first line of this string (everything up to the first newline)
	;---------
	firstLine() {
		return this.beforeString("`n")
	}
	
	;---------
	; DESCRIPTION:    Get the string, with no leading/trailing whitespace.
	; RETURNS:        The string without whitespace.
	;---------
	withoutWhitespace() {
		newText = %this% ; Note using = not :=, to drop whitespace.
		return newText
	}
	
	;---------
	; DESCRIPTION:    Left-pad the string to the specified length.
	; PARAMETERS:
	;  numChars (I,REQ) - How many characters the final string should be (at minimum).
	;  withChar (I,OPT) - The character to use to do the padding. Defaults to space ( ).
	; RETURNS:        The string, padded out to the specified length.
	;---------
	prePadToLength(numChars, withChar := " ") {
		outStr := this
		
		while(outStr.length() < numChars)
			outStr := withChar outStr
		
		return outStr
	}
	
	;---------
	; DESCRIPTION:    Wrappers for StrReplace - replace all (or one) instance(s) of the provided
	;                 string, with the replacement text.
	; PARAMETERS:
	;  needle      (I,REQ) - String to replace
	;  replaceWith (I,REQ) - String to replace with
	; RETURNS:        The updated string
	; NOTES:          If you just want to remove all instances of a string, use .remove() instead.
	;---------
	replace(needle, replaceWith) {
		return StrReplace(this, needle, replaceWith) ; Replace all
	}
	replaceOne(needle, replaceWith) {
		return StrReplace(this, needle, replaceWith, "", 1) ; Replace 1
	}
	
	;---------
	; DESCRIPTION:    Remove all instances of the provided string from this string.
	; PARAMETERS:
	;  needle (I,REQ) - Text to remove all instances of.
	; RETURNS:        The updated string
	;---------
	remove(needle) {
		return this.replace(needle, "")
	}
	
	;---------
	; DESCRIPTION:    Wrapper for RegExReplace - replace all matches for the provided RegEx, with
	;                 the provided replacement text.
	; PARAMETERS:
	;  needleRegEx (I,REQ) - RegEx to match on.
	;  replaceWith (I,REQ) - Text to replace matches with.
	; RETURNS:        The updated string
	; NOTES:          If you just want to remove all matches, use .removeRegEx() intead.
	;---------
	replaceRegEx(needleRegEx, replaceWith) {
		return RegExReplace(this, needleRegEx, replaceWith) ; Replace all
	}
	
	;---------
	; DESCRIPTION:    Remove all matches for the provided RegEx from this string.
	; PARAMETERS:
	;  needleRegEx (I,REQ) - RegEx to match on.
	; RETURNS:        The updated string
	;---------
	removeRegEx(needleRegEx) {
		return this.replaceRegEx(needleRegEx, "")
	}
	
	;---------
	; DESCRIPTION:    Append a piece to this string with a delimiter, but only add a delimiter if it's needed.
	; PARAMETERS:
	;  pieceToAdd (I,REQ) - Piece to add to the string
	;  delimiter  (I,OPT) - Delimiter to add before the new piece (if applicable). Defaults to a comma (,).
	; RETURNS:        The updated string.
	;---------
	appendPiece(pieceToAdd, delimiter := ",") {
		if(pieceToAdd = "")
			return this
		if(this = "")
			return pieceToAdd
		
		return this delimiter pieceToAdd
	}
	
	;---------
	; DESCRIPTION:    Replace a tag ("<TAG_NAME>") in this string with the provided replacement.
	; PARAMETERS:
	;  tagName     (I,REQ) - The name of the tag to replace (no angle brackets)
	;  replacement (I,REQ) - The text to replace all instances of the tag with.
	; RETURNS:        The updated string.
	;---------
	replaceTag(tagName, replacement) {
		return this.replace("<" tagName ">", replacement)
	}
	
	;---------
	; DESCRIPTION:    Replace multiple tags with corresponding replacement texts (see .replaceTag()).
	; PARAMETERS:
	;  tagsAry (I,REQ) - Array of tag names and replacements. Format:
	;                       tagsAry["TAG_NAME"] := REPLACEMENT_TEXT
	; RETURNS:        The updated string.
	;---------
	replaceTags(tagsAry) {
		outputString := this
		
		For tagName, replacement in tagsAry
			outputString := outputString.replaceTag(tagName, replacement)
		
		return outputString
	}
	
	;---------
	; DESCRIPTION:    Remove certain characters (and optionally, additional passed-in strings) from
	;                 the start and end of this string.
	; PARAMETERS:
	;  additionalStringsToRemove (I,OPT) - Pass in an array of strings to have them also removed
	;                                      from the start and end of this string.
	; RETURNS:        The updated string
	; NOTES:          Order doesn't matter - we keep cleaning until we don't find any of the
	;                 provided strings at the start or end of the output.
	;---------
	clean(additionalStringsToRemove := "") {
		outStr := this
		
		charCodesToRemove := []
		charCodesToRemove.push([13])      ; Carriage return (`r)
		charCodesToRemove.push([10])      ; Newline (`n)
		charCodesToRemove.push([32])      ; Space ( )
		charCodesToRemove.push([46])      ; Period (.)
		charCodesToRemove.push([8226,9])  ; First level bullet (filled circle) + tab
		charCodesToRemove.push([111,9])   ; Second level bullet (empty circle) + tab
		charCodesToRemove.push([61607,9]) ; Third level bullet (filled square) + tab
		
		; Transform the codes above so we can check whether it's in the string.
		stringsToRemove := []
		For i,s in charCodesToRemove {
			stringsToRemove[i] := ""
			For j,c in s {
				newChar := Transform("Chr", c)
				stringsToRemove[i] .= newChar
			}
		}
		For i,str in additionalStringsToRemove {
			stringsToRemove.push(str)
		}
		; DEBUG.popup("outStr",outStr, "Chars to remove",stringsToRemove)
		
		while(!isClean) {
			isClean := true
			
			; Leading/trailing whitespace
			noWhitespace := outStr.withoutWhitespace()
			if(noWhitespace != outStr) {
				outStr := noWhitespace
				isClean := false
			}
			
			; Remove specific strings from start/end
			For _,removeString in stringsToRemove {
				if(outStr.startsWith(removeString)) {
					outStr := outStr.removeFromStart(removeString)
					isClean := false
				}
				if(outStr.endsWith(removeString)) {
					outStr := outStr.removeFromEnd(removeString)
					isClean := false
				}
			}
		}
		
		return outStr
	}
	
	;---------
	; DESCRIPTION:    A wrapper for StrSplit() that returns an actual array (not an object).
	; PARAMETERS:
	;  delimiters             (I,OPT) - Delimiter(s) to split on
	;  surroundingCharsToDrop (I,OPT) - Characters to drop from around each piece
	; RETURNS:        Array of split-up string
	;---------
	split(delimiters := "", surroundingCharsToDrop := "") { ; Like StrSplit(), but returns an actual array (not an object)
		obj := StrSplit(this, delimiters, surroundingCharsToDrop)
		return convertObjectToArray(obj)
	}
	
	
; ==============================
; == Private ===================
; ==============================
	
	;---------
	; DESCRIPTION:    Get the portion of this string that is between the provided strings.
	; PARAMETERS:
	;  startString       (I,REQ) - String to start at
	;  endString         (I,REQ) - String to finish at
	;  upToLastEndString (I,REQ) - False to stop at the first endString, True to be greedy and get
	;                              everything up to the last instance of endString.
	; RETURNS:        The string between the provided strings.
	;---------
	getBetweenStrings(startString, endString, upToLastEndString) {
		; Trim off everything before (and including) the first instance of the startString
		outStr := this.afterString(startString)
		
		; Trim off everything before (and including) the remaining instance (first or last depending on upToLastEndString) of the endString
		return outStr.beforeString(endString, upToLastEndString)
	}
}