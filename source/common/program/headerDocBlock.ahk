/* Class representing a block of documentation in AHK code, in Notepad++. =--
	
	Example Usage
;		block := new HeaderDocBlock().initFromSelection()
;		wrappedDoc := block.getWrappedString() ; Wrapped version of the selected documentation block

;		new HeaderDocBlock().rewrapSelection() ; Selects whole line if needed, then redoes wrapping, maintaining indentation appropriately
	
*/ ; --=

class HeaderDocBlock {
	;region ==================== PUBLIC ====================
	;---------
	; DESCRIPTION:    Create a new representation of a block of documentation.
	; PARAMETERS:
	;  docString (I,REQ) - The block of documentation to process.
	;---------
	__New(docString := "") {
		if(docString != "")
			this.initFromDocString(docString)
	}
	
	;---------
	; DESCRIPTION:    Initialize this class using the selection, rather than passing in a string value to the constructor.
	; RETURNS:        this
	;---------
	initFromSelection() {
		docString := this.getDocFromSelection()
		this.initFromDocString(docString)
		return this
	}
	
	;---------
	; DESCRIPTION:    Wrap the content and recombine it with our various bits of indentation to create our finished doc string.
	; RETURNS:        The wrapped and indented string for this documentation block
	; PARAMETERS:
	;  tabWidth (I,REQ) - The width that tabs should be considered.
	;---------
	getWrappedString(tabWidth) {
		leadingWidth := (this.outerRest this.innerRest).width(tabWidth) ; Use the "rest" instead of the first line as the first line may not include indentation.
		wrappedContentLines := StringLib.wrapToWidth(this.unwrappedContent, this.WRAP_WIDTH - leadingWidth, tabWidth)
		
		; Rebuild each line with its leading indentation and keywords.
		docString := ""
		For i,line in wrappedContentLines {
			if(i = 1)
				line := this.outerFirst this.innerFirst line
			else
				line := this.outerRest this.innerRest line
			docString := docString.appendLine(line)
		}
		
		return docString
	}
	
	;---------
	; DESCRIPTION:    Replace the selected documentation block (and potentially a little of its surroundings) with a
	;                 rewrapped version of the same.
	; PARAMETERS:
	;  tabWidth (I,REQ) - The width that tabs should be considered.
	;---------
	rewrapSelection(tabWidth) {
		this.initFromSelection()
		Sleep, 500 ; Wait a tick to make sure the program we're copying from doesn't get mad about us using the clipboard a second time so quickly.
		ClipboardLib.send(this.getWrappedString(tabWidth))
	}
	;endregion ================= PUBLIC ====================
	
	;region ==================== PRIVATE ===================
	COMMENT_CHAR := ";" ; The comment character that's assumed to precede each line of the documentation in question.
	WRAP_WIDTH := 100 ; The max width we want to (try and) keep all headers within.

	tabWidth         := "" ; How many characters wide a tab should be considered.
	outerFirst       := "" ; Tabs, semicolon, leading spaces for first line. Tracked separately for multi-line cases where first-line indent not selected, so we don't duplicate it.
	outerRest        := "" ; Tabs, semicolon, leading spaces for other lines.
	innerFirst       := "" ; Keyword + spaces for first line.
	innerRest        := "" ; Spaces to match keyword for other lines.
	unwrappedContent := "" ; The actual content, collapsed to a single line.
	
	;---------
	; DESCRIPTION:    Use the selected text (and potentialy select some of the surrounding text if needed) to get a
	;                 documentation block that we can work with.
	; RETURNS:        The located documentation block.
	; SIDE EFFECTS:   Can select more of the surrounding text if we don't have everything we need to start with.
	; NOTES:          Can be called with nothing selected to select everything we need, as a shortcut.
	;---------
	getDocFromSelection() {
		selection := SelectLib.getText()
		
		; Whole line, including newline (VSCode ^c with nothing selected, probably) - actually select the whole line.
		if(selection.endsWith("`n"))
			Send, {End 2}{Shift Down}{Home 2}{Shift Up} ; End twice to get to end of wrapped line, Home twice to try and get indent too.

		; Multiple lines - we can pull anything not selected in the first line, from the second line. We
		; shouldn't mess with the selection because we don't know which direction we selected from - so trying
		; to reselect might just mess with the last line.
		if(selection.contains("`n"))
			return selection
		
		; The line starts with indent - assume the user got it all.
		if(selection.startsWith("`t"))
			return selection
		
		; We can't get the indent from the current selection (which may be nothing), so reselect the whole
		; line (including the indent).
		Send, {End 2}{Shift Down}{Home 2}{Shift Up} ; End twice to get to end of wrapped line, Home twice to try and get indent too.
		selection := SelectLib.getText()
		
		; We got the indent on the first try (non-wrapped line)
		if(selection.startsWith("`t"))
			return selection
		
		; Either a wrapped string, or no indent at start - either way, we can select one more chunk with Home
		; and have everything.
		Send, {Shift Down}{Home}{Shift Up}
		selection := SelectLib.getText()
		
		return selection
	}
	
