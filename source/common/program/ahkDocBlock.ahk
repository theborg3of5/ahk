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
	rewrappedString {
		get {
			return ""
		}
	}
	
	;  - __New()/Init()
	__New(docString) {
		this.initFromDocString(docString)
	}
	
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
	outerFirst       := "" ; Tabs, semicolon, leading spaces for first line. Tracked separately for multi-line cases where first-line indent not selected, so we don't duplicate it.
	outerRest        := "" ; Tabs, semicolon, leading spaces for other lines.
	innerFirst       := "" ; Keyword + spaces for first line.
	innerRest        := "" ; Spaces to match keyword for other lines.
	unwrappedContent := "" ; The actual content, collapsed to a single line.
	
	;  - functions
	
	initFromDocString(docString) {
		; ["OUTER_FIRST"] ; Leading indent, comment character (;), and leading spaces. Must be tracked separately for multi-line cases where entire first line not selected (so we don't add extra indents and such when it's already there).
		; ["OUTER_REST"]  ; Leading indent, comment character (;), and leading spaces
		; ["INNER_FIRST"] ; Keyword (if one found) + indent for first line
		; ["INNER_REST"]  ; Additional indent for lines after the first
		; ["CONTENT"]     ; The actual content, collapsed to a single line
		
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
		
		; Debug.popup("docString",docString, "outerFirst","x" outerFirst "x", "outerRest","x" outerRest "x", "innerFirst","x" innerFirst "x", "innerRest","x" innerRest "x", "content",content)
		; return {"OUTER_FIRST":outerFirst, "OUTER_REST":outerRest, "INNER_FIRST":innerFirst, "INNER_REST":innerRest, "CONTENT":content}
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
