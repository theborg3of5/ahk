; Debugger object and functions.

class DEBUG {
	static spacesPerTab := 4 ; How many spaces are in a tab that we indent things by.
	
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
		outString := ""
		
		For i,p in params {
			newString := this.buildDebugString(p[1], p[2], numTabs)
			outString := appendLine(outString, newString)
		}
		
		return outString
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
	buildDebugString(label, value, numTabs = 0) {
		outString := ""
		outString .= getTabs(numTabs, DEBUG.spacesPerTab) label ": "  ; Label
		outString .= this.buildObjectString(value, numTabs, "", true) ; Value
		return outString
	}
	
	; Puts together a string describing the value given.
	; 
	; Relevant special properties of objects:
	;  value.debugName     - Rather than the generic "Array", text will contain {value.debugName}.
	;  value.debugToString - If exists for the object, we will call it with the parameter (debugBuilder) rather than looping over the objects subscripts.
	;									debugBuilder - A DebugBuilder object (see debugBuilder.ahk)
	; Parameters:
	;  value    - Object to put together a string about.
	;  numTabs  - How much to indent the start of the string. Subitems will be indented by numTabs+1.
	;  index    - If set, row will be prefaced with "[index] "
	;  noIndent - If true, we will NOT indent this line. Typically used because we're still on the label line.
	;              NOTE: subitems will still be indented by numTabs+1.
	buildObjectString(value, numTabs = 0, index = "", noIndent = false) {
		if(!noIndent)
			outString := getTabs(numTabs, DEBUG.spacesPerTab)
		
		; Index
		if(index != "")
			outString .= "[" index "] "
		
		; Base case - not a complex object, just add our value and be done.
		if(!isObject(value)) {
			outString .= value
			return outString
		}
		
		outString .= this.getObjectName(value)
		
		; If an object has its own debug printout, use that rather than looping.
		if(isFunc(value.debugToString)) {
			builder := new DebugBuilder(numTabs + 1)
			value.debugToString(builder)
			outString .= "`n" builder.toString()
			builder := ""
		} else {
			For subIndex,subVal in value
				outString .= "`n" this.buildObjectString(subVal, numTabs + 1, subIndex)
		}
		
		return outString
	}
	
	getObjectName(value) {
		; If an object has its own name specified, use it.
		if(value.debugName)
			return "{" value.debugName "}"
			
		; For other objects, just use a generic "Array" label and add the number of elements.
		return "Array (" getArraySize(value) ")"
	}
}
