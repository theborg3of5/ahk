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
	static escapeCharUsingChar(inputString, charToEscape, escapeChar := "\") {
		replaceString := escapeChar charToEscape
		return inputString.replace(charToEscape, replaceString)
	}

	;---------
	; DESCRIPTION:    Wrap the given string in quotes, escaping any double-quotes inside by doubling them.
	; PARAMETERS:
	;  inputString (I,REQ) - The string to wrap in quotes.
	; RETURNS:        Quoted string
	;---------
	static escapeAndQuote(inputString) {
		QUOTE := """" ; A single double-quote character
		return QUOTE this.escapeCharUsingChar(inputString, QUOTE, QUOTE) QUOTE
	}
	
	;---------
	; DESCRIPTION:    Determine whether the given string is empty or contains only whitespace.
	; PARAMETERS:
	;  stringToCheck (I,REQ) - The string to analyze.
	; RETURNS:        true if the string has nothing or nothing but whitespace.
	;---------
	static isNullOrWhitespace(stringToCheck) {
		if stringToCheck = ""
			return true

		cleanedString := stringToCheck.withoutWhitespace()
		if cleanedString = ""
			return true

		return false
	}
	
	;---------
	; DESCRIPTION:    Determine whether a given string is formatted like a URL.
	; PARAMETERS:
	;  input (I,REQ) - The string to check.
	; RETURNS:        true/false - is the string a URL?
	;---------
	static isURL(input) {
		if input.startsWithAnyOf(["http://", "https://"])
			return true

		if input.startsWithAnyOf(["www.", "vpn.", "m."])
			return true

		return false
	}

	;---------
	; DESCRIPTION:    Extract markdown-style links from a string into an array of objects.
	;
	;                 For example, this string:
	;                  "one[two](https://www.google.com)three"
	;                 Would return: [
	;                  { text: "one" }
	;                  { text: "two", url: "https://www.google.com" }
	;                  { text: "three" }
	;                 ]
	; PARAMETERS:
	;  inputText (I,REQ) - String that includes markdown-style links
	; RETURNS:        Array of objects broken up by the links, where for each object:
	;                  text = display text
	;                  url  = link URL (for links only)
	; SIDE EFFECTS:   
	; NOTES:          
	;---------
	static extractMarkdownLinks(inputText) {
		chunks := []
		startPos := 1
		while (pos := RegExMatch(inputText, "\[(.*?)\]\((.*?)\)", &match, startPos)) {
			preText := SubStr(inputText, startPos, pos - startPos)
			if preText != ""
				chunks.Push({text: preText})

			text := match[1]
			url  := FileLib.cleanupPath(match[2])
			chunks.Push({text: text, url: url})
			startPos := pos + match.Len
		}
		remainingText := SubStr(inputText, startPos)
		if remainingText != ""
			chunks.Push({text: remainingText})

		return chunks
	}
	
	;---------
	; DESCRIPTION:    Determine how many spaces there are at the beginning of a string.
	; PARAMETERS:
	;  line (I,REQ) - The line to count spaces for.
	; RETURNS:        The number of spaces at the beginning of the line.
	;---------
	static countLeadingSpaces(line) {
		numSpaces := 0

		Loop Parse, line {
			if A_LoopField = A_Space
				numSpaces++
			else
				break
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
	static indentBlock(textBlock, numSpaces) {
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
	static dropLeadingTrailing(inString, removeStrings := "") {
		outStr := inString

		Loop {
			isClean := true

			noWhitespace := outStr.withoutWhitespace()
			if noWhitespace != outStr {
				outStr := noWhitespace
				isClean := false
			}

			for _, dropString in removeStrings {
				if outStr.startsWith(dropString) {
					outStr := outStr.removeFromStart(dropString)
					isClean := false
				}
				if outStr.endsWith(dropString) {
					outStr := outStr.removeFromEnd(dropString)
					isClean := false
				}
			}

			if isClean
				break
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
	static dropEmptyLines(inString) {
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
	static getSpaces(numToGet) {
		return StringLib.duplicate(A_Space, numToGet)
	}
	;---------
	; DESCRIPTION:    Get the specified number of tabs.
	; PARAMETERS:
	;  numToGet (I,REQ) - How many tabs to return.
	; RETURNS:        As many tabs as requested.
	;---------
	static getTabs(numToGet) {
		return StringLib.duplicate(A_Tab, numToGet)
	}
	;---------
	; DESCRIPTION:    Get the specified number of newlines.
	; PARAMETERS:
	;  numToGet (I,REQ) - How many newlines to return.
	; RETURNS:        As many newlines as requested.
	;---------
	static getNewlines(numToGet) {
		return StringLib.duplicate("`n", numToGet)
	}
	;---------
	; DESCRIPTION:    Get the specified number of dots.
	; PARAMETERS:
	;  numToGet (I,REQ) - How many dots to return.
	; RETURNS:        As many dots as requested.
	;---------
	static getDots(numToGet) {
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
	static duplicate(stringToDup, numTimes) {
		if stringToDup = "" || numTimes < 1
			return ""

		outStr := ""

		Loop numTimes
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
	static padCenter(textToCenter, goalLength, padChar := " ") {
		leftoverWidth := goalLength - StrLen(textToCenter)
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
	static encodeForURL(textToEncode) {
		currentText := textToEncode
		prefix := ""

		if currentText.matchesRegEx("^\w+:/{0,2}", &prefixMatch) {
			prefix := prefixMatch[]
			currentText := currentText.removeFromStart(prefix)
		}

		needle := "%"
		replaceWith := "%" DataLib.numToHex(Asc("%"))
		currentText := currentText.replace(needle, replaceWith)

		while currentText.matchesRegEx("i)[^\w\.~%]", &charMatch) {
			charToReplace := charMatch[]
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
	static decodeFromURL(textToDecode) {
		outString := textToDecode

		while outString.matchesRegEx("i)(?<=%)[\da-f]{1,2}", &hexMatch) {
			charCodeInHex := hexMatch[]
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
	static wrapToWidth(inString, goalWidth, tabWidth, allowedFinalOverhang := 25) {
		maxLastLineWidth := goalWidth + allowedFinalOverhang
		words := inString.split(" ")

		line := ""
		wrappedLines := []
		for i, word in words {
			potentialLine := line.appendPiece(" ", word)
			lineLength := potentialLine.width()

			if lineLength <= goalWidth {
				line := potentialLine
				continue
			}

			if lineLength <= maxLastLineWidth && i = words.Length {
				line := potentialLine
				continue
			}

			wrappedLines.Push(line)
			line := word
		}
		wrappedLines.Push(line)

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
	static findStringOverlapFromStart(string1, string2) {
		overlap := ""

		Loop Parse, string1 {
			if A_LoopField != string2.charAt(A_Index)
				break
			overlap .= A_LoopField
		}

		return overlap
	}
	
	;---------
	; DESCRIPTION:    Generate a "ruler" of the given length, for easy visualization of how
	;                 long a string can be. By default, we'll label each ruler with its length:
	;                  5 =>     5|
	;                       12345|
	;                            |
	;
	;                 If the (single, unlabelled) length is bigger than 12, we'll add (un-piped) labels
	;                 for each 10:
	;                  25 =>         10|       20|  25|
	;                        1234567890123456789012345|
    ;                                                 |
	;
	;                 Multiple rulers can be specified by separating them with commas:
	;                  25,30,19 =>                  19|   25|  30|
	;                              1234567890123456789|12345|7890|
	;                                                 |     |    |
	;
	;                 Labels can be added to each ruler by appending "=label" to each length. If a label
	;                 won't fit, we'll push it up onto a new line with a spacer (except for the first
	;                 label, which we just truncate):
	;                  5=Too long,15=Mid,30=This is longer but it's OK =>     This is longer but it's OK|
	;                                                                                                   |
	;                                                                     Too *|      Mid|              |
	;                                                                     12345|789012345|78901234567890|
	;                                                                          |         |              |
	; PARAMETERS:
	;  rulersList (I,REQ) - Comma-separated list of ruler lengths that our "rulers" should appear at.
	;                       Can optionally include "=label" on each length to show that label.
	; RETURNS:        Generated string (includes an extra newline on the end so your cursor ends up
	;                 below the "ruler").
	;---------
	static getRulerString(rulersList) {
		baseString := "1234567890"
		haveExplicitLabels := rulersList.contains("=")
		outputLines  := []

		rulers := []
		For _, lengthString in rulersList.split(",", " ") {
			chunks := lengthString.split("=")
			len   := chunks[1]
			label := chunks[2]
			
			if StrLen(label) > len
				label := label.sub(1, len - 1) "*" ; Truncate with marker

			rulers.Push( { len:len, label:label } )

			DataLib.updateMax(&maxLength, len)
		}

		; Generate fake labels for any rulers without them
		For _, ruler in rulers {
			if (ruler.label = "")
				ruler.label := ruler.len
		}
		
		; When there's no explicit labels, also add special markers for every 10 for easier
		; counting/measuring. We only do this when there's a single ruler, as handling the potential
		; interleaving with multiple is more trouble than it's worth.
		if !haveExplicitLabels && rulers.Length = 1 {
			num := 0
			Loop {
				num += 10
				if (num + StrLen(maxLength)) > maxLength
					break

				rulers.Push({len:num, label:num, noPipe:true})
			}
		}

		; We want to loop in reverse numeric order by length, so we can build label lines from rightmost
		; label to left (so we don't have to add pipes retroactively or worry about intersecting labels/pipes).
		rulers := DataLib.sortArrayBySubProperty(rulers, "len", false)
		
		; This is an empty line of the correct length that we'll start all our labels lines with
		emptyLine := StringLib.duplicate(A_Space, maxLength)
		
		; Build labels and their pointer pipes
		prevRulers   := []
		prevLeftEdge := 0
		For _, ruler in rulers {

			; If the label will fit on the previous line, add it there to save space
			if (ruler.len < (prevLeftEdge - 1)) { ; Extra -1 to ensure there's a space of padding between previous label and new pipe
				line := outputLines.Pop() ; Use previous line (remove it because we'll re-push it below)
			; Otherwise add a new line
			} else {
				line := emptyLine
				
				; Include a spacer line when there's an overlap to make it easier to read
				if (prevLeftEdge) ; But not for the first ruler
					outputLines.push(this.insertPipesForRulers(emptyLine, prevRulers))
			}
				
			line := this.insertRuler(ruler, line) ; Add the current ruler label + pipe to the line
			line := this.insertPipesForRulers(line, prevRulers) ; Add in pipes for any previously-added rulers
			outputLines.push(line)
			
			prevRulers.push(ruler) ; Keep track of previously-added rulers so we can include their pipes on following lines
			prevLeftEdge := ruler.len - StrLen(ruler.label)
		}

		numsLine := StringLib.duplicate(baseString, maxLength // 10) baseString.sub(1, Mod(maxLength, 10))
		outputLines.Push(this.insertPipesForRulers(numsLine,  rulers))
		outputLines.Push(this.insertPipesForRulers(emptyLine, rulers))
		
		; Debug.popup("outputLines",outputLines)
		return outputLines.join("`n") "`n"
	}
	;endregion ------------------------------ PUBLIC ------------------------------

	;region ------------------------------ PRIVATE ------------------------------
	;---------
	; DESCRIPTION:    Overlay the pipes for the given rulers onto the given string.
	; PARAMETERS:
	;  line   (I,REQ) - Starting line to add pipes to.
	;  rulers (I,REQ) - Array of rulers to add pipes for.
	; RETURNS:        String with pipes added.
	;---------
	static insertPipesForRulers(line, rulers) {
		for _, ruler in rulers {
			if !ruler.noPipe
				line := line.replaceCharAt(ruler.len + 1, "|")
		}

		return line
	}

	;---------
	; DESCRIPTION:    Add the given ruler's label and pipe to the given line.
	; PARAMETERS:
	;  ruler (I,REQ) - Ruler to add
	;  line  (I,REQ) - Line to add the ruler to
	; RETURNS:        String with ruler added.
	;---------
	static insertRuler(ruler, line) {
		labelLeftEdge := ruler.len - StrLen(ruler.label)
		return line.replaceSlice(ruler.label "|", labelLeftEdge + 1, ruler.len + 1)
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
