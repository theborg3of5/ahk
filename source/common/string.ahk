; String manipulation functions.

; NOTE: this file needs to be in ANSI encoding, to preseve some odd characters.

global STRING_CASE_MIXED := 0
global STRING_CASE_UPPER := 1
global STRING_CASE_LOWER := 2

; Phone number parsing function.
parsePhone(input) {
	nums := RegExReplace(input, "[^0-9\+]" , "") ; Strip out spaces and other odd chars.
	nums := RegExReplace(nums, "\+" , "011") ; + becomes country exit code (USA code here)
	
	StringLen, len, nums
	; DEBUG.popup(input, "Input", nums, "Nums", len, "Len")
	
	if(len = 4) ; Old extension.
		return "7" nums
	if(len = 5) ; Extension.
		return nums
	if(len = 7) ; Normal
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
	replString := ""
	while(num > 0) {
		replString .= """"
		num--
	}
	
	StringReplace, s, s, ", %replString%, All		; For syntax! "
	return s
}

; Wraps each line of the array in quotes, turning any quotes already there into double double quotes.
quoteWrapArrayDouble(arr) {
	outArr := []
	
	For i,a in arr {
		outArr.insert("""" escapeDoubleQuotes(a) """")
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

; Given an array of strings, put them all together.
arrayToString(arr, spacesBetween = true, preString = "", postString = "") {
	outStr := ""
	
	For i,a in arr {
		outStr .= preString a postString
		
		if(spacesBetween)
			outStr .= " "
	}
	
	; Take off the last, extraneous space.
	StringTrimRight, outStr, outStr, 1
	
	return outStr
}

; Wrapper for InStr() that I can remember easier.
stringContains(haystack, needle, caseSensitive = "") {
	return InStr(haystack, needle, caseSensitive)
}

; See if a string contains any of the strings in the array.
stringContainsAnyOf(haystack, needles) {
	For i,n in needles {
		if(stringContains(haystack, n))
			return true
	}
	
	return false
}

; Wrapper function for "If var Is Alpha" statements.
isAlpha(str) {
	If str Is Alpha
		return true
	return false
}

; Wrapper function for "If var Is Number" statements.
isNum(num) {
	If num Is Number
		return true
	return false
}

isAlphaNum(str) {
	If str Is AlNum
		return true
	return false
}

; Test for casing in a string.
isCase(string, case = 0) { ; case = STRING_CASE_MIXED
	if(case = STRING_CASE_MIXED) {
		return true
	} else if(case = STRING_CASE_UPPER) {
		StringUpper, upper, string
		return (string = upper)
	} else if(case = STRING_CASE_LOWER) {
		StringLower, lower, string
		return (string = lower)
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
		text := RegExReplace(text, "%20", A_Space)
		; DEBUG.popup("Trimmed path", text)
		type := SUBTYPE_FILEPATH
	} else if(subStr(text, 2, 2) = ":\") { ; Windows filepath
		type := SUBTYPE_FILEPATH
	} else if(subStr(text, 1, 2) = "\\") { ; Windows network path
		type := SUBTYPE_FILEPATH
	} else if(colonSlashPos && stringContainsAnyOf(subStr(text, 1, colonSlashPos), protocols) ) { ; URL.
		type := SUBTYPE_URL
	}
	
	; DEBUG.popup("isPath", "Finish", "Type", type)
	return type
}

; Strips the dollar sign/asterisk off of the front of hotkeys if it's there.
stripHotkeyString(hotkeyString, leaveDollarSign = 0, leaveStar = 0) {
	if(!leaveDollarSign && InStr(hotkeyString, "$")) {
		StringReplace, returnKey, hotkeyString, $
		return returnKey
	} else if(!leaveStar && InStr(hotkeyString, "*")) {
		StringReplace, returnKey, hotkeyString, *
		return returnKey
	} else {
		return A_ThisHotkey
	}
}

; Reduces a given filepath down by the number of levels given, from right to left.
reduceFilepath(path, levelsDown) {
	outPath := ""
	splitPath := StrSplit(path, "\") ; Start with this exact file (commonVariables.ahk).
	pathSize := splitPath.MaxIndex()
	For i,p in splitPath {
		if(i = (pathSize - levelsDown + 1))
			Break
		outPath .= p "\"
	}
	; DEBUG.popup("Split Path", splitPath, "Size", pathSize, "Final path", outPath)
	
	return outPath
}

; Show a popup that takes what math on the given number.
mathPopup(inputNum, operations = "") {
	if(!isNum(inputNum))
		return ""
	
	if(!operations)
		InputBox, operations, Do Math, Math operations to make on number:
	
	result := Eval(inputNum operations)
	
	; DEBUG.popup("mathPopup", "Got ops", "InputNum", inputNum, "Ops", operations, "Result", result)
	return result
}

; Cleans a hard-coded list of characters out of a (should be single-line) string, including whitespace.
cleanupText(text) {
	charCodesToRemove := []
	charCodesToRemove[1] := [13,10]    ; Newline
	charCodesToRemove[2] := [8226,9]   ; First level bullet (filled circle) + tab
	charCodesToRemove[3] := [111,9]    ; Second level bullet (empty circle) + tab
	charCodesToRemove[4] := [61607,9]  ; Third level bullet (filled square) + tab
	
	; Transform the codes above so we can check whether it's in the string.
	charsToRemove := []
	For i,s in charCodesToRemove {
		charsToRemove[i] := ""
		For j,c in s {
			Transform, newChar, Chr, %c%
			charsToRemove[i] .= newChar
		}
	}
	
	while(!isClean) {
		isClean := true
		
		; Drop any leading/trailing whitespace. (Note using = not :=)
		temp = %text%
		if(temp != text) {
			text := temp
			isClean := false
		}
		
		; Odd character checks.
		index := containsAnyOf(text, charsToRemove, CONTAINS_BEG) ; Beginning of string
		if(index) {
			needle := charsToRemove[index]
			text := RegExReplace(text, needle, "", "", 1) ; Get only the first replaceable one.
			isClean := false
		}
		index := containsAnyOf(text, charsToRemove, CONTAINS_END) ; End of string
		if(index) {
			needle := charsToRemove[index]
			text := RegExReplace(text, needle, "", "", 1, strlen(text) - strlen(needle)) ; Get only the last replaceable one.
			isClean := false
		}
		
		; DEBUG.popup("Is clean", isClean, "Current text", text)
	}
	
	return text
}

