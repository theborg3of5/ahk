#If MainConfig.isWindowActive("Notepad++")
	!x::return ; Block close-document hotkey that can't be changed/removed.
	^+t::Send, !f1 ; Re-open last closed document.
	
	; Copy current file/folder to clipboard.
	!c::copyFilePathWithHotkey("!c")
	!#c::copyFolderPathWithHotkey("^!c")
	
	^Enter::NotepadPlusPlus.insertIndentedNewline() ; Add an indented newline
	
	; Insert various AHK dev/debug strings
	:X:`;`;`;::NotepadPlusPlus.sendAHKFunctionHeader()                 ; Function header
	:X:dbpop::NotepadPlusPlus.sendDebugCodeString("DEBUG.popup")       ; Debug popup
	:X:dbto::NotepadPlusPlus.sendDebugCodeString("DEBUG.toast")        ; Debug toast
	:X:edbpop::NotepadPlusPlus.sendDebugCodeString("DEBUG.popupEarly") ; Debug popup that appears at startup
	:X:dbparam::NotepadPlusPlus.insertDebugParams()                    ; Debug parameters
#If
	
class NotepadPlusPlus {

; ==============================
; == Public ====================
; ==============================
	;---------
	; DESCRIPTION:    Insert a newline at the cursor, indented to the same level as the current line.
	;                 Also takes AHK headers into account, indenting to the proper level if you're
	;                 within one.
	;---------
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
		
		numSpaces := NotepadPlusPlus.getDocumentationLineIndent(lineStart)
		
		Send, {Enter} ; Start the new line - assuming that Notepad++ will put us at the same indentation level (before the semicolon) as the previous row.
		Send, % ";" getSpaces(numSpaces)
	}
	
	;---------
	; DESCRIPTION:    Send a debug code string using the given function name, prompting the user for
	;                 the list of parameters to use (in "varName",varName parameter pairs).
	; PARAMETERS:
	;  functionName (I,REQ) - Name of the function to send before the parameters.
	;---------
	sendDebugCodeString(functionName) {
		if(functionName = "")
			return
		
		varList := InputBox("Enter variables to send debug string for", , , 500, 100, , , , , clipboard)
		if(ErrorLevel) ; Popup was cancelled or timed out
			return
		
		if(varList = "") {
			SendRaw, % functionName "()"
			Send, {Left} ; Get inside parens for user to enter the variables/labels themselves
		} else {
			SendRaw, % functionName "(" NotepadPlusPlus.generateDebugParams(varList) ")"
		}
	}
	
	;---------
	; DESCRIPTION:    Generate and insert debug parameters, prompting the user for which variables
	;                 to include.
	;---------
	insertDebugParams() {
		varList := clipboard
		if(!varList)
			return
		
		Send, % NotepadPlusPlus.generateDebugParams(varList)
	}
	
	;---------
	; DESCRIPTION:    Insert an AHK function header based on the function defined on the line below
	;                 the cursor.
	; SIDE EFFECTS:   Selects the line below in order to process the parameters.
	;---------
	sendAHKFunctionHeader() {
		; Select the following line after this one to get parameter information
		Send, {Down}
		selectCurrentLine()
		functionDefLine := cleanupText(getSelectedText())
		Send, {Up}
		
		; Check for parameters
		paramsList := getFirstStringBetweenStr(functionDefLine, "(", ")")
		if(paramsList = "") {
			; No parameters, just send the basic base
			SendRaw, % NotepadPlusPlus.ahkHeaderBase
			return
		}
		
		; Build array of parameter names, cleaning off ByRef and defaults
		paramsAry := []
		maxParamLength := 0
		For _,param in strSplit(paramsList, ",", " `t") {
			param := removeStringFromStart(param, "ByRef ")
			param := getStringBeforeStr(param, " :=")
			
			paramsAry.push(param)
			maxParamLength := max(maxParamLength, strLen(param))
		}
		
		; Build a line for each parameter, padding things out to make them even
		paramLines := []
		For _,paramName in paramsAry {
			line := NotepadPlusPlus.ahkParamBase
			line := replaceTag(line, "NAME",    paramName)
			line := replaceTag(line, "PADDING", getSpaces(maxParamLength - strLen(paramName)))
			paramLines.push(line)
		}
		
		header := NotepadPlusPlus.ahkHeaderBaseWithParams
		header := replaceTag(header, "PARAMETERS", paramLines.join("`n"))
		SendRaw, % header
	}
	
	
; ==============================
; == Private ===================
; ==============================
	; AHK headers bases
	static ahkHeaderBase := "
		( RTrim0
		;---------
		; DESCRIPTION:    
		; RETURNS:        
		; SIDE EFFECTS:   
		; NOTES:          
		;---------
		)"
	
	static ahkHeaderBaseWithParams := "
		( RTrim0
		;---------
		; DESCRIPTION:    
		; PARAMETERS:
		<PARAMETERS>
		; RETURNS:        
		; SIDE EFFECTS:   
		; NOTES:          
		;---------
		)"
	
	static ahkParamBase := "
		( RTrim0
		;  <NAME><PADDING> (I/O/IO,REQ/OPT) - 
		)"
	
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
		matchedPos := stringMatchesAnyOf(line, keywords, CONTAINS_ANY, matchedKeyword)
		if(matchedPos) {
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
	; DESCRIPTION:    Generate a list of parameters for the DEBUG.popup/DEBUG.toast functions,
	;                 in "varName",varName pairs.
	; PARAMETERS:
	;  varList (I,REQ) - Comma-separated list of parameters to generate the debug parameters for.
	; RETURNS:        Comma-separated list of parameters, spaced in pairs, of "varName",varName.
	;                 Example:
	;                 	Input: var1,var2
	;                 	Output: "var1",var1, "var2",var2
	;---------
	generateDebugParams(varList) {
		paramsAry := StrSplit(varList, ",", A_Space) ; Split on comma and drop leading/trailing spaces
		; DEBUG.toast("paramsAry",paramsAry)
		
		paramsString := ""
		For i,param in paramsAry {
			if(i > 1)
				paramsString .= ", "
			paramsString .= """" param """" "," param
		}
		
		return paramsString
	}
}
