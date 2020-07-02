/* GDB TODO --=
	
	Example Usage
;		GDB TODO
	
	GDB TODO
		Update auto-complete and syntax highlighting notepad++ definitions
	
*/ ; =--

class AHKDocBlock {
	; #PUBLIC#
	
	;  - Constants
	;  - staticMembers
	;  - nonStaticMembers
	;  - properties
	;  - __New()/Init()
	__New(docString := "") {
		if(docString != "")
			this.initFromDocString(docString)
	}
	
	initFromSelection() {
		docString := this.getDocFromSelection()
		this.initFromDocString(docString)
		return this
	}
	
	;  - otherFunctions
	getString() {
		return this.rebuildDocString()
	}
	
	; #INTERNAL#
	
	;  - Constants
	;  - staticMembers
	;  - nonStaticMembers
	;  - functions
	
	
	; #PRIVATE#
	
	;  - Constants
	;  - staticMembers
	;  - nonStaticMembers
	outerFirst       := "" ; Tabs, semicolon, leading spaces for first line. Tracked separately for multi-line cases where first-line indent not selected, so we don't duplicate it.
	outerRest        := "" ; Tabs, semicolon, leading spaces for other lines.
	innerFirst       := "" ; Keyword + spaces for first line.
	innerRest        := "" ; Spaces to match keyword for other lines.
	unwrappedContent := "" ; The actual content, collapsed to a single line.
	
	;  - functions
	
	getDocFromSelection() {
		selection := SelectLib.getText()
		
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
	
	initFromDocString(docString) {
		docLines := docString.split("`n", "`r")
		
		; Get the outer chunk from the first line.
		needle := "^\t*;\s+" ; Optional leading indent, comment character (;), spaces.
		docLines[1].containsRegEx(needle, match)
		this.outerFirst := match
		
		; Figure out what the outer chunk should look like for subsequent lines.
		if(docLines[2] != "") { ; With a multi-line selection, we can use the second line and we're guaranteed to get the full indentation
			docLines[2].containsRegEx(needle, match)
			this.outerRest := match ; Might include innerRest - if/when we can determine innerRest, we'll remove it from outerRest.
		} else { ; Otherwise, we just have to assume that the outer chunk for any new lines should match the old one (and it should if we got the whole line).
			this.outerRest := this.outerFirst
		}
		
		; GDB TODO consider wrapping all the docLine stuff together in a function, since it's not used elsewhere
		; Everything else can come from the first line, sans the outer indent (or any sub-portion of it)
		docLine := docLines[1].removeFromStart(this.outerFirst)
		; docLine := docLines[1].afterString(";").withoutWhitespace() ; Drop anything before (and including) the semicolon, and any whitespace after it
		
		; GDB TODO AHKCodeLib.HeaderKeywords is private
		; Header keyword lines
		needle := "^(" AHKCodeLib.HeaderKeywords.join("|") "):\s+" ; Starts with (^) any of the keywords followed by a colon (:) and 1+ spaces
		if(docLine.containsRegEx(needle, foundHeaderKeyword))
			this.innerFirst := foundHeaderKeyword
		
		; Parameter lines
		needle := ".*\((I|O|IO),(OPT|REQ)\) - "
		if(docLine.containsRegEx(needle, foundParamStart))
			this.innerFirst := foundParamStart
		docLine := docLine.removeFromStart(this.innerFirst)
		
		; If the first line has any special keywords, subsequent lines should have extra indentation to match so the content continues in the same spot horizontally.
		this.innerRest := StringLib.getSpaces(this.innerFirst.length())
		
		; outer shouldn't contain innerRest - the only time this should happen is if we fell back to the second line to get our indent.
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
			
			; Drop any extra whitespace from start/end too, so we don't end up with extra spaces in the middle of the string.
			line := line.withoutWhitespace()
			
			this.unwrappedContent := this.unwrappedContent.appendPiece(line, " ")
		}
	}
	
	
	rebuildDocString() {
		wrappedContentLines := StringLib.wrapToWidth(this.unwrappedContent, 100)
		
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
	
	
	; #DEBUG#
	
	Debug_TypeName() {
		return "AHKDocBlock"
	}
	
	Debug_ToString(ByRef table) {
		table.addLine("GDB TODO", this.GDBTODO)
	}
	; #END#
}
