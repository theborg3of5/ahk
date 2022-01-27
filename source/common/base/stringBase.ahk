/* Base class for strings to extend (technically for their base to extend), so we can add these functions directly to strings. =--
	
	Note: this does not allow you to manipulate the string itself - all functions return the result of the operation.
		For example: appendPiece() returns the new string, so you must capture the return value instead of just calling it (i.e. str := str.appendPiece() instead of just str.appendPiece())
	
	Example usage:
;		str := "abcd"
;		result := str.contains("b") ; result = 2
	
*/ ; --=

class StringBase {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Wrapper for StrLen().
	; RETURNS:        Length of string
	;---------
	length() {
		return StrLen(this)
	}
	
	;---------
	; DESCRIPTION:    Wrapper for whether a string is alphabetic.
	; RETURNS:        true/false
	;---------
	isAlpha() {
		return IfIs(this, "Alpha")
	}
	;---------
	; DESCRIPTION:    Wrapper function for whether a string is numeric.
	; RETURNS:        true/false
	;---------
	isNum() {
		return IfIs(this, "Number")
	}
	;---------
	; DESCRIPTION:    Wrapper function for whether a string is alphanumeric.
	; RETURNS:        true/false
	;---------
	isAlphaNum() {
		return IfIs(this, "AlNum")
	}
	
	;---------
	; DESCRIPTION:    Check whether this object is both a number and even.
	; RETURNS:        true/false
	;---------
	isEvenNum() {
		return ( this.isNum() && (mod(this, 2) = 0) )
	}
	
	;---------
	; DESCRIPTION:    Check whether this object is both a number and odd.
	; RETURNS:        true/false
	;---------
	isOddNum() {
		return ( this.isNum() && (mod(this, 2) = 1) )
	}
	
