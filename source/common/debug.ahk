; Debugger object and functions.

class DEBUG {
	static spacesPerTab := 6
	
	; Input in any number of pairs of (label, value), in that order. They will be formatted as described in DEBUG.buildDebugString.
	popup(params*) {
		; Convert params array into array of (label, value) pairs.
		pairedParams := []
		i := 1
		while(i <= params.length()) {
			; MsgBox, % "Label`n`t" params[i] "`nValue:`n`t" params[i + 1])
			pairedParams.Push([params[i], params[i + 1]])
			i += 2
		}
		; MsgBox, % pairedParams[1][1] "`n" pairedParams[1][2]
		
		MsgBox, % this.buildDebugPopup(pairedParams)
	}

	; Given any number of pairs of (label, value), build a debug popup.
	; Parameters:
	;  params  - Array of (label, value) arrays.
	;  numTabs - Number of tabs to indent label part of each pair by. Values will be indented by numTabs+1.
	buildDebugPopup(params, numTabs = 0) {
		outStr := ""
		
		For i,p in params
			outStr .= this.buildDebugString(p[1], p[2], numTabs) "`n"
		
		return outStr
	}
	
	; Puts together a string in the form:
	; 
	; label1:
	;        value1
	; label2:
	;        value2
	; 
	; Parameters:
	;  label         - Label to show the value with
	;  value         - Value to show. If this is an object, we will call into DEBUG.buildObjectString() for a more complete description.
	;  numTabs       - Number of tabs of indentation to start at. Value will be indented by numTabs+1.
	;  labelSameLine - If set to true, we won't put a newline and indentation between the label and value, only a space.
	buildDebugString(label, value, numTabs = 0, labelSameLine = false) {
		outStr := ""
		
		; Label
		outStr .= getTabs(numTabs, DEBUG.spacesPerTab) label ": "
		
		; More complex case - call recusive object function.
		if(isObject(value)) {
			outStr .= this.buildObjectString(value, numTabs, "", true)
		
		; Simple string or numeric value - just put it into place and return, we're done.
		} else {
			if(!labelSameLine)
				outStr .= "`n" getTabs(numTabs + 1, DEBUG.spacesPerTab)
			outStr .= value
		}
		
		outStr .= "`n"
		
		return outStr
	}
	
	; Puts together a string describing the value given.
	; 
	; Relevant special properties of objects:
	;  value.debugName - Rather than the generic "Array", text will contain {value.debugName}.
	;  value.toDebugString - If exists for the object, we will call it with parameters (numTabs) rather than looping over the objects subscripts.
	; 
	; Parameters:
	;  value    - Object to put together a string about.
	;  numTabs  - How much to indent the start of the string. Subitems will be indented by numTabs+1.
	;  index    - If set, row will be prefaced with "[index] "
	;  noIndent - If true, we will NOT indent this line. Typically used because caller has already done the indentation.
	;              NOTE: subitems will still be indented by numTabs+1.
	buildObjectString(value, numTabs = 0, index = "", noIndent = false) {
		if(!noIndent)
			outStr := getTabs(numTabs, DEBUG.spacesPerTab)
		
		; Index
		if(index != "")
			outStr .= "[" index "] "
		
		; Base case - not a complex object, just add our value and be done.
		if(!isObject(value)) {
			outStr .= value
			return outStr
		}
		
		; If an object has its own name specified, use it.
		if(value.debugName) {
			outStr .= "{" value.debugName "}"
		
		; Otherwise, just use a generic "Array" label and add the number of elements.
		} else {
			arraySize := getArraySize(value)
			if(!arraySize)
				outStr .= "`n" ; Empty array, no number or subitems.
			else
				outStr .= "Array (" arraySize ")"
		}
		
		; If an object has its own debug printout, use that rather than looping.
		if(isFunc(value.toDebugString)) {
			outStr .= "`n" value.toDebugString(numTabs + 1)
			
		} else {
			; Loop over the object's subscripts.
			For i,v in value {
				outStr .= "`n" this.buildObjectString(v, numTabs + 1, i)
			}
		}
		
		
		
		return outStr
	}
	
	; Given any number of pairs of (label, value), build a debug string to put into a popup.
	buildDebugString2(var, label = "", index = "", numTabs = 0, labelSameLine = false) {
		outStr := ""
		if(label)
			label .= ": "
		if(var.debugName)
			label .= "[" var.debugName "]"
		
		; numTabsStart := numTabs
		
		outStr .= getTabs(numTabs, DEBUG.spacesPerTab)
		
		; Label.
		if(label) {
			outStr .= label
			if(!labelSameLine) {
				outStr .= "`n"
				numTabs++
			}
			
		} else if(index) { ; Index means it stays on the same line.
			outStr .= "[" index "] "
		}
		
		; numTabsHalf := numTabs
		; firstHalfString := outStr
		
		; Variable.
		if(IsObject(var) && IsFunc(var.toDebugString) && var.debugNoRecurse) {
			outStr .= var.toDebugString(numTabs + 1)
			
		} else if(IsObject(var)) { ; Array, time to start recursing.
			if(!labelSameLine)
				outStr .= getTabs(numTabs, DEBUG.spacesPerTab)
			outStr .= "Array (" var.MaxIndex() ")`n"
			For i,v in var
				outStr .= this.buildDebugString(v, , i, numTabs + 1)
			
		} else { ; Lowest level - show the value.
			if(!index && !labelSameLine)
				outStr .= getTabs(numTabs, DEBUG.spacesPerTab)
			outStr .= var "`n"
		}
		
		; MsgBox, % "x Label:`n" label "`nx Variable:`n" var "`nx NumTabs Start:`n" numTabsStart "`nx NumTabs Half:`n" numTabsHalf "`nx First half:`n" firstHalfString "z`nx Final:`n" outStr "z"
		
		return outStr
	}
}
