/* GDB TODO --=
	
	Example Usage
;		GDB TODO
	
	GDB TODO
		Update auto-complete and syntax highlighting notepad++ definitions
	
*/ ; =--

class AHKDocBlock {
	deconstructDocString(docString) {
		; ["OUTER_FIRST"] ; Leading indent, comment character (;), and leading spaces. Must be tracked separately for multi-line cases where entire first line not selected (so we don't add extra indents and such when it's already there).
		; ["OUTER_REST"]  ; Leading indent, comment character (;), and leading spaces
		; ["INNER_FIRST"] ; Keyword (if one found) + indent for first line
		; ["INNER_REST"]  ; Additional indent for lines after the first
		; ["CONTENT"]     ; The actual content, collapsed to a single line
		
		docLines := docString.split("`n", "`r")
		
		; Get the outer chunk from the first line.
		needle := "^\t*;\s+" ; Optional leading indent, comment character (;), spaces.
		docLines[1].containsRegEx(needle, outerFirst)
		
		; Figure out what the outer chunk should look like for subsequent lines.
		if(docLines[2] != "") { ; With a multi-line selection, we can use the second line and we're guaranteed to get the full indentation
			docLines[2].containsRegEx(needle, outerRest) ; Might include innerRest - if/when we can determine innerRest, we'll remove it from outerRest.
		} else { ; Otherwise, we just have to assume that the outer chunk for any new lines should match the old one (and it should if we got the whole line).
			outerRest := outerFirst
		}
		
		; GDB TODO consider wrapping all the docLine stuff together in a function, since it's not used elsewhere
		; Everything else can come from the first line, sans the outer indent (or any sub-portion of it)
		docLine := docLines[1].removeFromStart(outerFirst)
		; docLine := docLines[1].afterString(";").withoutWhitespace() ; Drop anything before (and including) the semicolon, and any whitespace after it
		
		; GDB TODO AHKCodeLib.HeaderKeywords is private
		; Header keyword lines
		needle := "^(" AHKCodeLib.HeaderKeywords.join("|") "):\s+" ; Starts with (^) any of the keywords followed by a colon (:) and 1+ spaces
		if(docLine.containsRegEx(needle, foundHeaderKeyword))
			innerFirst := foundHeaderKeyword
		
		; Parameter lines
		needle := ".*\((I|O|IO),(OPT|REQ)\) - "
		if(docLine.containsRegEx(needle, foundParamStart))
			innerFirst := foundParamStart
		docLine := docLine.removeFromStart(innerFirst)
		
		; If the first line has any special keywords, subsequent lines should have extra indentation to match so the content continues in the same spot horizontally.
		innerRest := StringLib.getSpaces(innerFirst.length())
		
		; outer shouldn't contain innerRest - the only time this should happen is if we fell back to the second line to get our indent.
		outerRest := outerRest.removeFromEnd(innerRest)
		
		; Content is what's left after the rest is removed
		content := ""
		For i,line in docLines {
			; Peel off the indentation, keywords, etc.
			if(i = 1) {
				line := line.removeFromStart(outerFirst)
				line := line.removeFromStart(innerFirst)
			} else {
				line := line.removeFromStart(outerRest)
				line := line.removeFromStart(innerRest)
			}
			
			; Drop any extra whitespace from start/end too, so we don't end up with extra spaces in the middle of the string.
			line := line.withoutWhitespace()
			
			content := content.appendPiece(line, " ")
		}
		
		; Debug.popup("docString",docString, "outerFirst","x" outerFirst "x", "outerRest","x" outerRest "x", "innerFirst","x" innerFirst "x", "innerRest","x" innerRest "x", "content",content)
		return {"OUTER_FIRST":outerFirst, "OUTER_REST":outerRest, "INNER_FIRST":innerFirst, "INNER_REST":innerRest, "CONTENT":content}
	}

	wrapToWidth(inString, goalWidth, allowedFinalOverhang := 5) {
		maxLastLineWidth := goalWidth + allowedFinalOverhang
		words := inString.split(" ")
		
		line := ""
		wrappedLines := []
		For i,word in words {
			potentialLine := line.appendPiece(word, " ")
			lineLength := potentialLine.length()
			
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
	
	
	
	
	
	; #PUBLIC#
	
	;  - Constants
	;  - staticMembers
	;  - nonStaticMembers
	;  - properties
	;  - __New()/Init()
	;  - otherFunctions
	
	
	; #INTERNAL#
	
	;  - Constants
	;  - staticMembers
	;  - nonStaticMembers
	;  - functions
	
	
	; #PRIVATE#
	
	;  - Constants
	;  - staticMembers
	;  - nonStaticMembers
	;  - functions
	
	
	; #DEBUG#
	
	Debug_TypeName() {
		return "AHKDocBlock"
	}
	
	Debug_ToString(ByRef table) {
		table.addLine("GDB TODO", this.GDBTODO)
	}
	; #END#
}