	;---------
	; DESCRIPTION:    Split the given documentation block into various pieces of indentation and content.
	; PARAMETERS:
	;  docString (I,REQ) - The block of documentation to process.
	;---------
	initFromDocString(docString) {
		docLines := docString.split("`n", "`r")
		
		; Get the outer chunk from the first line.
		outerNeedle := "^\t*" this.COMMENT_CHAR "\s+" ; Optional leading indent, comment character, spaces.
		docLines[1].matchesRegEx(outerNeedle, match)
		this.outerFirst := match
		
		; Figure out what the outer chunk should look like for subsequent lines.
		if(docLines[2] != "") { ; With a multi-line selection, we can use the second line and we're guaranteed to get the full indentation
			docLines[2].matchesRegEx(outerNeedle, match)
			this.outerRest := match ; Might include innerRest - if/when we can determine innerRest below, we'll remove it from outerRest.
		} else { ; Otherwise, we just have to assume that the outer chunk for any new lines should match the old one (and it should if we got the whole line).
			this.outerRest := this.outerFirst
		}
		
		; The inner bit for the first line will be any header-specific keywords (like DESCRIPTION:) and their following whitespace.
		this.innerFirst := this.getKeywordStartChunk(docLines)
		
		; The rest of the lines just need to indent to match the first so the content continues in the same spot horizontally.
		this.innerRest := StringLib.getSpaces(this.innerFirst.length())
		
		; If we fell back to the second line of the string to get outerRest, it might also contain innerRest - remove it if that's the case.
		this.outerRest := this.outerRest.removeFromEnd(this.innerRest)
		
		; Content is what's left after the rest is removed
		For i,line in docLines {
			; Peel off the indentation, keywords, etc.
			if(i = 1) {
				line := line.removeFromStart(this.outerFirst)
				line := line.removeFromStart(this.innerFirst)
			} else {
				line := line.removeFromStart(this.outerRest)
				line := line.removeFromStart(this.innerRest)
			}
			line := line.withoutWhitespace() ; Drop any extra whitespace from start/end too, so we don't end up with extra spaces in the middle of the string.
			
			this.unwrappedContent := this.unwrappedContent.appendPiece(" ", line)
		}
	}
	
	;---------
	; DESCRIPTION:    Using the first line of the block, extract any prefixes specific to a documentation header (i.e.
	;                 DESCRIPTION: or parameter lines).
	; PARAMETERS:
	;  docLines (I,REQ) - Array of lines representing the documentation block
	; RETURNS:        The found keyword (header keyword or parameter start), or "" if one not found
	;---------
	getKeywordStartChunk(docLines) {
		; The prefix in question will only be on the first line, after the outer indent, so we can trim our search to just that.
		docLine := docLines[1].removeFromStart(this.outerFirst)
		
		; Header keyword lines
		needle := "^([A-Z\s]+):\s+" ; Starts with (^) any all-caps words (including spaces) followed by a colon (:) and 1+ spaces
		if(docLine.matchesRegEx(needle, match))
			return match
		
		; Parameter lines
		if(docLine.matchesRegEx(".*\((I|O|IO),(OPT|REQ)\) - ", match)) ; Variable name + properties + leading hyphen and space
			return match
		
		return ""
	}
	;endregion ================= PRIVATE ===================
	
	;region ==================== DEBUG =====================
	Debug_ToString(ByRef table) {
		table.addLine("Outer indent, first line",          this.outerFirst)
		table.addLine("Outer indent, other lines",         this.outerRest)
		table.addLine("Inner indent/keywords, first line", this.innerFirst)
		table.addLine("Inner indent, other lines",         this.innerRest)
		table.addLine("Unwrapped content",                 this.unwrappedContent)
	}
	;endregion ================= DEBUG =====================
}

; Test cases: =--
; This is a short, single line with no indent.

; This is a short, single line with no indent, that will nonetheless need to wrap because it's just so long.
	
	; This is a short, single line.
	
	; This is a group of short lines
	; that seem to have been somewhat
	; over-wrapped.
	
	; This is such a long line of documentation, isn't it? Wow it just keeps going for days and days...
	
	; This is such a long line of documentation, isn't it? It even wraps around in a single screen in notepad, look at it wrap and wrap and go on and on...look at it wrap and wrap and go on and on...look at it wrap and wrap and go on and on...look at it wrap and wrap and go on and on...
	
	; This is a set of long lines that weren't wrapped quite propertly to begin with, but at
	; least they tried?
	
	; DESCRIPTION:    This will be a rather long description, that just keeps going and just keeps going, and just keeps going and just keeps going, you know?
	; PARAMETERS:
	;  inString             (I,REQ) - This will be a short parameter description
	;  goalWidth            (I,REQ) - This will be a longer parameter description, which also keeps going, and going, and going for days upon days.
	;  allowedFinalOverhang (I,OPT) - This will be a longer parameter description,
	;                                 that has already been wrapped, but not very well - too short at the first line, and too long on the last.
; --=
