; String manipulation functions.

; NOTE: this file needs to be in ANSI encoding, to preserve some odd characters.

global STRING_CASE_MIXED := 0
global STRING_CASE_UPPER := 1
global STRING_CASE_LOWER := 2

global CONTAINS_ANY   := 1
global CONTAINS_BEG   := 2
global CONTAINS_END   := 3
global CONTAINS_EXACT := 4

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

; Turns all double quotes (") into double double quotes ("") or more, if second argument given.
escapeDoubleQuotes(s, num := 2) {
	global QUOTES
	
	replString := ""
	while(num > 0) {
		replString .= QUOTES
		num--
	}
	
	return StrReplace(s, """", replString, "All")
}

escapeAmpersands(textToEscape) {
	escapedString := ""
	
	Loop, Parse, textToEscape
	{
		escapedString .= A_LoopField
		if(A_LoopField = "&")
			escapedString .= "&"
	}
	
	return escapedString
}

; Doubles every backslash in the given string.
doubleBackslashes(in) {
	out := ""
	
	Loop, Parse, in
	{
		out .= A_LoopField
		if(A_LoopField = "\")
			out .= "\"
	}
	
	return out
}

escapeRegExChars(inputString) {
	outputString := ""
	Loop, Parse, inputString
	{
		if(stringContains("\.*?+[{|()^$", A_LoopField))
			outputString .= "\"
		outputString .= A_LoopField
	}
	
	return outputString
}

; Wrapper for InStr() that I can remember easier. Slightly different parameters as well.
stringContains(haystack, needle, searchFromEnd := false) {
	if(searchFromEnd)
		return InStr(haystack, needle, , 0)
	else
		return InStr(haystack, needle)
}

stringMatches(haystack, el, method := 1) { ; method := CONTAINS_ANY
	if(method = CONTAINS_ANY)
		return stringContains(haystack, el)
	
	else if(method = CONTAINS_BEG)
		return stringStartsWith(haystack, el)
	
	else if(method = CONTAINS_END)
		return stringEndsWith(haystack, el)
	
	else if(method = CONTAINS_EXACT)
		return (haystack = el)
	
	DEBUG.popup("Unsupported match method",method)
	return ""
}

; Reverse array contains function - checks if any of array strings are in given string, with some special ways of searching (matches start, matches end, exact match, partial match anywhere)
stringMatchesAnyOf(haystack, needles, method := 1, ByRef matchedIndex := "") { ; method = CONTAINS_ANY
	; DEBUG.popup("Haystack",haystack, "Needles",needles, "Method",method)
	For i, el in needles {
		matchedPos := stringMatches(haystack, el, method)
		if(matchedPos) {
			matchedIndex := i
			return matchedPos
		}
	}
	
	return ""
}

stringStartsWith(inputString, startString) {
	return (subStr(inputString, 1, strLen(startString)) = startString)
}
stringEndsWith(inputString, endString) {
	return (subStr(inputString, strLen(inputString) - strLen(endString) + 1) = endString)
}


getStringBeforeStr(inputString, endString, searchFromEnd := false) {
	endStringPos := stringContains(inputString, endString, searchFromEnd)
	if(!endStringPos)
		return inputString
	
	return subStr(inputString, 1, endStringPos - 1)
}
getStringAfterStr(inputString, startString, searchFromEnd := false) {
	startStringPos := stringContains(inputString, startString, searchFromEnd)
	if(!startStringPos)
		return inputString
	
	return subStr(inputString, startStringPos + strLen(startString))
}
getStringBetweenStr(inputString, startString, endString, beGreedy := false) {
	outString := getStringBeforeStr(inputString, endString, beGreedy)
	return getStringAfterStr(outString, startString)
}
getStringBetweenStrGreedy(inputString, startString, endString) {
	return getStringBetweenStr(inputString, startString, endString, true)
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
isCase(string, case = 0) { ; case = STRING_CASE_MIXED
	if(case = STRING_CASE_MIXED) {
		return true
	} else if(case = STRING_CASE_UPPER) {
		return (string = StringUpper(string))
	} else if(case = STRING_CASE_LOWER) {
		return (string = StringLower(string))
	}
	
	return false
}

; Test whether something is a filepath or a URL.
getPathType(text) {
	protocols := ["http", "ftp"]
	
	text := cleanupText(text, [""""]) ; Make sure there's no quotes or other oddities surrounding the path
	colonSlashPos := stringContains(text, "://")
	
	if(subStr(text, 1, 8) = "file:///") ; URL'd filepath.
		type := SUBTYPE_FilePath
	else if(subStr(text, 2, 2) = ":\")  ; Windows filepath
		type := SUBTYPE_FilePath
	else if(subStr(text, 1, 2) = "\\")  ; Windows network path
		type := SUBTYPE_FilePath
	else if(colonSlashPos && stringMatchesAnyOf(subStr(text, 1, colonSlashPos), protocols) ) ; URL.
		type := SUBTYPE_URL
	
	; DEBUG.popup("getPathType", "Finish", "Type", type, "Cleaned up text",text)
	return type
}

; Return only the first line of the given string.
getFirstLine(inputString) {
	splitAry := StrSplit(inputString, "`n")
	return splitAry[1]
}

; Cleans a hard-coded list of characters out of a (should be single-line) string, including whitespace.
cleanupText(text, additionalStringsToRemove := "") {
	charCodesToRemove := []
	charCodesToRemove[1] := [13,10]   ; Newline
	charCodesToRemove[1] := [32]      ; Space
	charCodesToRemove[2] := [8226,9]  ; First level bullet (filled circle) + tab
	charCodesToRemove[3] := [111,9]   ; Second level bullet (empty circle) + tab
	charCodesToRemove[4] := [61607,9] ; Third level bullet (filled square) + tab
	
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

getCleanHotkeyString(hotkeyString) {
	return cleanupText(hotkeyString, ["$", "*", "<", ">", "~"])
}

replaceTags(inputString, tagNamesAry) {
	outputString := inputString
	
	For tagName, replacement in tagNamesAry
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
