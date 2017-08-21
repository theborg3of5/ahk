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
	; label:
	;        value
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
	;  value.debugToString - If exists for the object, we will call it with parameters (numTabs) rather than looping over the objects subscripts.
	; 
	; Parameters:
	;  value    - Object to put together a string about.
	;  numTabs  - How much to indent the start of the string. Subitems will be indented by numTabs+1.
	;  index    - If set, row will be prefaced with "[index] "
	buildObjectString(value, numTabs = 0, index = "") {
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
		if(isFunc(value.debugToString)) {
			outStr .= "`n" value.debugToString(numTabs + 1)
			
		} else {
			; Loop over the object's subscripts.
			For i,v in value
				outStr .= "`n" this.buildObjectString(v, numTabs + 1, i)
		}
		
		
		
		return outStr
	}
}
