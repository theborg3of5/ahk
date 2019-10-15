#If Config.isWindowActive("Notepad++")
	!x::return ; Block close-document hotkey that can't be changed/removed.
	^+t::Send, !f1 ; Re-open last closed document.
	!f::Send, ^+!f ; Use !f hotkey for highlighting with the first style (ControlSend so we don't trigger other hotkeys)
	
	; Copy current file/folder to clipboard.
	!c::copyFilePathWithHotkey("!c")
	!#c::copyFolderPathWithHotkey("^!c")
	
	^Enter::NotepadPlusPlus.insertIndentedNewline() ; Add an indented newline
	
	; Insert various AHK dev/debug strings
	:X:`;`;`;::NotepadPlusPlus.sendAHKFunctionHeader()                 ; Function header
	:X:dbpop::NotepadPlusPlus.sendDebugCodeString("Debug.popup")       ; Debug popup
	:X:dbto::NotepadPlusPlus.sendDebugCodeString("Debug.toast")        ; Debug toast
	:X:edbpop::NotepadPlusPlus.sendDebugCodeString("Debug.popupEarly") ; Debug popup that appears at startup
	:X:dbparam::NotepadPlusPlus.insertDebugParams()                    ; Debug parameters
	:X:dbm::SendRaw, % "MsgBox, % "
	
	:X:.ahkclass::NotepadPlusPlus.sendAHKClassTemplate()
#If
	
class NotepadPlusPlus {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
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
		if(lineStart.endsWith(A_Space))
			Send, {Backspace}
		if(lineEnd.startsWith(A_Space))
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
		functionDefLine := getSelectedText().clean()
		Send, {Up}
		
		; Check for parameters
		paramsList := functionDefLine.firstBetweenStrings("(", ")")
		if(paramsList = "") {
			; No parameters, just send the basic base
			SendRaw, % NotepadPlusPlus.ahkHeaderBase
			return
		}
		
		; Build array of parameter names, cleaning off ByRef and defaults
		paramsAry := []
		maxParamLength := 0
		For _,param in paramsList.split(",", " `t") {
			param := param.removeFromStart("ByRef ")
			param := param.beforeString(" :=")
			
			paramsAry.push(param)
			maxParamLength := max(maxParamLength, param.length())
		}
		
		; Build a line for each parameter, padding things out to make them even
		paramLines := []
		For _,paramName in paramsAry {
			line := NotepadPlusPlus.ahkParamBase
			line := line.replaceTag("NAME",    paramName)
			line := line.replaceTag("PADDING", getSpaces(maxParamLength - paramName.length()))
			paramLines.push(line)
		}
		
		header := NotepadPlusPlus.ahkHeaderBaseWithParams
		header := header.replaceTag("PARAMETERS", paramLines.join("`n"))
		SendRaw, % header
	}
	
	;---------
	; DESCRIPTION:    Insert a template of an AHK class (read from a template file) at the cursor.
	;---------
	sendAHKClassTemplate() {
		templateString := FileRead(Config.path["AHK_TEMPLATE"] "\class.ahk")
		if(!templateString) {
			new ErrorToast("Could not insert AHK class template", "Could not read template file").showMedium()
			return
		}
		
		sendTextWithClipboard(templateString)
	}
	
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
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
		line := line.clean() ; Drop (and ignore) any leading/trailing whitespace and odd characters
		line := line.removeFromStart("; ") ; Trim off the starting comment char + space
		numSpaces := 1 ; Space we just trimmed off
		
		keywords := ["DESCRIPTION:", "PARAMETERS:", "RETURNS:", "SIDE EFFECTS:", "NOTES:"]
		matchedPos := line.containsAnyOf(keywords, matchedKeyword)
		if(matchedPos) {
			; Keyword line - add length of keyword + however many spaces are after it.
			numSpaces += matchedKeyword.length()
			line := line.removeFromStart(matchedKeyword)
			numSpaces += countLeadingSpaces(line)
		} else {
			matchedPos := line.containsRegEx("P)\((I|O|IO),(OPT|REQ)\) - ", matchedTextLen)
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
	; DESCRIPTION:    Generate a list of parameters for the Debug.popup/Debug.toast functions,
	;                 in "varName",varName pairs.
	; PARAMETERS:
	;  varList (I,REQ) - Comma-separated list of parameters to generate the debug parameters for.
	; RETURNS:        Comma-separated list of parameters, spaced in pairs, of "varName",varName.
	;                 Example:
	;                 	Input: var1,var2
	;                 	Output: "var1",var1, "var2",var2
	;---------
	generateDebugParams(varList) {
		paramsString := ""
		paramsAry := varList.split(",", A_Space) ; Split on comma and drop leading/trailing spaces
		QUOTE := """" ; Double-quote character
		
		; Special case: if first param starts with +, it's a top-level message that should be shown with no corresponding data.
		if(paramsAry[1].startsWith("+")) {
			label := paramsAry[1].afterString("+")
			paramsString .= QUOTE label QUOTE ","
			paramsAry.RemoveAt(1)
		}
		
		For i,param in paramsAry {
			label := QUOTE escapeCharUsingRepeat(param, QUOTE) QUOTE
			paramsString := paramsString.appendPiece(label "," param, ", ")
		}
		
		return paramsString
	}
}
