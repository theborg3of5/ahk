; String manipulation functions.

; NOTE: this file needs to be in ANSI encoding, to preserve some odd characters.

global STRING_CASE_MIXED := 0
global STRING_CASE_UPPER := 1
global STRING_CASE_LOWER := 2

; Phone number parsing function.
parsePhone(input) {
	nums := RegExReplace(input, "[^0-9\+]" , "") ; Strip out spaces and other odd chars.
	nums := RegExReplace(nums, "\+" , "011") ; + becomes country exit code (USA code here)
	
	len := StringLen(nums)
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
	
	return -1
}

reformatPhone(input) {
	nums := RegExReplace(input, "[^0-9\+]" , "") ; Strip out spaces and other odd chars.
	trimmedNums := SubStr(nums, -9) ; Last 10 chars only.
	return "(" SubStr(trimmedNums, 1, 3) ") " SubStr(trimmedNums, 4, 3) "-" SubStr(trimmedNums, 7, 4)
}

; Gives the height of the given text.
getTextHeight(text) {
	StringReplace, text, text, `n, `n, UseErrorLevel
	lines := ErrorLevel + 1
	
	lineHeight := 17 ; play with this value
	
	height := lines * lineHeight
	; DEBUG.popup(lines, "Lines", lineHeight, "Line height", height, "Height")
	
	return height
}

; Gives the specified number of tabs as a string.
; Give spacesPerTab > 0 to use spaces instead of true tabs.
getTabs(i, spacesPerTab = 0) {
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

; Turns all double quotes (") into double double quotes ("") or more, if second argument given.
escapeDoubleQuotes(s, num = 2) {
	global QUOTES
	
	replString := ""
	while(num > 0) {
		replString .= QUOTES
		num--
	}
	
	StringReplace, s, s, ", %replString%, All		; For syntax highlighting, an ending quote: "
	return s
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

; Given an array of strings, put them all together.
arrayToString(arr, spacesBetween = true, preString = "", postString = "") {
	outStr := ""
	
	For i,a in arr {
		outStr .= preString a postString
		
		if(spacesBetween)
			outStr .= " "
	}
	
	; Take off the last, extraneous space.
	outStr := StringTrimRight(outStr, 1)
	
	return outStr
}

; Wrapper for InStr() that I can remember easier.
stringContains(haystack, needle, caseSensitive = "") {
	return InStr(haystack, needle, caseSensitive)
}

; See if a string contains any of the strings in the array.
stringContainsAnyOf(haystack, needles) {
	firstPos := 0
	For i,n in needles {
		currPos := stringContains(haystack, n)
		if(!currPos)
			Continue
		if(firstPos && (firstPos < currPos) )
			Continue
		
		; DEBUG.popup("Found needle",n, "At position",currPos)
		firstPos := currPos
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
; Also may change the path slightly to make it runnable.
isPath(ByRef text, ByRef type = "") {
	colonSlashPos := stringContains(text, "://")
	protocols := ["http", "ftp"]
	
	if(subStr(text, 1, 8) = "file:///") { ; URL'd filepath.
		text := subStr(text, 9) ; strip off the file:///
		text := StrReplace(text, "%20", A_Space)
		; DEBUG.popup("Updated path", text)
		type := SUBTYPE_FilePath
	} else if(subStr(text, 2, 2) = ":\") { ; Windows filepath
		type := SUBTYPE_FilePath
	} else if(subStr(text, 1, 2) = "\\") { ; Windows network path
		type := SUBTYPE_FilePath
	} else if( colonSlashPos && stringContainsAnyOf(subStr(text, 1, colonSlashPos), protocols) ) { ; URL.
		type := SUBTYPE_URL
	}
	
	; DEBUG.popup("isPath", "Finish", "Type", type)
	return type
}

; Return only the first line of the given string.
getFirstLine(inputString) {
	splitAry := StrSplit(inputString, "`n")
	return splitAry[1]
}

; Cleans a hard-coded list of characters out of a (should be single-line) string, including whitespace.
cleanupText(text, additionalStringsToRemove = "") {
	charCodesToRemove := []
	charCodesToRemove[1] := [13,10]   ; Newline
	charCodesToRemove[1] := [32]      ; Space
	charCodesToRemove[2] := [8226,9]  ; First level bullet (filled circle) + tab
	charCodesToRemove[3] := [111,9]   ; Second level bullet (empty circle) + tab
	charCodesToRemove[4] := [61607,9] ; Third level bullet (filled square) + tab
	
	; Transform the codes above so we can check whether it's in the string.
	charsToRemove := []
	For i,s in charCodesToRemove {
		charsToRemove[i] := ""
		For j,c in s {
			newChar := Transform("Chr", c)
			charsToRemove[i] .= newChar
		}
	}
	For i,str in additionalStringsToRemove {
		charsToRemove.push(str)
	}
	; DEBUG.popup("Text",text, "Chars to remove",charsToRemove)
	
	while(!isClean) {
		isClean := true
		
		; Leading/trailing whitespace
		temp := dropWhitespace(text)
		if(temp != text) {
			text := temp
			isClean := false
		}
		
		; Odd character checks.
		index := containsAnyOf(text, charsToRemove, CONTAINS_BEG) ; Beginning of string
		if(index) {
			needle := charsToRemove[index]
			text := StrReplace(text, needle, "", , 1) ; Get only the first replaceable one.
			isClean := false
		}
		index := containsAnyOf(text, charsToRemove, CONTAINS_END) ; End of string
		if(index) {
			needle := escapeRegExChars(charsToRemove[index])
			text := RegExReplace(text, needle, "", , 1, strlen(text) - strlen(needle)) ; Get only the last replaceable one.
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

replaceTags(inputString, tagNamesAry) {
	outputString := inputString
	
	For tagName, replacement in tagNamesAry
		outputString := replaceTag(outputString, tagName, replacement)
	
	return outputString
}

replaceTag(inputString, tagName, replacement) {
	return StrReplace(inputString, "<" tagName ">", replacement)
}

removeStringFromEnd(inputString, endingToRemove) {
	inputLen  := strLen(inputString)
	endingLen := strLen(endingToRemove)
	
	if(subStr(inputString, inputLen - endingLen + 1) = endingToRemove)
		return subStr(inputString, 1, inputLen - endingLen)
	else
		return inputString
}

appendCharIfMissing(inputString, charToAppend) {
	if(SubStr(inputString, 0) != charToAppend)
		inputString .= charToAppend
	
	return inputString
}
