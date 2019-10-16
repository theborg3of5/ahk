/* String manipulation functions.
*/

class StringLib {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Escape all instances of a character in the given string, with a specific character.
	; PARAMETERS:
	;  inputString  (I,REQ) - The string to escape the character within.
	;  charToEscape (I,REQ) - The character to escape
	;  escapeChar   (I,OPT) - The escape character to use.
	; RETURNS:        The string with all instances of the character escaped.
	;---------
	escapeCharUsingChar(inputString, charToEscape, escapeChar := "\") {
		replaceString := escapeChar charToEscape
		return inputString.replace(charToEscape, replaceString)
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
	
	;---------
	; DESCRIPTION:    Get the specified number of spaces/dots.
	; PARAMETERS:
	;  numToGet (I,REQ) - How many of the relevant character to return.
	; RETURNS:        As many spaces/dots as requested.
	; SIDE EFFECTS:   
	; NOTES:          
	;---------
	getSpaces(numToGet) {
		return StringLib.duplicate(" ", numToGet)
	}
	getDots(numToGet) {
		return StringLib.duplicate(".", numToGet)
	}
	
	;---------
	; DESCRIPTION:    Duplicate the given string, the given number of times. For example,
	;                 StringLib.duplicate("abc", 3) will produce "abcabcabc".
	; PARAMETERS:
	;  stringToDup (I,REQ) - The string to duplicate
	;  numTimes    (I,REQ) - How many times to duplicate the string. 1 returns the same string.
	; RETURNS:        A string with the given number of duplicates.
	;---------
	duplicate(stringToDup, numTimes) {
		if(stringToDup = "" || numTimes < 1)
			return ""
		
		outStr := ""
		
		Loop, %numTimes%
			outStr .= stringToDup
		
		return outStr
	}
	
	;---------
	; DESCRIPTION:    Encode the given text to be URL-safe.
	; PARAMETERS:
	;  textToEncode (I,REQ) - The text to encode
	; RETURNS:        The encoded text.
	;---------
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
	
	;---------
	; DESCRIPTION:    Decode the given URL-safe text to bring it back to normal.
	; PARAMETERS:
	;  textToDecode (I,REQ) - The text to decode.
	; RETURNS:        The decoded text.
	;---------
	decodeFromURL(textToDecode) {
		outString := textToDecode
		
		while(outString.containsRegEx("i)(?<=%)[\da-f]{1,2}", charCodeInHex)) {
			needle := "%" charCodeInHex
			replaceWith := Chr(hexToInteger(charCodeInHex))
			outString := outString.replace(needle, replaceWith)
		}
		
		return outString
	}
	
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	
}
