; Functions related to editing AHK scripts and their documentation.

class AHKCodeLib {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    How many spaces are treated as a tab for indentation purposes.
	;---------
	static SPACES_PER_TAB := 3
	
	;---------
	; DESCRIPTION:    All of the keywords possibly contained in the documentation header, in the order they should be shown in.
	; NOTES:          NPP-* and GROUP are used for auto-completion/syntax highlighting generation
	;---------
	static HeaderKeywords := ["DESCRIPTION", "PARAMETERS", "RETURNS", "SIDE EFFECTS", "NOTES", "GROUP", "NPP-DEF-LINE", "NPP-RETURNS"]
	
	;---------
	; DESCRIPTION:    Generate a documentation header based on the definition line provided.
	; PARAMETERS:
	;  defLine (I,REQ) - The definition line for the function to document, with the name and parameters.
	; RETURNS:        The full text of the documentation header to insert.
	;---------
	generateDocHeader(defLine) {
		; Determine if it's a function/property or just a class member.
		if(defLine.containsAnyOf(["(", "[", ":="], match)) {
			if(match = ":=") ; We found the equals before any opening paren/bracket
				return this.generateHeaderWithParts({"DESCRIPTION":"", "NOTES":""})
		}
		
		; Get parameter info
		AHKCodeLib.getDefLineParts(defLine, "", paramsAry)
		paramInfos := []
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
		}
		
		return AHKCodeLib.generateHeaderWithParts({"DESCRIPTION":"", "RETURNS":"", "SIDE EFFECTS":"", "NOTES": ""}, paramInfos)
	}
	
	;---------
	; DESCRIPTION:    Generate an AHK documentation header based on the given keyword:value pairs.
	; PARAMETERS:
	;  parts     (I,REQ) - An associative array of {KEYWORD: VALUE}
	;  paramsAry (I,OPT) - An array of objects with parameter info. We'll add these to the header
	;                      regardless of whether a "PARAMETERS" keyword is found in the parts
	;                      parameter. Format per element:
	;                       {"NAME":name, "IN_OUT":I/O/IO, "REQUIREMENT":REQ/OPT}
	; RETURNS:        The generated header as a string
	;---------
	generateHeaderWithParts(parts, paramsAry := "") {
		header := ";---------"
		For _,keyword in AHKCodeLib.HeaderKeywords { ; Go in order of this list of keywords
			; Only include keywords from the parts parameter (except for the PARAMETERS keyword, which should only be included if paramsAry is given)
			if(! (parts.hasKey(keyword) || (keyword = "PARAMETERS" && !DataLib.isNullOrEmpty(paramsAry))) )
				Continue
			
			if(keyword = "PARAMETERS") {
				header .= "`n; PARAMETERS:"
				
				; First figure out the longest parameter name so we can pad the others out appropriately.
				maxParamLength := 0
				For _,paramInfo in paramsAry
					DataLib.updateMax(maxParamLength, paramInfo["NAME"].length())
				
				; Add a line for each parameter
				For _,paramInfo in paramsAry {
					padding := StringLib.getSpaces(maxParamLength - paramInfo["NAME"].length())
					
					line := AHKCodeLib.HeaderSingleParamBase
					line := line.replaceTags(paramInfo)
					line := line.replaceTag("PADDING", padding)
					
					header .= "`n" line
				}
			} else {
				line := ("; " keyword ":").postPadToLength(AHKCodeLib.HeaderKeywordIndentStop)
				line .= parts[keyword]
				header .= "`n" line
			}
		}
		header .= "`n;---------"
		
		return header
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
		
		Switch AHKCodeLib.getDefLineType(defLine) {
			Case "FUNCTION":
				name := defLine.beforeString("(")
				paramsList := defLine.firstBetweenStrings("(", ")")
			
			Case "PROPERTY":
				name := defLine.beforeString("[")
				if(defLine.contains("["))
				paramsList := defLine.firstBetweenStrings("[", "]")
			
			Case "OTHER":
				name := defLine.beforeString(" ") ; First space, before any brackets (for properties) or default values (for members).
				paramsList := ""
		}
		
		paramsAry := AHKCodeLib.splitVarList(paramsList)
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
			paramsString .= QUOTE label QUOTE "," QUOTE QUOTE
			paramsAry.RemoveAt(1)
		}
		
		For i,param in paramsAry {
			label := StringLib.escapeCharUsingChar(param, QUOTE, QUOTE)
			paramPair := QUOTE label QUOTE "," param
			paramsString := paramsString.appendPiece(paramPair, ", ")
		}
		
		return paramsString
	}
	
	;---------
	; DESCRIPTION:    The reverse the generateDebugParams - take the paired parameters list and turn it back into the
	;                 original parameters the user chose.
	; PARAMETERS:
	;  debugParamList (I,REQ) - The list of paired parameters, originally from generateDebugParams.
	; RETURNS:        A list of the original parameters.
	;---------
	reduceDebugParams(debugParamList) {
		QUOTE := """" ; Double-quote character
		
		; Now get down to our original list by preferring the second of each pair of parameters.
		paramsAry := []
		lastNameParam := ""
		For i,param in AHKCodeLib.splitVarList(debugParamList) {
			; Generally ignore odd-numbered parameters, but store them until we're done with their corresponding even param in case it's a label case.
			if(i.isOddNum()) {
				lastNameParam := param
				Continue
			}
			
			; If the even-numbered parameter is a blank string, it's a label case - use the last name param with a + instead.
			if(param = QUOTE QUOTE) {
				paramsAry.push("+" lastNameParam.allBetweenStrings(QUOTE, QUOTE)) ; Add the + for label, remove the quotes
				Continue
			}
			
			paramsAry.push(param)
		}
		
		return paramsAry.join(",")
	}
	
	
	; #PRIVATE#
	
	static HeaderKeywordIndentStop := 18 ; How many characters over we should be from the start of the line (after indentation) for header values.
	
	; The structure for documenting a single parameter
	static HeaderSingleParamBase := "
		( RTrim0
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
		openParens   := 0
		openBrackets := 0
		openQuotes   := false
		Loop, Parse, varList
		{
			char := A_LoopField
			
			; Track open parens, brackets, and quotes.
			Switch char {
				Case "(":   openParens++
				Case ")":   openParens--
				Case "[":   openBrackets++
				Case "]":   openBrackets--
				Case QUOTE: openQuotes := !openQuotes ; Quotes close other quotes, so just swap between open and closed
			}
			
			; Split on commas, but only if there are no open parens or quotes.
			if(char = "," && openParens = 0 && !openQuotes && !openBrackets) {
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