	;---------
	; DESCRIPTION:    Return the single character at the given position in the string.
	; PARAMETERS:
	;  pos (I,REQ) - The position, where the first character is 1. 0 and below are treated as the
	;                number of characters from the end of the string - 0 is the last character,
	;                -1 is the next-to-last character, etc.
	; RETURNS:        The character from the given position.
	;---------
	charAt(pos) {
		return this.sub(pos, 1)
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
	;---------
	matchesRegEx(needleRegEx, ByRef outputVar := "") {
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
	;  needlesAry    (I,REQ) - The array/object of strings to search for (we'll search for the values, not the keys/indices)
	;  matchedNeedle (O,OPT) - The needle that we matched
	; RETURNS:        The position of the first occurrence of any needle.
	;---------
	containsAnyOf(needlesAry, ByRef matchedNeedle := "") {
		earliestMatchedPos := 0
		
		For _,needle in needlesAry {
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
	; DESCRIPTION:    Check whether this string starts with the provided string.
	; PARAMETERS:
	;  checkString (I,REQ) - The string to check whether this string starts with.
	; RETURNS:        True if it does, False otherwise.
	;---------
	startsWith(checkString) {
		return (this.sub(1, checkString.length()) = checkString)
	}
	;---------
	; DESCRIPTION:    Check whether this string ends with the provided string.
	; PARAMETERS:
	;  checkString (I,REQ) - The string to check whether this string ends with.
	; RETURNS:        True if it does, False otherwise.
	;---------
	endsWith(checkString) {
		return (this.sub(this.length() - checkString.length() + 1) = checkString)
	}
	
	;---------
	; DESCRIPTION:    Wrapper for .startsWith() that takes an array of strings to check.
	; PARAMETERS:
	;  needlesAry    (I,REQ) - Array of strings to check.
	;  matchedNeedle (O,OPT) - The first matching entry we found in the needlesAry.
	; RETURNS:        True if this string starts with any of the provided check strings, False otherwise.
	;---------
	startsWithAnyOf(needlesAry, ByRef matchedNeedle := "") {
		For _,needle in needlesAry {
			if(this.startsWith(needle)) {
				matchedNeedle := needle
				return true
			}
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
	; DESCRIPTION:    Get the portion of this string before the given string.
	; PARAMETERS:
	;  checkString   (I,REQ) - The string to return before, will not be included in the result
	;                          (unless there are multiple).
	;  searchFromEnd (I,OPT) - Set to True to start searching from the end of the string instead of
	;                          the start.
	; RETURNS:        The requested portion of this string.
	; NOTES:          If checkString isn't found, we return the original string.
	;---------
	beforeString(checkString, searchFromEnd := false) {
		checkStringPos := this.contains(checkString, searchFromEnd)
		if(!checkStringPos)
			return this
		
		return this.sub(1, checkStringPos - 1)
	}
	;---------
	; DESCRIPTION:    Get the portion of this string after the given string.
	; PARAMETERS:
	;  checkString   (I,REQ) - The string to return after, will not be included in the result
	;                          (unless there are multiple).
	;  searchFromEnd (I,OPT) - Set to True to start searching from the end of the string instead of
	;                          the start.
	; RETURNS:        The requested portion of this string.
	; NOTES:          If checkString isn't found, we return the original string.
	;---------
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
	; RETURNS:        Requested chunk of this string, with some caveats:
	;                  - endString not found/endString before startString => everything after startString
	;                  - startString not found                            => everything before endString
	;                  - Neither found                                    => original string
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
	; RETURNS:        Requested chunk of this string, with some caveats:
	;                  - endString not found/endString before startString => everything after startString
	;                  - startString not found                            => everything before endString
	;                  - Neither found                                    => original string
	;---------
	allBetweenStrings(startString, endString) {
		return this.getBetweenStrings(startString, endString, true)
	}
	
	;---------
	; DESCRIPTION:    Remove a string (if it exists) from the start of this string.
	; PARAMETERS:
	;  toRemove (I,REQ) - The string to remove from the start of this string.
	; RETURNS:        The updated string, after removing toRemove.
	;---------
	removeFromStart(toRemove) {
		if(!this.startsWith(toRemove))
			return this
		
		return this.sub(toRemove.length() + 1)
	}
	;---------
	; DESCRIPTION:    Remove a string (if it exists) from the end of this string.
	; PARAMETERS:
	;  toRemove (I,REQ) - The string to remove from the end of this string.
	; RETURNS:        The updated string, after removing toRemove.
	;---------
	removeFromEnd(toRemove) {
		if(!this.endsWith(toRemove))
			return this
		
		return this.sub(1, this.length() - toRemove.length())
	}
	
	;---------
	; DESCRIPTION:    Add a string to the beginning of this string, but only if that string is not
	;                 already in place.
	; PARAMETERS:
	;  strToAdd (I,REQ) - String to add at the beginning.
	; RETURNS:        Updated string.
	;---------
	prependIfMissing(strToAdd) {
		if(this.sub(1, strToAdd.length()) != strToAdd)
			return strToAdd this
		
		return this
	}
	;---------
	; DESCRIPTION:    Add a string to the end of this string, but only if that string is not already
	;                 in place.
	; PARAMETERS:
	;  strToAdd (I,REQ) - String to add at the end.
	; RETURNS:        Updated string.
	;---------
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
	; DESCRIPTION:    Right-pad the string to the specified length.
	; PARAMETERS:
	;  numChars (I,REQ) - How many characters the final string should be (at minimum).
	;  withChar (I,OPT) - The character to use to do the padding. Defaults to space ( ).
	; RETURNS:        The string, padded out to the specified length.
	;---------
	postPadToLength(numChars, withChar := " ") {
		outStr := this
		
		while(outStr.length() < numChars)
			outStr .= withChar
		
		return outStr
	}
	
	;---------
	; DESCRIPTION:    Wrapper for StrReplace - replace all instances of the provided string, with the replacement text.
	; PARAMETERS:
	;  needle      (I,REQ) - String to replace
	;  replaceWith (I,REQ) - String to replace with
	; RETURNS:        The updated string
	; NOTES:          If you just want to remove all instances of a string, use .remove() instead.
	;---------
	replace(needle, replaceWith) {
		return StrReplace(this, needle, replaceWith) ; Replace all
	}
	;---------
	; DESCRIPTION:    Wrapper for StrReplace - replace one instance of the provided string, with the
	;                 replacement text.
	; PARAMETERS:
	;  needle      (I,REQ) - String to replace
	;  replaceWith (I,REQ) - String to replace with
	; RETURNS:        The updated string
	; NOTES:          If you just want to remove all instances of a string, use .remove() instead.
	;---------
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
	; DESCRIPTION:    Add a new line with the provided text to this string, but don't add an extra
	;                 newline if this is the first line.
	; PARAMETERS:
	;  lineToAdd (I,REQ) - The line to add to the end
	; RETURNS:        The updated string
	;---------
	appendLine(lineToAdd) {
		return this.appendPiece(lineToAdd, "`n")
	}
	
	;---------
	; DESCRIPTION:    Repeat this string a certain number of times.
	;                 For example, "a".repeat(3) will return "aaa".
	; PARAMETERS:
	;  numTimes (I,REQ) - How many times to duplicate the string. 1 returns the same string.
	; RETURNS:        A new string with the given number of copies.
	;---------
	repeat(numTimes) {
		return StringLib.duplicate(this, numTimes)
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
	;                 the start and end of this string, and replace certain odd characters with
	;                 better equivalents.
	; PARAMETERS:
	;  additionalStringsToRemove (I,OPT) - Pass in an array of strings to have them also removed
	;                                      from the start and end of this string.
	; RETURNS:        The updated string
	; NOTES:          Order doesn't matter - we keep cleaning until we don't find any of the
	;                 provided strings at the start or end of the output.
	;---------
	clean(additionalStringsToRemove := "") {
		outStr := this
		
		; Drop leading/trailing odd characters
		stringsToTrim := []
		stringsToTrim.push(Chr(10))         ; Newline (`n)
		stringsToTrim.push(Chr(13))         ; Carriage return (`r)
		stringsToTrim.push(Chr(46))         ; Period (.)
		stringsToTrim.push(Chr(160))        ; Non-breaking space/nbsp ( )
		stringsToTrim.push(Chr(8226)  "`t") ; First level bullet (filled circle) + tab
		stringsToTrim.push(Chr(111)   "`t") ; Second level bullet (letter o)     + tab
		stringsToTrim.push(Chr(61607) "`t") ; Third level bullet (filled square) + tab
		
		For _,string in additionalStringsToRemove
			stringsToTrim.push(string)
		
		outStr := StringLib.dropLeadingTrailing(outStr, stringsToTrim)
		
		; Replace certain characters
		stringsToReplace := {}
		stringsToReplace[Chr(160)] := A_Space ; Non-breaking space/nbsp => Normal space
		
		For toReplace,replaceWith in stringsToReplace
			outStr := outStr.replace(toReplace, replaceWith)
		
		return outStr
	}
	
	;---------
	; DESCRIPTION:    A wrapper for StrSplit() that returns an actual array (not an object).
	; PARAMETERS:
	;  delimiters             (I,OPT) - Delimiter (or array of delimiters) to split on
	;  surroundingCharsToDrop (I,OPT) - Characters to drop from around each piece
	; RETURNS:        Array of split-up string
	;---------
	split(delimiters := "", surroundingCharsToDrop := "") { ; Like StrSplit(), but returns an actual array (not an object)
		obj := StrSplit(this, delimiters, surroundingCharsToDrop)
		return DataLib.convertObjectToArray(obj)
	}
	
	
	; #PRIVATE#
	
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
	; #END#
}
