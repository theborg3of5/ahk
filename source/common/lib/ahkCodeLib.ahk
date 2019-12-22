; Functions related to editing AHK scripts and their documentation.

class AHKCodeLib {
	; #PUBLIC#
	
	static SPACES_PER_TAB := 3 ; How many spaces are treated as a tab for indentation purposes.
	
	;---------
	; DESCRIPTION:    Generate a documentation header based on the definition line provided.
	; PARAMETERS:
	;  defLine (I,REQ) - The definition line for the function to document, with the name and parameters.
	; RETURNS:        The full text of the documentation header to insert.
	;---------
	getDocHeader(defLine) {
		; Determine if it's a function/property or just a class member.
		if(defLine.containsAnyOf(["(", "[", ":="], match)) {
			if(match = ":=") ; We found the equals before any opening paren/bracket
				return AHKCodeLib.HeaderBase_Member ; No parameters/return value/side effects => basic member base.
		}
		
		; Check for parameters
		AHKCodeLib.getDefLineParts(defLine, name, paramsAry)
		if(paramsAry.count() = 0)
			return AHKCodeLib.HeaderBase_Function ; No parameters => basic function base
		
		; Build array of parameter info
		paramInfos := []
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
			
			paramInfos.push({"NAME":param, "IN_OUT":inOut, "REQUIREMENT":requirement})
			
			; Also track the max length of any parameter name so we can space things out appropriately.
			DataLib.updateMax(maxParamLength, param.length())
		}
		
		; Build a line for each parameter, padding things out to make them even
		paramLines := []
		For _,paramObj in paramInfos {
			line := AHKCodeLib.HeaderBase_SingleParam
			
			padding := StringLib.getSpaces(maxParamLength - paramObj["NAME"].length())
			
			line := line.replaceTag("NAME",        paramObj["NAME"])
			line := line.replaceTag("IN_OUT",      paramObj["IN_OUT"])
			line := line.replaceTag("REQUIREMENT", paramObj["REQUIREMENT"])
			line := line.replaceTag("PADDING",     padding)
			
			paramLines.push(line)
		}
		
		header := AHKCodeLib.HeaderBase_FunctionWithParams
		return header.replaceTag("PARAMETERS", paramLines.join("`n"))
	}
	
	;---------
	; DESCRIPTION:    Extract the relevant information from a definition line.
	; PARAMETERS:
	;  defLine   (I,REQ) - The definition line for the function to document, with the name and parameters.
	;  name      (O,OPT) - The name of the function/property/member.
	;  paramsAry (O,OPT) - If the function/property has parameters, this is an array of them,
	;                      including any "ByRef" or default values.
	;---------
	getDefLineParts(defLine, ByRef name := "", ByRef paramsAry := "") {
		; Trim off any indentation and the static modifier if it's there - we don't care here.
		defLine := defLine.withoutWhitespace()
		defLine := defLine.removeFromStart("static ")
		
		lineType := AHKCodeLib.getDefLineType(defLine)
		if(lineType = "FUNCTION") {
			name := defLine.beforeString("(")
			paramsList := defLine.firstBetweenStrings("(", ")")
		
		} else if(lineType = "PROPERTY") {
			name := defLine.beforeString("[")
			if(defLine.contains("["))
			paramsList := defLine.firstBetweenStrings("[", "]")
		
		} else if(lineType = "OTHER") {
			name := defLine.beforeString(" ") ; First space, before any brackets (for properties) or default values (for members).
			paramsList := ""
		}
		
		paramsAry := AHKCodeLib.splitVarList(paramsList)
	}
	
	;---------
	; DESCRIPTION:    Figure out how much indentation is needed for the next line of documentation,
	;                 based on the current line.
	; PARAMETERS:
	;  line            (I,REQ) - The line that we're trying to determine indentation after.
	;  numExtraIndents (I,OPT) - How many extra indents to do versus the start of the current line.
	;                            Defaults to 0 (same level as the current line).
	; RETURNS:        The indentation to use:
	;                    ";"
	;                    align with previous line
	;                    extra indents
	;                    bullet and trailing space if previous line had it
	;---------
	getNextDocLineIndent(line, numExtraIndents) {
		line := line.clean() ; Drop (and ignore) any leading/trailing whitespace and odd characters
		line := line.removeFromStart(";") ; Trim off the starting comment char
		
		; Leading spaces after the comment
		numSpaces := StringLib.countLeadingSpaces(line)
		line := line.withoutWhitespace()
		
		; Add in any extra indents
		numSpaces += numExtraIndents * this.SPACES_PER_TAB
		
		; Keyword line
		if(line.startsWithAnyOf(this.HeaderKeywords, matchedKeyword)) {
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
	
	; All of the keywords possibly contained in the documentation header - should be kept up to date with HeaderBase* constants below.
	static HeaderKeywords := ["DESCRIPTION:", "PARAMETERS:", "RETURNS:", "SIDE EFFECTS:", "NOTES:"]
	
	; Header bases
	static HeaderBase_Member := "
		( LTrim RTrim0
			;---------
			; DESCRIPTION:    
			; NOTES:          
			;---------
		)"
	static HeaderBase_Function := "
		( LTrim RTrim0
			;---------
			; DESCRIPTION:    
			; RETURNS:        
			; SIDE EFFECTS:   
			; NOTES:          
			;---------
		)"
	static HeaderBase_FunctionWithParams := "
		( LTrim RTrim0
			;---------
			; DESCRIPTION:    
			; PARAMETERS:
			<PARAMETERS>
			; RETURNS:        
			; SIDE EFFECTS:   
			; NOTES:          
			;---------
		)"
	static HeaderBase_SingleParam := "
		( LTrim RTrim0
			;  <NAME><PADDING> (<IN_OUT>,<REQUIREMENT>) - 
		)"
	
	;---------
	; DESCRIPTION:    Determine what kind of line the given definition line is.
	; PARAMETERS:
	;  defLine (I,REQ) - The line to check.
	; RETURNS:        "FUNCTION" - Functions
	;                 "PROPERTY" - Properties with square brackets
	;                 "OTHER"    - Members or properties without square brackets
	;---------
	getDefLineType(defLine) {
		; Member with a default value
		if(defLine.containsAnyOf(["(", "[", ":="], match)) {
			if(match = ":=") { ; We found the equals before any opening paren/bracket
				return "OTHER"
			}
		}
		
		; Function
		if(defLine.contains("("))
			return "FUNCTION"
		
		; Property with brackets
		if(defLine.contains("["))
			return "PROPERTY"
		
		; Property without parameters or member without a default value
		return "OTHER"
	}
	
	;---------
	; DESCRIPTION:    Manually split up the variable list by comma, so we can keep commas
	;                 parens/quotes intact instead of splitting on them. This also drops any
	;                 leading/trailing whitespace from each variable name.
	; PARAMETERS:
	;  varList (I,REQ) - Comma-separated list of parameters to generate the debug parameters for.
	; RETURNS:        Array of variable names, split on commas.
	;---------
	splitVarList(varList) {
		if(varList = "")
			return []
		
		QUOTE := """" ; Double-quote character
		paramsAry := []
		
		currentName := ""
		openParens := 0
		openQuotes := false
		Loop, Parse, varList
		{
			char := A_LoopField
			
			; Track open parens/quotes.
			if(char = "(")
				openParens++
			if(char = ")")
				openParens--
			if(char = QUOTE)
				openQuotes := !openQuotes ; Quotes close other quotes, so just swap between open and closed
			
			; Split on commas, but only if there are no open parens or quotes.
			if(char = "," && openParens = 0 && !openQuotes) {
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
