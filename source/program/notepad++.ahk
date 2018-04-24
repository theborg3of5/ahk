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
	
	; Function header
	::`;`;`;::
		sendAHKFunctionHeader() {
			; Select the following line after this one to get parameter information
			Send, {Down}
			Send, {End}{Shift Down}{Home}{Shift Up}
			firstLine := cleanupText(getSelectedText())
			Send, {Up}
			
			; Piece out the parameters
			openParenPos  := stringContains(firstLine, "(")
			closeParenPos := stringContains(firstLine, ")")
			paramsList := subStr(firstLine, openParenPos + 1, closeParenPos - openParenPos - 1)
			paramsAry  := strSplit(paramsList, ",", " `t")
			
			; Drop any defaults from the parameters, get max length
			maxParamLength := 0
			For i,param in paramsAry {
				firstSpacePos := stringContains(param, " ")
				if(firstSpacePos)
					paramsAry[i] := subStr(param, 1, firstSpacePos - 1)
				
				maxParamLength := max(maxParamLength, strLen(paramsAry[i]))
			}
			; DEBUG.popup("Line",firstLine, "Params list",paramsList, "Params array",paramsAry, "Max param length",maxParamLength)
			
			startText = 
				( RTrim0
				;---------
				; DESCRIPTION:    
				; PARAMETERS:
				
				)
			
			paramsText := ""
			For i,param in paramsAry {
				paramLen := strLen(param)
				param := param getSpaces(maxParamLength - paramLen)
				paramsText .= ";  " param " (I/O/IO,REQ/OPT) - `n"
			}
			
			endText =
				( RTrim0
				; RETURNS:        
				; SIDE EFFECTS:   
				; NOTES:          
				;---------
				)
			SendRaw, % startText paramsText endText
		}
	return
#IfWinActive
