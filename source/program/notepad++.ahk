#IfWinActive, ahk_class Notepad++
	; New document.
	^t::^n
	
	; Re-open last closed document.
	^+t::
		Send, !f
		Send, 1
	return
	
	!+x::return
	
	::dbpop::
		SendRaw, DEBUG.popup(") ; ending quote for syntax highlighting: "
		Send, {Left} ; Get inside parens
	return
	
	::edbpop::
		SendRaw, DEBUG.popupEarly(") ; ending quote for syntax highlighting: "
		Send, {Left} ; Get inside parens
	return
	
	::dbto::
		SendRaw, DEBUG.toast(") ; ending quote for syntax highlighting: "
		Send, {Left} ; Get inside parens
	return
	
	; Function header
	::`;`;`;::
		sendAHKFunctionHeader() {
			; Select the following line after this one to get parameter information
			Send, {Down}
			Send, {End}{Shift Down}{Home}{Shift Up}
			firstLine := cleanupText(getSelectedText())
			Send, {Up}
			
			; Piece out the parameters
			paramsList := getStringBetweenStr(firstLine, "(", ")")
			paramsAry  := strSplit(paramsList, ",", " `t")
			
			; Drop any defaults from the parameters, get max length
			maxParamLength := 0
			For i,param in paramsAry {
				param := removeStringFromStart(param, "ByRef ")
				param := getStringBeforeStr(param, " :=")
				
				maxParamLength := max(maxParamLength, strLen(param))
				paramsAry[i] := param
			}
			; DEBUG.popup("Line",firstLine, "Params list",paramsList, "Params array",paramsAry, "Max param length",maxParamLength)
			
			startText = 
				( RTrim0
				;---------
				; DESCRIPTION:    
				
				)
			
			paramsText := ""
			For i,param in paramsAry {
				paramLen := strLen(param)
				param := param getSpaces(maxParamLength - paramLen)
				paramsText .= ";  " param " (I/O/IO,REQ/OPT) - `n"
			}
			if(paramsText)
				paramsText := "; PARAMETERS:`n" paramsText
			
			endText =
				( RTrim0
				; RETURNS:        
				; SIDE EFFECTS:   
				; NOTES:          
				;---------
				)
			SendRaw, % startText paramsText endText
		}
	
	^Enter::
		insertIndentedNewline() {
			; Read in both sides of the current line - the left will help us find where the indent is, the right is what we're moving.
			Send, {Shift Down}{Home}{Shift Up}
			lineStart := getSelectedText()
			Send, {Shift Down}{End}{Shift Up}
			lineEnd := getSelectedText()
			
			; Put the cursor back where it was, where we want to insert the newline.
			if(lineEnd = "")
				Send, {End}
			else
				Send, {Left}
			
			; If we would have a widowed (on the end of the old line) or orphaned (at the start of the new line) space, remove it.
			if(stringEndsWith(lineStart, A_Space))
				Send, {Backspace}
			if(stringStartsWith(lineEnd, A_Space))
				Send, {Delete}
			
			numSpaces := getDocumentationLineIndent(lineStart)
			
			Send, {Enter} ; Start the new line - assuming that Notepad++ will put us at the same indentation level (before the semicolon) as the previous row.
			sendTextWithClipboard(";" getSpaces(numSpaces))
		}
	
	;---------
	; DESCRIPTION:    Figure out where the indentation for a line is positioned (in terms of the
	;                 number of spaces after the comment character).
	; PARAMETERS:
	;  line (I,REQ) - The line that we're trying to determine indentation for.
	; RETURNS:        The number of spaces after the comment character that the indent is.
	;---------
	getDocumentationLineIndent(line) {
		line := cleanupText(line) ; Drop (and ignore) any leading/trailing whitespace and odd characters
		line := removeStringFromStart(line, "; ") ; Trim off the starting comment char + space
		numSpaces := 1 ; Space we just trimmed off
		
		keywords := ["DESCRIPTION:", "PARAMETERS:", "RETURNS:", "SIDE EFFECTS:", "NOTES:"]
		if(stringContainsAnyOf(line, keywords, matchedKeyword)) {
			; Keyword line - add length of keyword + however many spaces are after it.
			numSpaces += strLen(matchedKeyword)
			line := removeStringFromStart(line, matchedKeyword)
			numSpaces += countLeadingSpaces(line)
		} else {
			matchedPos := RegExMatch(line, "P)\((I|O|IO),(OPT|REQ)\) - ", matchedTextLen)
			if(matchedPos) {
				; Parameter line - add the position of the "(I,REQ) - "-style description - 1 + its length.
				numSpaces += (matchedPos - 1) + matchedTextLen
			} else {
				; Floating line - just count the spaces.
				numSpaces += countLeadingSpaces(line)
			}
		}
		
		return numSpaces
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
#IfWinActive
