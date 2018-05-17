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
				param := getStringBeforeStr(param, " =")
				
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
	return
#IfWinActive
