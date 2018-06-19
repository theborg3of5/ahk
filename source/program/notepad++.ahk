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
			Send, {Left} ; Put the cursor back where it was, where we want to insert the newline.
			
			; If the line will end with a space after we add a newline, remove that space.
			if(stringEndsWith(lineStart, A_Space))
				Send, {Backspace}
			; If the new line text starts with a space, remove that space.
			if(stringStartsWith(lineEnd, A_Space))
				Send, {Delete}
			
			; Figure out where the current indent is at.
			
			lineStart := cleanupText(lineStart) ; Drop (and ignore) any leading/trailing whitespace and odd characters
			lineStart := removeStringFromStart(lineStart, "; ") ; Trim off the starting comment char + space
			numSpaces := 1 ; Space we just trimmed off
			
			; If it's one of the keywords, just see how many spaces (plus length of matching keyword) there are until next non-space character.
			matchedKeyword := false ; GDB TEMP - remove once this is in a function
			keywords := ["DESCRIPTION:", "PARAMETERS:", "RETURNS:", "SIDE EFFECTS:", "NOTES:"]
			for i,keyword in keywords {
				if(stringStartsWith(lineStart, keyword)) {
					matchedKeyword := true ; GDB TODO functionalize this better - just true/false if a keyword matches, then do the rest?
					numSpaces += strLen(keyword)
					lineStart := removeStringFromStart(lineStart, keyword)
					
					; Count the remaining spaces until something else. ; GDB TODO can this bit be a (private) function?
					Loop, Parse, lineStart
					{
						if(A_LoopField = A_Space)
							numSpaces++
						else
							Break
					}
					
					Break ; Found our match.
				}
			}
			
			; If we didn't match a keyword, we're on a parameter line or a floating line.
			if(!matchedKeyword) {
				matchedPos := RegExMatch(lineStart, "P)\((I|O|IO),(OPT|REQ)\) - ", matchedTextLen)
				if(matchedPos) { ; Parameter line
					numSpaces += (matchedPos - 1) + matchedTextLen ; GDB TODO should this be +2 for the space after the hyphen too?
				} else { ; Floating line (already indented to where we want)
					; Count the remaining spaces until something else. ; GDB TODO can this bit be a (private) function?
					Loop, Parse, lineStart
					{
						if(A_LoopField = A_Space)
							numSpaces++
						else
							Break
					}
				}
			}
			
			Send, {Enter} ; Start the new line - assuming that Notepad++ will put us at the same indentation level (before the semicolon) as the previous row.
			sendTextWithClipboard(";" getSpaces(numSpaces))
		}
#IfWinActive
