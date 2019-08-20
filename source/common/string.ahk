; String manipulation functions.

; NOTE: this file needs to be in ANSI encoding, to preserve some odd characters.

global STRING_CASE_MIXED := "MIXED"
global STRING_CASE_UPPER := "UPPER"
global STRING_CASE_LOWER := "LOWER"

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
	
	nums := input.replaceRegEx("[^0-9\+]" , "") ; Strip out spaces and other odd chars.
	nums := nums.replaceRegEx("\+" , "011") ; + becomes country exit code (USA code here)
	
	len := nums.length()
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
	nums := input.replaceRegEx("[^0-9\+]" , "") ; Strip out spaces and other odd chars.
	trimmedNums := nums.sub(-9) ; Last 10 chars only.
	return "(" trimmedNums.sub(1, 3) ") " trimmedNums.sub(4, 3) "-" trimmedNums.sub(7, 4)
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

getCleanHotkeyString(hotkeyString) {
	return hotkeyString.clean(["$", "*", "<", ">", "~"])
}

encodeForURL(textToEncode) {
	currentText := textToEncode
	
	; Temporarily trim off any http/https/etc. (will add back on at end)
	if(RegExMatch(currentText, "^\w+:/{0,2}", prefix))
		currentText := currentText.removeFromStart(prefix)
	
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
