; String manipulation functions.

; NOTE: this file needs to be in ANSI encoding, to preserve some odd characters.

global STRING_CASE_MIXED := "MIXED"
global STRING_CASE_UPPER := "UPPER"
global STRING_CASE_LOWER := "LOWER"

global CONTAINS_ANY   := "ANY"
global CONTAINS_START := "START"
global CONTAINS_END   := "END"
global CONTAINS_EXACT := "EXACT"

isValidPhoneNumber(formattedNum) {
	rawNum := parsePhone(formattedNum) ; Returns "" if it's not a valid number
	if(rawNum = "")
		return false
	else
		return true
}

; Phone number parsing function.
parsePhone(input) {
	; Special case - hang up
	if(input = "HANGUP")
		return input
	
	nums := RegExReplace(input, "[^0-9\+]" , "") ; Strip out spaces and other odd chars.
	nums := RegExReplace(nums, "\+" , "011") ; + becomes country exit code (USA code here)
	
	len := strLen(nums)
	; DEBUG.popup("Input",input, "Nums",nums, "Len",len)
	
	if(len = 4)  ; Old extension.
		return "7" nums
	if(len = 5)  ; Extension.
		return nums
	if(len = 7)  ; Normal
		return nums
	if(len = 10) ; Normal with area code.
		return "81" nums
	if(len = 11) ; Normal with 1 + area code at beginning.
		return "8" nums
	if(len = 12) ; Normal with 8 + 1 + area code at beginning.
		return nums
	if(len = 14) ; International number with exit code, just needs 8 to get out.
		return "8" nums
	if(len = 15) ; International number with 2-digit exit code and 8, should be set.
		return nums
	if(len = 16) ; International number with 3-digit exit code and 8, should be set.
		return nums
	
	return ""
}

reformatPhone(input) {
	nums := RegExReplace(input, "[^0-9\+]" , "") ; Strip out spaces and other odd chars.
	trimmedNums := subStr(nums, -9) ; Last 10 chars only.
	return "(" subStr(trimmedNums, 1, 3) ") " subStr(trimmedNums, 4, 3) "-" subStr(trimmedNums, 7, 4)
}

; Gives the specified number of tabs as a string.
; Give spacesPerTab > 0 to use spaces instead of true tabs.
getTabs(i, spacesPerTab := 0) {
	tabStr := spacesPerTab > 0 ? getSpaces(spacesPerTab) : "`t"
	return multiplyString(tabStr, i)
}
getSpaces(i) {
	return multiplyString(" ", i)
}
getNewLines(i) {
	return multiplyString("`n", i)
}
getDots(i) {
	return multiplyString(".", i)
}

multiplyString(inString, numTimes) {
	if(inString = "" || numTimes < 1)
		return ""
	
	outStr := ""
	
	Loop, %numTimes%
		outStr .= inString
	
	return outStr
}
	
;---------
; DESCRIPTION:    Determine how many spaces there are at the beginning of a string.
; PARAMETERS:
;  line (I,REQ) - The line to count spaces for.
; RETURNS:        The number of spaces at the beginning of the line.
;---------
countLeadingSpaces(line) {
	numSpaces := 0
	
	Loop, Parse, line
	{
		if(A_LoopField = A_Space)
			numSpaces++
		else
			Break
	}
	
	return numSpaces
}

escapeCharUsingChar(inputString, charToEscape, escapeChar := "\") {
	replaceString := escapeChar charToEscape
	return StrReplace(inputString, charToEscape, replaceString, "All")
}
escapeCharUsingRepeat(inputString, charToEscape, repeatCount := 1) {
	replaceString := multiplyString(charToEscape, repeatCount + 1) ; Replace with repeatCount+1 instances of character
	return StrReplace(inputString, charToEscape, replaceString, "All")
}

