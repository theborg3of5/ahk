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
	
	startsWith(startString) {
		return (this.sub(1, startString.length()) = startString)
	}
	endsWith(endString) {
		return (this.sub(this.length() - endString.length() + 1) = endString)
	}
	
	startsWithAnyOf(needlesAry) {
		For i,needle in needlesAry {
			if(this.startsWith(needle))
				return true
		}
		
		return false
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
	
	beforeString(endString, searchFromEnd := false) {
		endStringPos := this.contains(endString, searchFromEnd)
		if(!endStringPos)
			return this
		
		return this.sub(1, endStringPos - 1)
	}
	afterString(startString, searchFromEnd := false) {
		startStringPos := this.contains(startString, searchFromEnd)
		if(!startStringPos)
			return this
		
		return this.sub(startStringPos + startString.length())
	}
	
	firstBetweenStrings(startString, endString) {
		return this.getBetweenStrings(startString, endString, false)
	}
	allBetweenStrings(startString, endString) {
		return this.getBetweenStrings(startString, endString, true)
	}
	
	removeFromStart(startToRemove) {
		if(!this.startsWith(startToRemove))
			return this
		
		return this.sub(startToRemove.length() + 1)
	}
	removeFromEnd(endingToRemove) {
		if(!this.endsWith(endingToRemove))
			return this
		
		return this.sub(1, this.length() - endingToRemove.length())
	}
	
	prependIfMissing(strToPrepend) {
		if(this.sub(1, strToPrepend.length()) != strToPrepend)
			return strToPrepend this
		
		return this
	}
	appendIfMissing(strToAppend) {
		if(this.sub(- (strToAppend.length() - 1) ) != strToAppend)
			return this strToAppend
		
		return this
	}
	
	firstLine() {
		return this.beforeString("`n")
	}
	
	withoutWhitespace() {
		newText = %this% ; Note using = not :=, to drop whitespace.
		return newText
	}
	
	replace(needle, replaceWith) {
		return StrReplace(this, needle, replaceWith) ; Replace all
	}
	replaceOne(needle, replaceWith) {
		return StrReplace(this, needle, replaceWith, "", 1) ; Replace 1
	}
	replaceRegEx(needleRegEx, replaceWith) {
		return RegExReplace(this, needleRegEx, replaceWith) ; Replace all
	}
	
	remove() {
		return this.replace(needle, "")
	}
	removeRegEx(needleRegEx) {
		return this.replaceRegEx(needleRegEx, "")
	}
	
	appendPiece(pieceToAdd, delimiter := ",") {
		if(pieceToAdd = "")
			return this
		if(this = "")
			return pieceToAdd
		
		return this delimiter pieceToAdd
	}
	
	replaceTags(tagsAry) {
		outputString := this
		
		For tagName, replacement in tagsAry
			outputString := outputString.replaceTag(tagName, replacement)
		
		return outputString
	}

	replaceTag(tagName, replacement) {
		return StrReplace(this, "<" tagName ">", replacement)
	}
	
	; Cleans a hard-coded list of characters out of a (should be single-line) string, including whitespace.
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