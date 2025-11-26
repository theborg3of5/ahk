; String manipulation functions.

class StringLib {
	;region ------------------------------ PUBLIC ------------------------------
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
	; DESCRIPTION:    Wrap the given string in quotes, escaping any double-quotes inside by doubling them.
	; PARAMETERS:
	;  inputString (I,REQ) - The string to wrap in quotes.
	; RETURNS:        Quoted string
	;---------
	escapeAndQuote(inputString) {
		QUOTE := """" ; A single double-quote character
		return QUOTE this.escapeCharUsingChar(inputString, QUOTE, QUOTE) QUOTE
	}
	
	;---------
	; DESCRIPTION:    Determine whether the given string is empty or contains only whitespace.
	; PARAMETERS:
	;  stringToCheck (I,REQ) - The string to analyze.
	; RETURNS:        true if the string has nothing or nothing but whitespace.
	;---------
	isNullOrWhitespace(stringToCheck) {
		if(stringToCheck = "")
			return true
		
		cleanedString := stringToCheck.withoutWhitespace()
		if(cleanedString = "")
			return true
		
		return false
	}
	
	;---------
	; DESCRIPTION:    Determine whether a given string is formatted like a URL.
	; PARAMETERS:
	;  input (I,REQ) - The string to check.
	; RETURNS:        true/false - is the string a URL?
	;---------
	isURL(input) {
		; Full URLs
		if(input.startsWithAnyOf(["http://", "https://"]))
			return true
		
		; Partial URLs (www.google.com, similar)
		if(input.startsWithAnyOf(["www.", "vpn.", "m."]))
			return true
		
		; No match
		return false
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
	; DESCRIPTION:    Remove certain strings from the start/end of the given string.
	; PARAMETERS:
	;  inString      (I,REQ) - The string to remove things from
	;  removeStrings (I,OPT) - Array of strings to remove from the start/end of inString.
	; RETURNS:        The resulting string
	; SIDE EFFECTS:   Always removes leading/trailing whitespace.
	;---------
	dropLeadingTrailing(inString, removeStrings := "") {
		outStr := inString
		
		while(!isClean) {
			isClean := true
			
			; Always drop leading/trailing whitespace
			noWhitespace := outStr.withoutWhitespace()
			if(noWhitespace != outStr) {
				outStr := noWhitespace
				isClean := false
			}
			
			; Remove specific strings from start/end
			For _,dropString in removeStrings {
				if(outStr.startsWith(dropString)) {
					outStr := outStr.removeFromStart(dropString)
					isClean := false
				}
				if(outStr.endsWith(dropString)) {
					outStr := outStr.removeFromEnd(dropString)
					isClean := false
				}
			}
		}
		
		return outStr
	}
	
	;---------
	; DESCRIPTION:    Drop any empty lines (leading/trailing or in the middle) from the provided string.
	; PARAMETERS:
	;  inString (I,REQ) - The string to process
	; RETURNS:        The updated string.
	; NOTES:          Only supports `n and `r`n line endings (which should cover most strings)
	;---------
	dropEmptyLines(inString) {
		newlineNeedle := "(`n|`r`n)" ; Newline or return + newline
		
		; Reduce any spots where there's multiple newlines in a row
		outString := inString.replaceRegEx(newlineNeedle "{2,}", "$1")
		
		; Drop leading/trailing newline
		outString := outString.removeRegEx("^" newlineNeedle "|" newlineNeedle "$")
		
		return outString
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
		if(currentText.matchesRegEx("^\w+:/{0,2}", prefix))
			currentText := currentText.removeFromStart(prefix)
		
		; First replace any percents with the equivalent (since doing it later would also pick up anything else we've converted)
		needle := "%"
		replaceWith := "%" DataLib.numToHex(Asc("%"))
		currentText := currentText.replace(needle, replaceWith)
		
		; Replace any other iffy characters with their encoded equivalents
		while(currentText.matchesRegEx("i)[^\w\.~%]", charToReplace)) {
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
		
		while(outString.matchesRegEx("i)(?<=%)[\da-f]{1,2}", charCodeInHex)) {
			needle := "%" charCodeInHex
			replaceWith := Chr(DataLib.hexToInteger(charCodeInHex))
			outString := outString.replace(needle, replaceWith)
		}
		
		return outString
	}
	
	;---------
	; DESCRIPTION:    Wrap the given string to the provided dimensions.
	;                 Doesn't handle multiple leading spaces (and possibly multiple spaces in general)
	;                 very well.
	; PARAMETERS:
	;  inString             (I,REQ) - The string (without newlines) to wrap.
	;  goalWidth            (I,REQ) - The width (in characters) that we should shoot for.
	;  tabWidth             (I,REQ) - How many characters wide any tabs we encounter should be considered.
	;  allowedFinalOverhang (I,OPT) - The number of characters of overhang that's allowed on the final line, to avoid an additional line
	;                                 containing only a single short word.
	; RETURNS:        The same string, wrapped to the goal width with newlines.
	;---------
	wrapToWidth(inString, goalWidth, tabWidth, allowedFinalOverhang := 25) {
		maxLastLineWidth := goalWidth + allowedFinalOverhang
		words := inString.split(" ")
		
		line := ""
		wrappedLines := []
		For i,word in words {
			potentialLine := line.appendPiece(" ", word)
			lineLength := potentialLine.width()
			
			; We haven't exceeded our desired length yet. Just add the word and move on.
			if(lineLength <= goalWidth) {
				line := potentialLine
				Continue
			}
			
			; We've exceeded the goal length, but this is the last word we need to add -
			; allow it to stay on the same line if the new length will be within goal +
			; allowed overhang.
			if(lineLength <= maxLastLineWidth && i = words.length()) {
				line := potentialLine
				Continue
			}
			
			; Save off our previous line and start the next one.
			wrappedLines.push(line)
			line := word
		}
		wrappedLines.push(line) ; Get the last line as we finish
		
		return wrappedLines
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
	
	;---------
	; DESCRIPTION:    Generate a "ten string" of the given length, for easy visualization of how
	;                 long a string can be. A "ten string" is "1234567890" repeated to the given
	;                 length, with a | just past the last character to show the edge.
	;
	;                 If the length is bigger than 10, an additional line will be included at the
	;                 start that shows the tens digit at each 10th place.
	;                 
	;                 Examples:
	;                   - 5  => 12345|
	;                   - 15 =>          1     |
	;                           123456789012345|
	;                   - 30 =>          1         2         3|
	;                           123456789012345678901234567890|
	; PARAMETERS:
	;  rulersList (I,REQ) - List of lengths that our "rulers" should fall at. gdbredoc this whole thing
	; RETURNS:        Generated string
	;---------
	getTenString(rulersList, noTensLine := false) { ;gdbtodo consider renaming to "rulerString", and maybe change hotstring to .ruler?
		baseString := "1234567890"
		haveExplicitLabels := rulersList.contains("=")

		rulers := []
		For _, lengthString in rulersList.split(",", " ") {
			chunks := lengthString.split("=")
			len   := chunks[1]
			label := chunks[2]
			
			if (label.length() > len)
				label := label.sub(1, len - 1) "*" ; Truncate with marker

			rulers.push( { len:len, label:label } )

			DataLib.updateMax(maxLength, len)
		}
		
		onesLine := StringLib.duplicate(baseString, maxLength // 10) baseString.sub(1, Mod(maxLength, 10))
		emptyLine := StringLib.duplicate(A_Space, maxLength)
		
		; Generate fake labels for any rulers without them
		For _, ruler in rulers {
			if (ruler.label = "")
				ruler.label := ruler.len
		}

		; When there's no explicit labels, also add special markers for every 10 for easier
		; counting/measuring. We only do this when there's a single ruler, as handling the potential
		; interleaving with multiple is more trouble than it's worth.
		if (!noTensLine && !haveExplicitLabels && rulers.length() = 1) {
			Loop {
				num += 10
				if ( (num + maxLength.length()) > maxLength)
					Break

				; rulers[num] := {label:num, noPipe:true}
				rulers.push({len:num, label:num, noPipe:true})
			}
		}

		; We want to loop in reverse numeric order by length, so we can build label lines from rightmost
		; label to left (so we don't have to add pipes retroactively or worry about intersecting labels/pipes).
		rulers := DataLib.sortArrayBySubProperty(rulers, "len", false)
		
		; Build labels and their pointer pipes
		outputLines  := []
		prevRulers   := []
		prevLeftEdge := 0
		For _, ruler in rulers {
			; First one always goes on a new line (but without a spacer)
			if (!prevLeftEdge) {
				line := emptyLine

			; If the label will fit on the previous line, add it there to save space
			} else if (ruler.len < (prevLeftEdge - 1)) { ; prevLeftEdge-1 to require an extra space between this line and the previously-added label
				line := outputLines.Pop() ; Use previous line

			; Otherwise add a new line
			} else {
				; Include a spacer line when there's an overlap to make it easier to read
				outputLines.push(this.insertPipesForRulers(emptyLine, prevRulers))
				
				line := emptyLine
			}
			

			line := this.insertPipesForRulers(line, prevRulers)
			line := this.insertRuler(ruler, line)
			outputLines.push(line)
			
			prevRulers.push(ruler) ; Keep track of previously-added rulers so we can include their pipes on following lines
			prevLeftEdge := ruler.len - ruler.label.length()
		}

		outputLines.push(this.insertPipesForRulers(onesLine, rulers)) ; Ones line
		outputLines.push(this.insertPipesForRulers(emptyLine, rulers)) ; Spacer line at the bottom (nicer pointers, looks like a ruler)
		
		; Debug.popup("outputLines",outputLines)
		return outputLines.join("`n")
	}
	;endregion ------------------------------ PUBLIC ------------------------------


	insertPipesForRulers(line, rulers) {
		For _, ruler in rulers {
			if(!ruler.noPipe) ; Some rulers don't want pipes added
				line := line.replaceCharAt(ruler.len + 1, "|")
		}

		return line
	}

	insertRuler(ruler, line) {
		labelLeftEdge := ruler.len - ruler.label.length()
		return line.replaceSlice(ruler.label "|", labelLeftEdge + 1, ruler.len + 1)
	}
}