escapeForRunURL(stringToEscape) {
	encodedString := encodeForURL(stringToEscape)
	return escapeCharUsingRepeat(encodedString, DOUBLE_QUOTE, 2) ; Escape quotes twice - extra to get us past the windows run command stripping them out.
}

; Wrapper for InStr() that I can remember easier. Slightly different parameters as well.
stringContains(haystack, needle, fromLastInstance := false) {
	if(fromLastInstance)
		return InStr(haystack, needle, , 0)
	else
		return InStr(haystack, needle)
}

stringMatches(haystack, el, method := "ANY") { ; method := CONTAINS_ANY
	if(method = CONTAINS_ANY)
		return stringContains(haystack, el)
	
	else if(method = CONTAINS_START)
		return stringStartsWith(haystack, el)
	
	else if(method = CONTAINS_END)
		return stringEndsWith(haystack, el)
	
	else if(method = CONTAINS_EXACT)
		return (haystack = el)
	
	DEBUG.popup("Unsupported match method",method)
	return ""
}

; Reverse array contains function - checks if any of array strings are in given string, with some special ways of searching (matches start, matches end, exact match, partial match anywhere)
; Returns the position of the earliest match in the string (the first occurrence of any needle)
stringMatchesAnyOf(haystack, needlesAry, method := "ANY", ByRef matchedNeedle := "") { ; method = CONTAINS_ANY
	earliestMatchedPos := 0
	
	For i,needle in needlesAry {
		matchedPos := stringMatches(haystack, needle, method)
		if(matchedPos) {
			if(!earliestMatchedPos || (matchedPos < earliestMatchedPos)) {
				earliestMatchedPos := matchedPos
				matchedNeedle := needle
			}
		}
	}
	
	; DEBUG.popup("stringMatchesAnyOf","Finish", "haystack",haystack, "needlesAry",needlesAry, "method",method, "matchedIndex",matchedIndex, "earliestMatchedPos",earliestMatchedPos)
	return earliestMatchedPos
}

stringStartsWith(inputString, startString) {
	return (subStr(inputString, 1, strLen(startString)) = startString)
}
stringEndsWith(inputString, endString) {
	return (subStr(inputString, strLen(inputString) - strLen(endString) + 1) = endString)
}


getStringBeforeStr(inputString, endString, fromLastInstance := false) {
	endStringPos := stringContains(inputString, endString, fromLastInstance)
	if(!endStringPos)
		return inputString
	
	return subStr(inputString, 1, endStringPos - 1)
}
getStringAfterStr(inputString, startString, fromLastInstance := false) {
	startStringPos := stringContains(inputString, startString, fromLastInstance)
	if(!startStringPos)
		return inputString
	
	return subStr(inputString, startStringPos + strLen(startString))
}
getFirstStringBetweenStr(inputString, startString, endString, upToLastEndString := false) {
	; Trim off everything before (and including) the first instance of the startString
	outString := getStringAfterStr(inputString, startString)
	
	; Trim off everything before (and including) the remaining instance (first or last depending on upToLastEndString) of the endString
	return getStringBeforeStr(outString, endString, upToLastEndString)
}
getFullStringBetweenStr(inputString, startString, endString) {
	return getFirstStringBetweenStr(inputString, startString, endString, true)
}

; Wrapper function for whether a string is alphabetic.
isAlpha(str) {
	return IfIs(str, "Alpha")
}

; Wrapper function for whether a string is numeric.
isNum(str) {
	return IfIs(str, "Number")
}

; Wrapper function for whether a string is alphanumeric.
isAlphaNum(str) {
	return IfIs(str, "AlNum")
}

; Test for casing in a string.
isCase(string, case := "MIXED") { ; case = STRING_CASE_MIXED
	if(case = STRING_CASE_MIXED) {
		return true
	} else if(case = STRING_CASE_UPPER) {
		return (string = StringUpper(string))
	} else if(case = STRING_CASE_LOWER) {
		return (string = StringLower(string))
	}
	
	return false
}

