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
	;  rulersList (I,REQ) - List of lengths that our "rulers" should fall at. gdbredoc
	; RETURNS:        Generated string
	;---------
	getTenString(rulersList, noTensLine := false) { ;gdbtodo consider renaming to "rulerString", and maybe change hotstring to .ruler?
		baseString := "1234567890"
		haveLabels := rulersList.contains("=")

		; We want to do all looping in reverse numeric order so we can build label lines from rightmost
		; label to left (so we don't have to add pipes retroactively).
		; Sort, rulersList, D`, N R ; Sort command works fine even with =label bits on the ends

		; rulers := {} ; { len => { label, noPipe } }
		rulers := []
		For _, lengthString in rulersList.split(",", " ") {
			chunks := lengthString.split("=")
			len   := chunks[1]
			label := chunks[2]
			
			if (label.length() > len)
				label := label.sub(1, len - 1) "*" ; Truncate with marker

			rulers.push( { len:len, label:label } )

			DataLib.updateMax(maxLength, len)
			; rulers[len] := { label:label }
		}
		
		; maxLength := rulers.MaxIndex()
		; Debug.popup("rulers",rulers, "maxLength",maxLength)
		onesLine := StringLib.duplicate(baseString, maxLength // 10) baseString.sub(1, Mod(maxLength, 10))
		emptyLine := StringLib.duplicate(A_Space, maxLength)
		
		; return onesLine

		; lengthsList := new FormattedList(lengthsList).getList(FormattedList.Format_Commas) ; Turn it into comma-delimited if it's space or comma-space delimited
		; Sort, lengthsList, D`, N ; Sort numerically (works even with =label bits on the ends)
		; Debug.popup("lengthsList",lengthsList)

		; maxLength := DataLib.max()

		; return ""
		if (!haveLabels) {
			; Generate fake labels for the given rulers
			For _, ruler in rulers
				ruler.label := ruler.len

			; Also add special markers for every 10 for easier counting/measuring ;gdbtodo decide what to do for these
			if (!noTensLine && rulers.length() = 1) { ; Only auto-add when there's a single ruler, not worth handling the interleaving with multiple
				Loop {
					num += 10
					if ( (num + maxLength.length()) > maxLength)
						Break

					; rulers[num] := {label:num, noPipe:true}
					rulers.push({len:num, label:num, noPipe:true})
				}
			}

			; gdbtodo will have to resort, right? At least if there's multiple (unlabelled) rulers?
			; Sort, rulersList, D`, N R ; Sort command works fine even with =label bits on the ends
			; rulers := []
			; For _, lengthString in rulersList.split(",", " ") {

			haveLabels := true
		}
		
		; onesLine := StringLib.duplicate(baseString, length // 10) baseString.sub(1, Mod(length, 10)) "|"
		onesLine := this.addRulerPipesToLine(onesLine, rulers)


		if (haveLabels) {
			; Add labels above the ones line
			labelLines := []
			prevRulers := []

			prevLeftEdge := 0

			rulers := DataLib.sortArrayBySubProperty(rulers, "len", false) ; We want to loop in reverse order
			For _, ruler in rulers {
				; ; Mark the ones line at each ruler
				; onesLine := onesLine.replaceCharAt(ruler.len + 1, "|")
				; Debug.popup("ruler",ruler)

				if (ruler.label) {

					if (ruler.label.length() > ruler.len) {
						;gdbtodo add special check for when label is too long to fit within its ruler's entire length
						MsgBox, warning case
					}

					labelLeftEdge := ruler.len - ruler.label.length()

					; Debug.popup("ruler",ruler, "labelLeftEdge",labelLeftEdge)

					; Add to previous line instead of making a new one if it fits
					if ( !prevLeftEdge || ruler.len < (prevLeftEdge - 1)) { ; prevLeftEdge-1 to require an extra space between this line and the previously-added label
						labelLine := labelLines.Pop()
						if (!labelLine)
							labelLine := emptyLine
						
						newLabelLine := labelLine.replaceSlice(ruler.label "|", labelLeftEdge + 1, ruler.len + 1)

						; Debug.popup("ruler",ruler, "prevLeftEdge",prevLeftEdge, "labelLine",labelLine, "newLabelLine",newLabelLine)

						labelLines.push(newLabelLine)

					; Otherwise add a new line
					} else {
						; Debug.popup("+New line", "ruler",ruler)
						; Include a spacer line
						labelLines.push(this.addRulerPipesToLine(emptyLine, prevRulers))
						
						; labelLine := StringLib.duplicate(A_Space, labelLeftEdge + 1) ruler.label "|"
						labelLine := emptyLine.replaceSlice(ruler.label "|", labelLeftEdge + 1, ruler.len + 1)
						; line := line.replaceCharAt(ruler.len + 1, "|")
						labelLines.push(this.addRulerPipesToLine(labelLine, prevRulers))
						
					}
					
					; prevRulers[len] := ruler
					prevRulers.push(ruler)
					prevLeftEdge := labelLeftEdge
				}
			}

			; Debug.popup("labelLines",labelLines, "onesLine",onesLine)
			return labelLines.join("`n") "`n" onesLine "`n" this.addRulerPipesToLine(emptyLine, rulers)

		; gdbtodo could we make this a special kind of auto-generated label?
		; Something like:
		;         10|        21|             <-- Edge case to not show 20 when the final length is 21-22 (otherwise it would conflict)
		; 123456789012345678901|
		} else if (!noTensLine && maxLength > 10) { 
			; For strings longer than 10 chars, add an additional line showing the tens place.
			baseString := StringLib.duplicate(A_Space, 10)
			Loop, % maxLength // 10 {
				tensDigit := A_Index
				tensLine .= baseString.sub(1, -tensDigit.length()) tensDigit
			}
			tensLine .= baseString.sub(1, Mod(maxLength, 10)) "|"
		}

		if(maxLength <= 10 || noTensLine)
			return onesLine

		
		return tensLine.appendLine(onesLine)
	}
	;endregion ------------------------------ PUBLIC ------------------------------


	addRulerPipesToLine(line, rulers) {
		For _, ruler in rulers {
			if(!ruler.noPipe) ; Some rulers don't want pipes added
				line := line.replaceCharAt(ruler.len + 1, "|")
		}

		return line
	}
}
