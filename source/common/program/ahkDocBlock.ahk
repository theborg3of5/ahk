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
	
	reindentSelection() {
		this.initFromSelection()
		ClipboardLib.send(this.getString())
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
		outerNeedle := "^\t*;\s+" ; Optional leading indent, comment character (;), spaces.
		docLines[1].containsRegEx(outerNeedle, match)
		this.outerFirst := match
		
		; Figure out what the outer chunk should look like for subsequent lines.
		if(docLines[2] != "") { ; With a multi-line selection, we can use the second line and we're guaranteed to get the full indentation
			docLines[2].containsRegEx(outerNeedle, match)
			this.outerRest := match ; Might include innerRest - if/when we can determine innerRest below, we'll remove it from outerRest.
		} else { ; Otherwise, we just have to assume that the outer chunk for any new lines should match the old one (and it should if we got the whole line).
			this.outerRest := this.outerFirst
		}
		
		; The inner bit for the first line will be any header-specific keywords (like DESCRIPTION:) and their following whitespace.
		this.innerFirst := this.getHeaderPrefix(docLines)
		
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
			
			this.unwrappedContent := this.unwrappedContent.appendPiece(line, " ")
		}
	}
	
	getHeaderPrefix(docLines) {
		; The prefix in question will only be on the first line, after the outer indent, so we can trim our search to just that.
		docLine := docLines[1].removeFromStart(this.outerFirst)
		
		; GDB TODO AHKCodeLib.HeaderKeywords is private - consider turning it (or maybe this needle?) into a public constant or something
		; Header keyword lines
		needle := "^(" AHKCodeLib.HeaderKeywords.join("|") "):\s+" ; Starts with (^) any of the keywords followed by a colon (:) and 1+ spaces
		if(docLine.containsRegEx(needle, match))
			return match
		
		; Parameter lines
		if(docLine.containsRegEx(".*\((I|O|IO),(OPT|REQ)\) - ", match))
			return match
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