; Return only the first line of the given string.
getFirstLine(inputString) {
	splitAry := StrSplit(inputString, "`n")
	return splitAry[1]
}

; Cleans a hard-coded list of characters out of a (should be single-line) string, including whitespace.
cleanupText(text, additionalStringsToRemove := "") {
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
	; DEBUG.popup("Text",text, "Chars to remove",stringsToRemove)
	
	while(!isClean) {
		isClean := true
		
		; Leading/trailing whitespace
		temp := dropWhitespace(text)
		if(temp != text) {
			text := temp
			isClean := false
		}
		
		; Odd character checks.
		For i,removeString in stringsToRemove {
			if(stringStartsWith(text, removeString)) {
				text := removeStringFromStart(text, removeString)
				isClean := false
			}
			if(stringEndsWith(text, removeString)) {
				text := removeStringFromEnd(text, removeString)
				isClean := false
			}
		}
		
		; DEBUG.popup("Is clean", isClean, "Current text", text)
	}
	
	return text
}

; Drop any leading/trailing whitespace.
dropWhitespace(text) {
	newText = %text% ; Note using = not :=, to drop whitespace.
	return newText
}

appendLine(baseText, textToAdd) {
	updatedString := ""
	updatedString := baseText
	
	if(updatedString != "")
		updatedString .= "`n"
	updatedString .= textToAdd
	
	return updatedString
}

appendPieceToString(baseText, delimiter, pieceToAdd) {
	if(pieceToAdd = "")
		return baseText
	if(baseText = "")
		return pieceToAdd
	
	return baseText delimiter pieceToAdd
}

getCleanHotkeyString(hotkeyString) {
	return cleanupText(hotkeyString, ["$", "*", "<", ">", "~"])
}

replaceTags(inputString, tagsAry) {
	outputString := inputString
	
	For tagName, replacement in tagsAry
		outputString := replaceTag(outputString, tagName, replacement)
	
	return outputString
}

replaceTag(inputString, tagName, replacement) {
	return StrReplace(inputString, "<" tagName ">", replacement)
}

removeStringFromStart(inputString, startToRemove) {
	if(!stringStartsWith(inputString, startToRemove))
		return inputString
	
	return subStr(inputString, strLen(startToRemove) + 1)
}
removeStringFromEnd(inputString, endingToRemove) {
	if(!stringEndsWith(inputString, endingToRemove))
		return inputString
	
	return subStr(inputString, 1, strLen(inputString) - strLen(endingToRemove))
}

appendCharIfMissing(inputString, charToAppend) {
	if(subStr(inputString, 0) != charToAppend)
		inputString .= charToAppend
	
	return inputString
}

encodeForURL(textToEncode) {
	currentText := textToEncode
	
	; Temporarily trim off any http/https/etc. (will add back on at end)
	if(RegExMatch(currentText, "^\w+:/{0,2}", prefix))
		currentText := removeStringFromStart(currentText, prefix)
	
	; First replace any percents with the equivalent (since doing it later would also pick up anything else we've converted)
	needle := "%"
	replaceWith := "%" numToHex(Asc("%"))
	StringReplace, currentText, currentText, % needle, % replaceWith, All
	
	; Replace any other iffy characters with their encoded equivalents
	while(RegExMatch(currentText, "i)[^\w\.~%]", charToReplace)) {
		replaceWith := "%" numToHex(Asc(charToReplace))
		StringReplace, currentText, currentText, % charToReplace, % replaceWith, All
	}
	
	return prefix currentText
}

decodeFromURL(textToDecode) {
	outString := textToDecode
	
	while(RegExMatch(outString, "i)(?<=%)[\da-f]{1,2}", charCodeInHex)) {
		needle := "%" charCodeInHex
		replaceWith := Chr(hexToInteger(charCodeInHex))
		StringReplace, outString, outString, % needle, % replaceWith, All
	}
	
	return outString
}