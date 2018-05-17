; Debugger object and functions.

class DEBUG {
	static spacesPerTab := 4 ; How many spaces are in a tab that we indent things by.
	
	; Popup, but show before MainConfig is initialized.
	popupEarly(params*) {
		this.popupCore(params*)
	}
	
	; Input in any number of pairs of (label, value), in that order. They will be formatted as described in DEBUG.buildDebugString.
	popup(params*) {
		; Only start showing popups once MainConfig is finished loading - popupEarly can be used if you want to show debug messages in these cases.
		if(!MainConfig.isInitialized())
			return
		
		this.popupCore(params*)
	}
	
	popupCore(params*) {
		; Single parameter with an (assumed-to-be) associative array.
		if(params.length() = 1) {
			outString := this.buildObjectString(params[1])
		
		; Assume we have a list of label,value pairs (2 parameters at a time go together).
		} else {
			; Convert params array into array of (label, value) pairs.
			pairedParams := []
			i := 1
			while(i <= params.length()) {
				; MsgBox, % "Label`n`t" params[i] "`nValue:`n`t" params[i + 1])
				pairedParams.Push([params[i], params[i + 1]])
				i += 2
			}
			; MsgBox, % pairedParams[1][1] "`n" pairedParams[1][2]
			outString := this.buildDebugPopup(pairedParams)
		}
		
		MsgBox, % outString
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
		outString .= getTabs(numTabs, DEBUG.spacesPerTab) label ": " ; Label
		outString .= this.buildObjectString(value, numTabs)          ; Value
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
	;  newLine  - If true, we will indent this line. Typically used because the value is going on a new line (as opposed to next to the current label).
	;              NOTE: subitems will be indented by numTabs+1 regardless.
	;  index    - If set, row will be prefaced with "[index] "
	buildObjectString(value, numTabs = 0, newLine = false, index = "") {
		if(newLine)
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
		} else {
			For subIndex,subVal in value
				outString .= "`n" this.buildObjectString(subVal, numTabs + 1, true, subIndex)
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
