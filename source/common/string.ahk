; String manipulation functions.

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
	return inputString.replace(charToEscape, replaceString)
}
escapeCharUsingRepeat(inputString, charToEscape, repeatCount := 1) {
	replaceString := multiplyString(charToEscape, repeatCount + 1) ; Replace with repeatCount+1 instances of character
	return inputString.replace(charToEscape, replaceString)
}

escapeForRunURL(stringToEscape) {
	encodedString := encodeForURL(stringToEscape)
	return escapeCharUsingRepeat(encodedString, """", 2) ; Escape double-quotes twice - extra to get us past the windows run command stripping them out.
}

getCleanHotkeyString(hotkeyString) {
	return hotkeyString.clean(["$", "*", "<", ">", "~"])
}

encodeForURL(textToEncode) {
	currentText := textToEncode
	
	; Temporarily trim off any http/https/etc. (will add back on at end)
	if(currentText.containsRegEx("^\w+:/{0,2}", prefix))
		currentText := currentText.removeFromStart(prefix)
	
	; First replace any percents with the equivalent (since doing it later would also pick up anything else we've converted)
	needle := "%"
	replaceWith := "%" numToHex(Asc("%"))
	currentText := currentText.replace(needle, replaceWith)
	
	; Replace any other iffy characters with their encoded equivalents
	while(currentText.containsRegEx("i)[^\w\.~%]", charToReplace)) {
		replaceWith := "%" numToHex(Asc(charToReplace))
		currentText := currentText.replace(charToReplace, replaceWith)
	}
	
	return prefix currentText
}

decodeFromURL(textToDecode) {
	outString := textToDecode
	
	while(outString.containsRegEx("i)(?<=%)[\da-f]{1,2}", charCodeInHex)) {
		needle := "%" charCodeInHex
		replaceWith := Chr(hexToInteger(charCodeInHex))
		outString := outString.replace(needle, replaceWith)
	}
	
	return outString
}
