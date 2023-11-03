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
		subType  := data["SUBTYPE"]
		inputAry := data["VARS_AND_VALS"].split(",")

		Switch data["TYPE"] {
			Case "LOOP":  snipString := MSnippets.buildMLoop(subType, inputAry, numIndents)
			Case "ARRAY": snipString := MSnippets.buildArray(subType, inputAry, numIndents)
			Case "WIKI":
				MSnippets.launchWiki(subType)
				return
		}
		
		ClipboardLib.send(snipString) ; Better to send with the clipboard, otherwise we have to deal with EpicStudio adding in dot-levels itself.
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Generate an M for loop with the given data.
	; PARAMETERS:
	;  subType    (I,REQ) - Identifier for the type of loop we're building.
	;  inputAry   (I,REQ) - Array of input data. Subscripts vary per subtype, see sub-functions for details.
	;  numIndents (I,REQ) - The starting indentation (so that the line after can be indented 1 more).
	; RETURNS:        String containing the generated for loop.
	;---------
	buildMLoop(subType, inputAry, numIndents) {
		Switch subType {
			Case "ARRAY_GLO":       return MSnippets.buildMAryGloLoop(           inputAry, numIndents)
			Case "ID":              return MSnippets.buildMIdLoop(               inputAry, numIndents)
			Case "DAT":             return MSnippets.buildMDatLoop(              inputAry, numIndents)
			Case "ID_DAT":          return MSnippets.buildMIdLoop(               inputAry, numIndents) MSnippets.buildMDatLoop(inputAry, numIndents)
			Case "INDEX_REG_VALUE": return MSnippets.buildMIndexRegularValueLoop(inputAry, numIndents)
			Case "INDEX_REG_ID":    return MSnippets.buildMIndexRegularIDLoop(   inputAry, numIndents)
			Case "MULTI_ITEM":      return MSnippets.buildMultiItemLoop(         inputAry, numIndents)
		}
		
		return ""
	}
	
	;---------
	; DESCRIPTION:    Generate code to populate an array in M using the given values.
	; PARAMETERS:
	;  subType    (I,REQ) - Identifier for the type of array we're building.
	;  inputAry   (I,REQ) - Array of input data. Subscripts vary per subtype, see sub-functions for details.
	;  numIndents (I,REQ) - The starting indentation for the list.
	; RETURNS:        String containing the generated code.
	;---------
	buildArray(subType, inputAry, numIndents) {
		Switch subType {
			Case "INDEX": return MSnippets.buildMArrayIndex(  inputAry, numIndents)
			Case "NUM":   return MSnippets.buildMArrayNumeric(inputAry, numIndents)
		}
	}

	;---------
	; DESCRIPTION:    Launch one or more specific wikis.
	; PARAMETERS:
	;  subType (I,REQ) - An identifier for which wikis we should launch.
	;---------
	launchWiki(subType) {
		Switch subType {
			Case "INDEX":
				Run(Config.private["EPIC_WIKI_INDEX_GLOBALS"])
				Run(Config.private["EPIC_WIKI_INDEX_APIS"])
		}
	}
	
	;---------
	; DESCRIPTION:    Generate nested M for loops using the given data.
	; PARAMETERS:
	;  inputAry    (I,REQ) - Array of input data. Expected pieces:
	;                        	[1]  = Array or global name. Global should be prefixed with an @ (and can optionally be followed by one, added automatically if not).
	;                        	[2+] = Names of the iterator variables for each subscript.
	;  numIndents (IO,REQ) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMAryGloLoop(inputAry, ByRef numIndents) {
		arrayGloName := inputAry.RemoveAt(1)
		iteratorAry  := inputAry

		if(arrayGloName.startsWith("@"))
			arrayGloName := arrayGloName.appendIfMissing("@") ; End global references with the proper @ if they're not already.
		
		prevIterators := ""
		for i,iterator in iteratorAry {
			loopString .= Config.private["M_LOOP_ARRAY_BASE"].replaceTags({"ARRAY_NAME":arrayGloName, "ITERATOR":iterator, "PREV_ITERATORS":prevIterators})
			
			prevIterators .= iterator ","
			numIndents++
			loopString .= MSnippets.getMNewLinePlusIndent(numIndents)
		}
		
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over IDs using the given data.
	; PARAMETERS:
	;  inputAry    (I,REQ) - Array of input data. Expected pieces:
	;                        	[1]  = INI
	;                        	[2]  = Name of the ID variable   (optional, defaults to "<ini>Id")
	;  numIndents (IO,REQ) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMIdLoop(inputAry, ByRef numIndents) {
		ini   := inputAry[1]
		idVar := inputAry[2]
		
		ini := stringUpper(ini)
		idVar := idVar  ? idVar  : stringLower(ini) "Id"
		
		loopString := Config.private["M_LOOP_ID_BASE"].replaceTags({"INI":ini, "ID_VAR":idVar})
		
		numIndents++
		loopString .= MSnippets.getMNewLinePlusIndent(numIndents)
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over DATs using the given data.
	; PARAMETERS:
	;  inputAry    (I,REQ) - Array of input data. Expected pieces:
	;                        	[1]  = INI
	;                        	[2]  = Name of the ID variable   (optional, defaults to "<ini>Id")
	;                        	[3]  = Name of the DAT variable  (optional, defaults to "<ini>Dat")
	;                        	[4]  = Item number
	;  numIndents (IO,REQ) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMDatLoop(inputAry, ByRef numIndents) {
		ini    := inputAry[1]
		idVar  := inputAry[2]
		datVar := inputAry[3]
		item   := inputAry[4]

		ini := stringUpper(ini)
		idVar  := idVar  ? idVar  : stringLower(ini) "Id"
		datVar := datVar ? datVar : stringLower(ini) "Dat"
		
		loopString := Config.private["M_LOOP_DAT_BASE"].replaceTags({"INI":ini, "ID_VAR":idVar, "DAT_VAR":datVar, "ITEM":item})
		
		numIndents++
		loopString .= MSnippets.getMNewLinePlusIndent(numIndents)
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over regular index values for the given data.
	; PARAMETERS:
	;  inputAry    (I,REQ) - Array of input data. Expected pieces:
	;                        	[1]  = INI
	;                        	[2]  = Item number
	;                        	[3]  = Name of the value variable (optional, defaults to "val")
	;  numIndents (IO,REQ) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMIndexRegularValueLoop(inputAry, ByRef numIndents) {
		ini       := inputAry[1]
		item      := inputAry[2]
		valueVar  := inputAry[3]

		ini := stringUpper(ini)
		valueVar := valueVar ? valueVar : "val"
		
		loopString := Config.private["M_LOOP_INDEX_REGULAR_NEXT_VALUE"].replaceTags({"INI":ini, "ITEM":item, "VALUE_VAR":valueVar})
		
		numIndents++
		loopString .= MSnippets.getMNewLinePlusIndent(numIndents)
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over regular index IDs with a particular value for the
	;                 given data.
	; PARAMETERS:
	;  inputAry    (I,REQ) - Array of input data. Expected pieces:
	;                        	[1]  = INI
	;                        	[2]  = Item number
	;                        	[3]  = Name of the value variable (optional, defaults to "val")
	;                        	[4]  = Name of the ID variable    (optional, defaults to "<ini>Id")
	;  numIndents (IO,REQ) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMIndexRegularIDLoop(inputAry, ByRef numIndents) {
		ini       := inputAry[1]
		item      := inputAry[2]
		valueVar  := inputAry[3]
		idVar     := inputAry[4]
		
		ini := stringUpper(ini)
		valueVar := valueVar ? valueVar : "val"
		idVar    := idVar    ? idVar    : stringLower(ini) "Id"

		loopString := Config.private["M_LOOP_INDEX_REGULAR_NEXT_ID"].replaceTags({"INI":ini, "ITEM":item, "VALUE_VAR":valueVar, "ID_VAR":idVar})
		
		numIndents++
		loopString .= MSnippets.getMNewLinePlusIndent(numIndents)
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an M for loop over a multi-response item.
	; PARAMETERS:
	;  inputAry    (I,REQ) - Array of input data. Expected pieces:
	;                        	[1]  = INI
	;                        	[2]  = Item number
	;                        	[3]  = Name of the ID variable   (optional, defaults to "<ini>Id")
	;                        	[4]  = Name of the DAT variable  (optional, defaults to "<ini>Dat")
	;                        	[5]  = Name of the line variable (optional, defaults to "ln")
	;  numIndents (IO,REQ) - The starting indentation for the loop. Will be updated as we add nested
	;                        loops, final value is 1 more than the last loop.
	; RETURNS:        String for the generated loop
	;---------
	buildMultiItemLoop(inputAry, ByRef numIndents) {
		ini       := inputAry[1]
		item      := inputAry[2]
		idVar     := inputAry[3]
		datVar    := inputAry[4]
		lnVar     := inputAry[5]
		
		ini := stringUpper(ini)
		idVar  := idVar  ? idVar  : stringLower(ini) "Id"
		datVar := datVar ? datVar : stringLower(ini) "Dat"
		lnVar  := lnVar  ? lnVar  : "ln"

		loopString := Config.private["M_LOOP_MULTI_ITEM"].replaceTags({"INI":ini, "ITEM":item, "ID_VAR":idVar, "DAT_VAR":datVar, "LINE_VAR":lnVar})
		numIndents++
		loopString .= MSnippets.getMNewLinePlusIndent(numIndents)
		loopString .= Config.private["M_GETI"].replaceTags({"INI":ini, "ITEM":item, "ID_VAR":idVar, "DAT_VAR":datVar, "LINE_VAR":lnVar})
		
		return loopString
	}
	
	;---------
	; DESCRIPTION:    Generate an indexed [ary(value)=value] array in M code.
	; PARAMETERS:
	;  inputAry    (I,REQ) - Array of input data. Expected pieces:
	;                        	[1]  = Array or global name. Global should be prefixed with an @ (and can optionally be followed by one, added automatically if not).
	;                        	[2]  = Value to store under each index.
	;                        	[3+] = Indices to store in the array. Can include ranges (see DataLib.expandList).
	;  numIndents (IO,REQ) - The starting indentation for the array.
	; RETURNS:        String for generated array
	;---------
	buildMArrayIndex(inputAry, ByRef numIndents) {
		arrayGloName := inputAry.RemoveAt(1)
		value        := inputAry.RemoveAt(1)
		indexList    := inputAry.join(",")

		QUOTE := """"

		if(arrayGloName.startsWith("@"))
			arrayGloName := arrayGloName.appendIfMissing("@") ; End global references with the proper @ if they're not already.
		if(!value.isNum())
			value := QUOTE value QUOTE ; Wrap non-numeric values in quotes.
		indexAry := new FormattedList(indexList).getList(FormattedList.Format_Array) ; This handles expanding ranges and the like.
		
		lineBase := Config.private["M_SET_ARRAY_LINE"]
		newLine := MSnippets.getMNewLinePlusIndent(numIndents)
		
		aryString := ""
		For _,index in indexAry {
			if(!index.isNum())
				index := QUOTE index QUOTE ; Wrap non-numeric indices in quotes.
			line := lineBase.replaceTags({"ARRAY_NAME":arrayGloName, "INDEX":index, "VALUE":value})
			aryString := aryString.appendPiece(newLine, line)
		}
		
		return aryString
	}

	;---------
	; DESCRIPTION:    Generate a numeric [ary(ln)=value] array in M code.
	; PARAMETERS:
	;  inputAry    (I,REQ) - Array of input data. Expected pieces:
	;                        	[1]  = Array or global name. Global should be prefixed with an @ (and can optionally be followed by one, added automatically if not).
	;                        	[2+] = Values to store in the array. Can include ranges (see DataLib.expandList).
	;  numIndents (IO,REQ) - The starting indentation for the array.
	; RETURNS:        String for generated array
	;---------
	buildMArrayNumeric(inputAry, ByRef numIndents) {
		arrayGloName := inputAry.RemoveAt(1)
		valuesList   := inputAry.join(",")

		QUOTE := """"

		if(arrayGloName.startsWith("@"))
			arrayGloName := arrayGloName.appendIfMissing("@") ; End global references with the proper @ if they're not already.
		valuesAry := new FormattedList(valuesList).getList(FormattedList.Format_Array) ; This handles expanding ranges and the like.
		
		lineBase := Config.private["M_SET_ARRAY_LINE"]
		newLine := MSnippets.getMNewLinePlusIndent(numIndents)
		
		aryString := lineBase.replaceTags({"ARRAY_NAME":arrayGloName, "INDEX":0, "VALUE":valuesAry.length()})
		For ln,value in valuesAry {
			if(!value.isNum())
				value := QUOTE value QUOTE ; Wrap non-numeric values in quotes.
			line := lineBase.replaceTags({"ARRAY_NAME":arrayGloName, "INDEX":ln, "VALUE":value})
			aryString := aryString.appendPiece(newLine, line)
		}
		
		return aryString
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
