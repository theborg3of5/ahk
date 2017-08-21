; Debugger object and functions.

class DEBUG {
	static spacesPerTab := 6 ; How many spaces are in a tab that we indent things by.
	
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
	;  label: value
	; For arrays, format looks like this:
	;  label: Array (numIndices)
	;     [index] value
	;     [index] value
	;     ...
	; Also respects custom debug names and debug functions - see buildObjectString() for details.
	; 
	; Parameters:
	;  label       - Label to show the value with
	;  value       - Value to show. If this is an object, we will call into DEBUG.buildObjectString() for a more complete description.
	;  numTabs     - Number of tabs of indentation to start at. Sub-values (for array indices or custom debug function) will be indented by numTabs+1.
	;  isFirstLine - True if this is the first line (and should not have a newline before it).
	buildDebugString(label, value, numTabs = 0, isFirstLine = false) {
		outStr := ""
		
		if(!isFirstLine)
			outStr .= "`n"
		outStr .= getTabs(numTabs, DEBUG.spacesPerTab) label ": "  ; Label
		outStr .= this.buildObjectString(value, numTabs, "", true) ; Value
		
		return outStr
	}
	
	; Puts together a string describing the value given.
	; 
	; Relevant special properties of objects:
	;  value.debugName     - Rather than the generic "Array", text will contain {value.debugName}.
	;  value.debugToString - If exists for the object, we will call it with parameters (numTabs) rather than looping over the objects subscripts.
	; 
	; Parameters:
	;  value    - Object to put together a string about.
	;  numTabs  - How much to indent the start of the string. Subitems will be indented by numTabs+1.
	;  index    - If set, row will be prefaced with "[index] "
	;  noIndent - If true, we will NOT indent this line. Typically used because we're still on the label line.
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
		
		outStr .= this.getObjectName(value)
		
		if(isFunc(value.debugToString)) ; If an object has its own debug printout, use that rather than looping.
			outStr .= "`n" value.debugToString(numTabs + 1)
		else
			For subIndex,subVal in value
				outStr .= "`n" this.buildObjectString(subVal, numTabs + 1, subIndex)
		
		return outStr
	}
	
	getObjectName(value) {
		; If an object has its own name specified, use it.
		if(value.debugName)
			return "{" value.debugName "}"
			
		; For other objects, just use a generic "Array" label and add the number of elements.
		return "Array (" getArraySize(value) ")"
	}
}
