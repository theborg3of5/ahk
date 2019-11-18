; Functions related to editing AHK scripts and their documentation.
; GDB TODO: Update auto-complete and syntax highlighting notepad++ definitions
; GDB TODO: update all function headers

class AHKCodeLib {
	; #PUBLIC#
	
	; insertIndentedNewline() { => getNextDocLineIndent(line)*
	; sendDebugCodeString(functionName) {
	; insertDebugParams() { => generateDebugParams(varList)
	; sendAHKHeader() { => getDocHeader(defLine)
	; sendAHKClassTemplate() {
	
	;---------
	; DESCRIPTION:    Insert a function header based on the function defined on the line below
	;                 the cursor.
	; SIDE EFFECTS:   Selects the line below in order to process the parameters.
	;---------
	getDocHeader(defLine := "") {
		; Determine if it's a function/property or just a class member.
		equalsPos := defLine.contains(":=")
		if(defLine.containsAnyOf(["(", "[", ":="], match)) {
			if(match = ":=") ; We found the equals before any opening paren/bracket
				return AHKCodeLib.headerBase_Member ; No parameters/return value/side effects => basic member base.
		}
		
		; Check for parameters
		AHKCodeLib.getDefLineParts(defLine, name, paramsAry)
		if(paramsAry.count() = 0)
			return AHKCodeLib.headerBase_Function ; No parameters => basic function base
		
		; Build array of parameter info
		paramLines := []
		maxParamLength := 0
		For _,param in paramsAry {
			; Input/output can be partially deduced by whether it's ByRef
			if(param.startsWith("ByRef ")) {
				inOut := "I/O" ; Could be either
				param := param.removeFromStart("ByRef ")
			} else {
				inOut := "I" ; Can only be input
			}
			
			; Required/optional can be deduced by whether there's a default specified
			if(param.contains(" := ")) {
				requirement := "OPT" ; Optional if there's a default
				param := param.beforeString(" :=")
			} else {
				requirement := "REQ" ; Required if no default
			}
			
			paramLines.push({"NAME":param, "IN_OUT":inOut, "REQUIREMENT":requirement})
			
			; Also track the max length of any parameter name so we can space things out appropriately.
			DataLib.updateMax(maxParamLength, param.length())
		}
		
		; Build a line for each parameter, padding things out to make them even
		paramLines := []
		For _,paramObj in paramLines {
			line := AHKCodeLib.paramBase
			
			padding := StringLib.getSpaces(maxParamLength - paramObj["NAME"].length())
			
			line := line.replaceTag("NAME",        paramObj["NAME"])
			line := line.replaceTag("IN_OUT",      paramObj["IN_OUT"])
			line := line.replaceTag("REQUIREMENT", paramObj["REQUIREMENT"])
			line := line.replaceTag("PADDING",     padding)
			
			paramLines.push(line)
		}
		
		header := AHKCodeLib.headerBase_FunctionWithParams
		return header.replaceTag("PARAMETERS", paramLines.join("`n"))
	}
	

	getDefLineParts(defLine, ByRef name := "", ByRef paramsAry := "") {
		; Trim off the static modifier if it's there - we don't care here.
		defLine := defLine.removeFromStart("static ")
		
		; Function
		if(defLine.contains("(")) {
			name := defLine.beforeString("(")
			paramsList := defLine.firstBetweenStrings("(", ")")
		
		; Property with brackets
		} else if(defLine.contains("[")) {
			name := defLine.beforeString("[")
			paramsList := defLine.firstBetweenStrings("[", "]")
		
		; Property without brackets or other member
		} else {
			name := defLine.beforeString(" ") ; First space, before any brackets {properties} or values (members).
			paramsList := ""
		}
		
		paramsAry := AHKCodeLib.splitVarList(paramsList)
	}
	
	
	;---------
	; DESCRIPTION:    Figure out how much indentation is needed for the next line of documentation,
	;                 based on the current line.
	; PARAMETERS:
	;  line (I,REQ) - The line that we're trying to determine indentation after.
	; RETURNS:        The indentation to use:
	;                  If bullets: ";" + indentation + bullet + " "
	;                  Otherwise: ";" + indentation
	;---------
	getNextDocLineIndent(line) {
		line := line.clean() ; Drop (and ignore) any leading/trailing whitespace and odd characters
		line := line.removeFromStart(";") ; Trim off the starting comment char
		
		; Leading spaces after the comment
		numSpaces := StringLib.countLeadingSpaces(line)
		line := line.withoutWhitespace()
		
		; Keyword line
		if(line.startsWithAnyOf(this.headerKeywords, matchedKeyword)) {
			; Add length of keyword + however many spaces are after it.
			numSpaces += matchedKeyword.length()
			line := line.removeFromStart(matchedKeyword)
			numSpaces += StringLib.countLeadingSpaces(line)
			
			return ";" StringLib.getSpaces(numSpaces)
		}
		
		; Parameter line - add the position of the "(I,REQ) - "-style description - 1 + its length.
		paramTypePos := line.containsRegEx("P)\((I|O|IO),(OPT|REQ)\) - ", matchedTextLen)
		if(paramTypePos) {
			paramNameLength := paramTypePos - 1 ; Includes the space between the name and the type as well
			numSpaces += paramNameLength + matchedTextLen
			
			return ";" StringLib.getSpaces(numSpaces)
		}
		
		; Line that starts with some sort of bullet - include the bullet in the next line.
		bullets := ["*", "-"]
		if(line.startsWithAnyOf(bullets, matchedBullet)) {
			return ";" StringLib.getSpaces(numSpaces) matchedBullet " "
		}
		
		; Floating line - just the same spaces we stripped off at the start.
		return ";" StringLib.getSpaces(numSpaces)
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
		if(varList = "")
			return ""
		
		paramsString := ""
		QUOTE := """" ; Double-quote character
		
		; Split list into array
		paramsAry := AHKCodeLib.splitVarList(varList)
		
		; Special case: if first param starts with +, it's a top-level message that should be shown with no corresponding data.
		if(paramsAry[1].startsWith("+")) {
			label := paramsAry[1].afterString("+")
			paramsString .= QUOTE label QUOTE ","
			paramsAry.RemoveAt(1)
		}
		
		For i,param in paramsAry {
			label := StringLib.escapeCharUsingChar(param, QUOTE, QUOTE)
			paramPair := QUOTE label QUOTE "," param
			paramsString := paramsString.appendPiece(paramPair, ", ")
		}
		
		return paramsString
	}
	
	; #PRIVATE#
	
	; All of the keywords possibly contained in the documentation header - should be kept up to date with headerBase* members below.
	static headerKeywords := ["DESCRIPTION:", "PARAMETERS:", "RETURNS:", "SIDE EFFECTS:", "NOTES:"]
	
	; Header bases
	static headerBase_Member := "
		( RTrim0
		;---------
		; DESCRIPTION:    
		; NOTES:          
		;---------
		)"
	static headerBase_Function := "
		( RTrim0
		;---------
		; DESCRIPTION:    
		; RETURNS:        
		; SIDE EFFECTS:   
		; NOTES:          
		;---------
		)"
	static headerBase_FunctionWithParams := "
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
	static paramBase := "
		( RTrim0
		;  <NAME><PADDING> (<IN_OUT>,<REQUIREMENT>) - 
		)"
	
	;---------
	; DESCRIPTION:    Manually split up the variable list by comma, so we can keep commas
	;                 parens/quotes intact instead of splitting on them. This also drops any
	;                 leading/trailing whitespace from each variable name.
	; PARAMETERS:
	;  varList (I,REQ) - Comma-separated list of parameters to generate the debug parameters for.
	; RETURNS:        Array of variable names, split on commas.
	;---------
	splitVarList(varList) {
		QUOTE := """" ; Double-quote character
		paramsAry := []
		
		currentName := ""
		openParens := 0
		openQuotes := 0
		Loop, Parse, varList
		{
			char := A_LoopField
			
			; Track open parens/quotes.
			if(char = "(")
				openParens++
			if(char = ")")
				openParens--
			if(char = QUOTE)
				openQuotes := mod(openQuotes + 1, 2) ; Quotes close other quotes, so just swap between open and closed
			
			; Split on commas, but only if there are no open parens or quotes.
			if(char = "," && openParens = 0 && openQuotes = 0) {
				paramsAry.push(currentName.withoutWhitespace())
				currentName := ""
				Continue
			}
			
			currentName .= char
		}
		paramsAry.push(currentName.withoutWhitespace())
		
		return paramsAry
	}
	
	; #END#
}
