; String manipulation functions.

class StringLib {
	; #PUBLIC#
	
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
	; DESCRIPTION:    Indent the entire given block of text by adding the given number of spaces to
	;                 the start of each line.
	; PARAMETERS:
	;  textBlock  (I,REQ) - The block of text to indent. May have either `r`n or `n-style newlines.
	;  numSpaces  (I,REQ) - The number of spaces to indent by.
	; RETURNS:        The indented block
	;---------
	indentBlock(textBlock, numSpaces) {
		indentText := StringLib.getSpaces(numSpaces)
		newBlock := indentText textBlock ; Make sure to indent the first row, too
		
		return newBlock.replace("`n", "`n" indentText)
	}
	
	;---------
	; DESCRIPTION:    Get the specified number of spaces.
	; PARAMETERS:
	;  numToGet (I,REQ) - How many spaces to return.
	; RETURNS:        As many spaces as requested.
	;---------
	getSpaces(numToGet) {
		return StringLib.duplicate(A_Space, numToGet)
	}
	;---------
	; DESCRIPTION:    Get the specified number of tabs.
	; PARAMETERS:
	;  numToGet (I,REQ) - How many tabs to return.
	; RETURNS:        As many tabs as requested.
	;---------
	getTabs(numToGet) {
		return StringLib.duplicate(A_Tab, numToGet)
	}
	;---------
	; DESCRIPTION:    Get the specified number of newlines.
	; PARAMETERS:
	;  numToGet (I,REQ) - How many newlines to return.
	; RETURNS:        As many newlines as requested.
	;---------
	getNewlines(numToGet) {
		return StringLib.duplicate("`n", numToGet)
	}
	;---------
	; DESCRIPTION:    Get the specified number of dots.
	; PARAMETERS:
	;  numToGet (I,REQ) - How many dots to return.
	; RETURNS:        As many dots as requested.
	;---------
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
	; DESCRIPTION:    Pad both sides of the given text to get a string that's the given width.
	; PARAMETERS:
	;  textToCenter (I,REQ) - The text to center
	;  goalLength   (I,REQ) - The number of characters long that the resulting string should be.
	;  padChar      (I,OPT) - The character to use as padding. Defaults to space.
	; RETURNS:        Padded string
	; NOTES:          If the difference between the length of the text and goal is odd, we'll bias
	;                 to the left (1 extra padding char on the right).
	;---------
	padCenter(textToCenter, goalLength, padChar := " ") {
		leftoverWidth := goalLength - textToCenter.length()
		leftSpace := leftoverWidth // 2
		rightSpace := leftoverWidth - leftSpace ; Bias left if uneven leftover space
		
		return StringLib.duplicate(padChar, leftSpace) textToCenter StringLib.duplicate(padChar, rightSpace)
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
		replaceWith := "%" DataLib.numToHex(Asc("%"))
		currentText := currentText.replace(needle, replaceWith)
		
		; Replace any other iffy characters with their encoded equivalents
		while(currentText.containsRegEx("i)[^\w\.~%]", charToReplace)) {
			replaceWith := "%" DataLib.numToHex(Asc(charToReplace))
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
			replaceWith := Chr(DataLib.hexToInteger(charCodeInHex))
			outString := outString.replace(needle, replaceWith)
		}
		
		return outString
	}
	
	;---------
	; DESCRIPTION:    Find the "overlap" between two strings - that is, everything (from the start)
	;                 that's the same in both of them.
	; PARAMETERS:
	;  string1 (I,REQ) - The first string to compare
	;  string2 (I,REQ) - The second string to compare
	; RETURNS:        The longest string that both of the given ones start with.
	;---------
	findStringOverlapFromStart(string1, string2) {
		overlap := ""
		
		Loop, Parse, string1
		{
			if(A_LoopField != string2.charAt(A_Index))
				Break
			overlap .= A_LoopField
		}
		
		return overlap
	}
	
	; #END#
}
