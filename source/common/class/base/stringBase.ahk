/*
	Base class for strings to extend (technically for their base to extend), so we can add these functions directly to strings.
	
	Note: this does not allow you to manipulate the string itself - all functions return the result of the operation.
		For example: appendPiece() returns the new string, so you must capture the return value instead of just calling it (i.e. str := str.appendPiece() instead of just str.appendPiece())
	
	Example usage:
		str := "abcd"
		result := str.contains("b") ; result = 2
*/

/*
	Do
		Functions to replace and remove
			replaceTags						=> .replaceTags
			replaceTag						=> .replaceTag
			prePadStringToLength			=> .prePadToLength
		Functions to remove (already replaced)
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
	
	; Reverse array contains function - checks if any of array strings are in given string.
	; Returns the position of the earliest match in the string (the first occurrence of any needle)
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
		
		; DEBUG.popup("StringBase.containsAnyOf","Finish", "this",this, "needlesAry",needlesAry, "matchedIndex",matchedIndex, "earliestMatchedPos",earliestMatchedPos)
		return earliestMatchedPos
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
	
	startsWithAnyOf(needlesAry) {
		For i,needle in needlesAry {
			if(this.startsWith(needle))
				return true
		}
		
		return false
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
	
	prePadToLength(numChars, withChar := " ") {
		outStr := this
		
		while(outStr.length() < numChars)
			outStr := withChar outStr
		
		return outStr
	}
	
	firstLine() {
		return this.beforeString("`n")
	}
	
	withoutWhitespace() {
		newText = %this% ; Note using = not :=, to drop whitespace.
		return newText
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
			outputString := replaceTag(outputString, tagName, replacement)
		
		return outputString
	}

	replaceTag(tagName, replacement) {
		return StrReplace(this, "<" tagName ">", replacement)
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
		outStr := this.afterString(startString)
		
		; Trim off everything before (and including) the remaining instance (first or last depending on upToLastEndString) of the endString
		return outStr.beforeString(endString, upToLastEndString)
	}
}