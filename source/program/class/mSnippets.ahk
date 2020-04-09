; Static class for inserting snippets of M code into EpicStudio.
class MSnippets {
	; #INTERNAL#
	
	;---------
	; DESCRIPTION:    Generate and insert an M snippet.
	;---------
	insertSnippet() {
		; Get current line for analysis.
		Send, {End}{Home 2}               ; Get to very start of line (before indentation)
		Send, {Shift Down}{End}{Shift Up} ; Select entire line (including indentation)
		line := SelectLib.getText()
		Send, {End}                       ; Get to end of line
		
		line := line.removeFromStart("`t") ; Tab at the start of every line
		
		numIndents := 0
		while(line.startsWith(". ")) {
			numIndents++
			line := line.removeFromStart(". ")
		}
		
		; If it's an empty line with just a semicolon, remove the semicolon.
		if(line = ";")
			Send, {Backspace}
		
		data := new Selector("MSnippets.tls").selectGui()
		Switch data["TYPE"] {
			Case "LOOP": snipString := MSnippets.buildMLoop(data, numIndents)
			Case "LIST": snipString := MSnippets.buildList(data, numIndents)
		}
		
		ClipboardLib.send(snipString) ; Better to send with the clipboard, otherwise we have to deal with EpicStudio adding in dot-levels itself.
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Generate an M for loop with the given data.
	; PARAMETERS:
	;  data       (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          ["SUBTYPE"] - The type of loop this is.
	;  numIndents (I,REQ) - The starting indentation (so that the line after can be indented 1 more).
	; RETURNS:        String containing the generated for loop.
	;---------
	buildMLoop(data, numIndents) {
		loopString := ""
		
		Switch data["SUBTYPE"] {
			Case "ARRAY_GLO":       loopString .= MSnippets.buildMArrayLoop(data, numIndents)
			Case "ID":              loopString .= MSnippets.buildMIdLoop(data, numIndents)
			Case "DAT":             loopString .= MSnippets.buildMDatLoop(data, numIndents)
			Case "ID_DAT":          loopString .= MSnippets.buildMIdLoop(data, numIndents) MSnippets.buildMDatLoop(data, numIndents)
			Case "INDEX_REG_VALUE": loopString .= MSnippets.buildMIndexRegularValueLoop(data, numIndents)
			Case "INDEX_REG_ID":    loopString .= MSnippets.buildMIndexRegularIDLoop(data, numIndents)
		}
		
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate code to populate an array in M with the given values.
	; PARAMETERS:
	;  data       (I,REQ) - Array of data needed to generate the list. Important subscripts:
	;                         ["ARRAY_OR_INI"]   - The name of the array to populate
	;                         ["VARS_OR_VALUES"] - The list of values to add to the array
	;  numIndents (I,REQ) - The starting indentation for the list.
	; RETURNS:        String containing the generated code.
	;---------
	buildList(data, numIndents) {
		Switch data["SUBTYPE"] {
			Case "INDEX": return MSnippets.buildMListIndex(data, numIndents)
		}
	}
	
	;---------
	; DESCRIPTION:    Generate nested M for loops using the given data.
	; PARAMETERS:
	;  data        (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          ["ARRAY_OR_INI"]   - The name of the array or global (with @s around it)
	;                          ["VARS_OR_VALUES"] - Comma-delimited list of iterator variables to loop with.
	;  numIndents (IO,REQ) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMArrayLoop(data, ByRef numIndents) {
		arrayName   := data["ARRAY_OR_INI"]
		iteratorAry := data["VARS_OR_VALUES"].split(",")
		
		if(arrayName.startsWith("@") && !arrayName.endsWith("@"))
			arrayName .= "@" ; End global references with the proper @ if they're not already.
		
		prevIterators := ""
		for i,iterator in iteratorAry {
			loopString .= Config.private["M_LOOP_ARRAY_BASE"].replaceTags({"ARRAY_NAME":arrayName, "ITERATOR":iterator, "PREV_ITERATORS":prevIterators})
			
			prevIterators .= iterator ","
			numIndents++
			loopString .= MSnippets.getMNewLinePlusIndent(numIndents)
		}
		
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over IDs using the given data.
	; PARAMETERS:
	;  data        (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          ["ARRAY_OR_INI"] - The INI of the records to loop through
	;  numIndents (IO,REQ) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMIdLoop(data, ByRef numIndents) {
		ini := stringUpper(data["ARRAY_OR_INI"])
		
		idVar := stringLower(ini) "Id"
		loopString := Config.private["M_LOOP_ID_BASE"].replaceTags({"INI":ini, "ID_VAR":idVar})
		
		numIndents++
		loopString .= MSnippets.getMNewLinePlusIndent(numIndents)
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over DATs using the given data.
	; PARAMETERS:
	;  data        (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          ["ARRAY_OR_INI"] - The INI of the records to loop through
	;  numIndents (IO,REQ) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMDatLoop(data, ByRef numIndents) {
		ini := stringUpper(data["ARRAY_OR_INI"])
		
		idVar  := stringLower(ini) "Id"
		datVar := stringLower(ini) "Dat"
		loopString := Config.private["M_LOOP_DAT_BASE"].replaceTags({"INI":ini, "ID_VAR":idVar, "DAT_VAR":datVar, "ITEM":""})
		
		numIndents++
		loopString .= MSnippets.getMNewLinePlusIndent(numIndents)
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over regular index values for the given data.
	; PARAMETERS:
	;  data        (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          ["ARRAY_OR_INI"]   - The INI of the records to loop through
	;                          ["VARS_OR_VALUES"] - The name of the iterator variable to use for values
	;  numIndents (IO,REQ) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMIndexRegularValueLoop(data, ByRef numIndents) {
		ini := stringUpper(data["ARRAY_OR_INI"])
		valueVar := data["VARS_OR_VALUES"]
		
		loopString := Config.private["M_LOOP_INDEX_REGULAR_NEXT_VALUE"].replaceTags({"INI":ini, "ITEM":"", "VALUE_VAR":valueVar})
		
		numIndents++
		loopString .= MSnippets.getMNewLinePlusIndent(numIndents)
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over regular index IDs with a particular value for the
	;                 given data.
	; PARAMETERS:
	;  data        (I,REQ) - Array of data needed to generate the loop. Important subscripts:
	;                          ["ARRAY_OR_INI"]   - The INI of the records to loop through
	;                          ["VARS_OR_VALUES"] - The name of the iterator variable to use for values
	;  numIndents (IO,REQ) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMIndexRegularIDLoop(data, ByRef numIndents) {
		ini := stringUpper(data["ARRAY_OR_INI"])
		valueVar := data["VARS_OR_VALUES"]
		
		idVar  := stringLower(ini) "Id"
		loopString := Config.private["M_LOOP_INDEX_REGULAR_NEXT_ID"].replaceTags({"INI":ini, "ITEM":"", "VALUE_VAR":valueVar, "ID_VAR":idVar})
		
		numIndents++
		loopString .= MSnippets.getMNewLinePlusIndent(numIndents)
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an indexed [ary(value)=""] array in M code.
	; PARAMETERS:
	;  data       (I,REQ) - Array of data needed to generate the list. Important subscripts:
	;                         ["ARRAY_OR_INI"]   - The name of the array to populate
	;                         ["VARS_OR_VALUES"] - The list of values to add to the array
	;  numIndents (I,REQ) - The starting indentation for the list.
	; RETURNS:        String for generated array
	;---------
	buildMListIndex(data, numIndents) {
		arrayName := data["ARRAY_OR_INI"]
		valueList := data["VARS_OR_VALUES"]
		
		listAry := new FormattedList(valueList).getList(FormattedList.Format_Array)
		
		newLine := MSnippets.getMNewLinePlusIndent(numIndents)
		lineBase := Config.private["M_LIST_ARRAY_INDEX"]
		
		listString := ""
		For _,value in listAry {
			line := lineBase.replaceTags({"ARRAY_NAME":arrayName, "VALUE":value})
			listString := listString.appendPiece(line, newLine)
		}
		
		return listString
	}
	
	;---------
	; DESCRIPTION:    Get the text for a new line in M code.
	; PARAMETERS:
	;  currNumIndents (I,REQ) - The number of indents on the current line.
	; RETURNS:        The string to start a new line with 1 indent more.
	;---------
	getMNewLinePlusIndent(currNumIndents) {
		outString := "`n`t" ; New line + tab (at the start of every line)
		
		; Add indentation
		outString .= ". ".repeat(currNumIndents)
		
		return outString
	}
	; #END#
}