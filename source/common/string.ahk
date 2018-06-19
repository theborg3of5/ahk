; String manipulation functions.

; NOTE: this file needs to be in ANSI encoding, to preserve some odd characters.

global STRING_CASE_MIXED := 0
global STRING_CASE_UPPER := 1
global STRING_CASE_LOWER := 2

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
	; DEBUG.popup(input, "Input", nums, "Nums", len, "Len")
	
	if(len = 4)  ; Old extension.
		return "7" nums
	if(len = 5)  ; Extension.
		return nums
	if(len = 7)  ; Normal
		return nums
	if(len = 10) ; Normal with area code.
		return "81" nums
	if(len = 11) ; Normal with area code plus 1 at beginning.
		return "8" nums
	if(len = 12) ; Already has everything needs, in theory.
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
	outStr := ""
	tabStr := spacesPerTab > 0 ? getSpaces(spacesPerTab) : "`t"
	
	Loop, %i%
		outStr .= tabStr
	
	return outStr
}

; Gives the specified number of spaces in a string.
getSpaces(i) {
	outStr := ""
	
	Loop, %i%
		outStr .= " "
	
	return outStr
}

; Gives the specified number of newlines as a string.
getNewLines(i) {
	outStr := ""
	
	Loop, %i%
		outStr .= "`n"
	
	return outStr
}

getDots(i) {
	outStr := ""
	
	Loop, %i%
		outStr .= "."
	
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

wrapInQuotes(inputString) {
	global QUOTES
	
	return QUOTES escapeDoubleQuotes(inputString) QUOTES
}

; Wraps each line of the array in quotes, turning any quotes already there into double double quotes.
quoteWrapArrayDouble(arr) {
	global QUOTES
	
	outArr := []
	
	For i,a in arr {
		outArr.insert(wrapInQuotes(a))
	}
	
	return outArr
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

; Wrapper for InStr() that I can remember easier.
stringContains(haystack, needle, caseSensitive := "") {
	return InStr(haystack, needle, caseSensitive)
}

; See if a string contains any of the strings in the array.
stringContainsAnyOf(haystack, needles, ByRef matchedNeedle = "") {
	firstPos := 0
	For i,n in needles {
		currPos := stringContains(haystack, n)
		if(!currPos)
			Continue
		if(firstPos && (firstPos < currPos) )
			Continue
		
		; DEBUG.popup("Found needle",n, "At position",currPos)
		firstPos := currPos
		matchedNeedle := n
	}
	
	return firstPos
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
	else if(colonSlashPos && stringContainsAnyOf(subStr(text, 1, colonSlashPos), protocols) ) ; URL.
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
		index := containsAnyOf(text, stringsToRemove, CONTAINS_BEG) ; Beginning of string
		if(index) {
			needle := stringsToRemove[index]
			text := StrReplace(text, needle, "", , 1) ; Get only the first replaceable one.
			isClean := false
		}
		index := containsAnyOf(text, stringsToRemove, CONTAINS_END) ; End of string
		if(index) {
			needle := escapeRegExChars(stringsToRemove[index])
			text := RegExReplace(text, needle, "", , 1, strLen(text) - strLen(needle)) ; Get only the last replaceable one.
			isClean := false
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

stringStartsWith(inputString, startString) {
	return (subStr(inputString, 1, strLen(startString)) = startString)
}
stringEndsWith(inputString, endString) {
	return (subStr(inputString, strLen(inputString) - strLen(endString) + 1) = endString)
}

; These are very simple - only work on the first instance of the character(s) in question.
getStringBeforeStr(inputString, endString) {
	endStringPos := stringContains(inputString, endString)
	if(!endStringPos)
		return inputString
	
	return subStr(inputString, 1, endStringPos - 1)
}
getStringAfterStr(inputString, startString) {
	startStringPos := stringContains(inputString, startString)
	if(!startStringPos)
		return inputString
	
	return subStr(inputString, startStringPos + strLen(startString))
}
getStringBetweenStr(inputString, startString, endString) {
	outString := getStringBeforeStr(inputString, endString)
	return getStringAfterStr(outString, startString)
}

appendCharIfMissing(inputString, charToAppend) {
	if(subStr(inputString, 0) != charToAppend)
		inputString .= charToAppend
	
	return inputString
}
