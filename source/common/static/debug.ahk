/* Static class to show debug information about whatever it's given. =--
	=-- Motivation
			This class is intended to show information in a slightly more structured and considerably deeper way than simply including the variable on a popup can do. It:
				* Recurses into objects
				* Supports label-object pairs in a single function call (variadic arguments instead of building an array yourself)
				* Supports more specific information from objects/classes which implement a couple of extra properties (see "Special Properties and Functions" below)
			
	--- Argument Interpretation
			Both public entry points, (Debug.popup, Debug.toast) take variadic arguments - that is, you can give them however many arguments you want. They will interpret those arguments as follows:
				1 argument: This is a value that will get evaluated and displayed
				>1 arguments: The arguments are assumed to be grouped in pairs - that is, parameter 1 is a label for parameter 2, 3 is a label for 4, etc.
			
	--- Evaluating value parameters
			Values: Simple values like strings and numbers will be displayed normally.
			Arrays: Numeric arrays will start with a line reading "Array (numIndices)", where numIndices is the count of indices in the array. Then, each of the indices in the array will be shown in square brackets next to their corresponding values. For example:
						Array (2)
							[1] A
							[2] B
				Associative arrays work the same way, with the actual indices inside the square brackets.
			Objects: If an object has implemented the .debugName variable and .debugToString function, it will be displayed as described in the "Special Properties and Functions" section below. If not, it will be treated the same as an array (where we show the subscripts [variables] underneath an "Array (numVariables)" line.
			
	--- Special Properties and Functions
			If a class has the following properties and functions, Debug.popup/.toast will display information about an instance of that class differently.
			
			.debugName
				If this is populated, then its top value will be "{debugName}" (with brackets) instead of the usual "Array (count)".
				
			.debugToString(debugBuilder)
				If this is implemented, we will use the text generated by this function instead of recursing into the object itself.
				The debugBuilder argument that will be passed is an instance of the DebugBuilder class, which will take function calls to fill it out. See the DebugBuilder class for more details.
			
	--- Indentation
			Indentation within the popup or toast is done using spaces instead of tabs (4 spaces per level) in order to avoid odd wrapping and alignment issues.
			
	--- Example Usage
			value := 1
			numericArray := ["value1", "value2"]
			assocArray := {"label1":"value1", "label2":"value2"}
			
			class ObjectWithDebug {
				__New() {
					this.var1 := "A"
					this.var2 := "B"
				}
				
				; Debug info
				debugName := "ObjectWithDebug"
				debugToString(debugBuilder) {
					debugBuilder.addLine("Descriptive name of property 1", this.var1)
					debugBuilder.addLine("Descriptive name of property 2", this.var2)
				}
			}
			objectInstance := new ObjectWithDebug()
			
			Debug.popup("A",value, "B",numericArray, "C",assocArray, "D",objectInstance)
				; Shows a popup with this text:
				;	A: 1
				;	B: Array (2)
				;		 [1] value1
				;		 [2] value2
				;	C: Array (2)
				;		 [label1] value1
				;		 [label2] value2
				;	D: {ObjectWithDebug}
				;		 Descriptive name of property 1: A
				;		 Descriptive name of property 2: B
				
			Debug.toast("A",value, "B",numericArray, "C",assocArray, "D",objectInstance)
				; Shows a brief toast (non-focusable, semi-transparent gui) in the bottom-right with this text:
				;	A: 1
				;	B: Array (2)
				;		 [1] value1
				;		 [2] value2
				;	C: Array (2)
				;		 [label1] value1
				;		 [label2] value2
				;	D: {ObjectWithDebug}
				;		 Descriptive name of property 1: A
				;		 Descriptive name of property 2: B
		
	--=
*/ ; --=

class Debug {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Display a popup of information about the information provided. See class
	;                 documentation for information about how we handle labels, values, arrays,
	;                 and objects.
	; PARAMETERS:
	;  params (I,REQ) - A variable number of arguments to display in the popup. For 1 argument,
	;                   we will interpret it as a value (not a label), but for >1 arguments an
	;                   even number of arguments should be passed in label,value pairs.
	; NOTES:          This function won't do anything before Config has initialized; this
	;                 is to prevent massive numbers of popups when debugging a function that it
	;                 uses (from each of the different standlone scripts that run). If you need
	;                 to show a popup before that point, you can use the .popupEarly() function
	;                 instead.
	;---------
	popup(params*) {
		; Only start showing popups once Config is finished loading - popupEarly can be used if you want to show debug messages in these cases.
		if(!Config.initialized)
			return
		
		MsgBox, % this.buildDebugString(params*)
	}
	
	;---------
	; DESCRIPTION:    Same as .popup(), but will run before Config is initialized. See
	;                 .popup() for details and parameters.
	;---------
	popupEarly(params*) {
		MsgBox, % this.buildDebugString(params*)
	}
	
	;---------
	; DESCRIPTION:    Display a toast (brief, semi-transparent display in the bottom-right) of
	;                 information about the information provided. See class documentation for
	;                 information about how we handle labels, values, arrays, and objects.
	; PARAMETERS:
	;  params (I,REQ) - A variable number of arguments to display in the popup. For 1 argument,
	;                   we will interpret it as a value (not a label), but for >1 arguments an
	;                   even number of arguments should be passed in label,value pairs.
	;---------
	toast(params*) {
		new Toast(this.buildDebugString(params*)).showLong()
	}
	
	
	; #PRIVATE#
	
	static singleIndent := "    " ; 4 spaces are used for each level of indentation.
	
	;---------
	; DESCRIPTION:    Build the debug string for the given value or label-value pairs.
	; PARAMETERS:
	;  params (I,REQ) - A variable number of arguments to display in the popup. For 1 argument,
	;                   we will interpret it as a value (not a label), but for >1 arguments an
	;                   even number of arguments should be passed in label,value pairs.
	; RETURNS:        A formatted string representing the labels and values given. See class
	;                 documentation for format.
	;---------
	buildDebugString(params*) {
		outString := ""
		
		; Single parameter - treat as an object.
		if(params.length() = 1)
			return this.buildValueDebugString(params[1])
		
		; Otherwise, assume we have a list of label,value pairs (2 parameters at a time go together).
		pairedParams := this.convertParamsToPaired(params)
		; For i,row in pairedParams
			; MsgBox, % i "`n" row["LABEL"] "`n" row["VALUE"]
		
		For i,row in pairedParams {
			newString := this.buildDebugStringForPair(row["LABEL"], row["VALUE"])
			outString := outString.appendPiece(newString, "`n")
		}
		
		return outString
	}
	
	;---------
	; DESCRIPTION:    Turn an array of parameters (which came from variadic parameters to the
	;                 calling function) into an array of pairs, where the pairs are size-2
	;                 arrays.
	; PARAMETERS:
	;  params (I,REQ) - Array of parameters, where the odd-numbered indices hold labels for
	;                   their following even-numbered indices.
	; RETURNS:        Array of pairs, where each pair is an array of this format:
	;                    pairedParams[i, "LABEL"] = label (odd index)
	;                                    "VALUE"] = value (following even index)
	;---------
	convertParamsToPaired(params) {
		pairedParams := []
		
		Loop, % params.MaxIndex() // 2 {
			key   := params[A_Index * 2 - 1]
			value := params[A_Index * 2]
			pairedParams.Push({"LABEL":key, "VALUE":value})
		}
		
		return pairedParams
	}
	
	;---------
	; DESCRIPTION:    Builds a debug string for a single label-value pair, including any needed
	;                 indentation and sub-lines.
	; PARAMETERS:
	;  label   (I,REQ) - Label to show the value with.
	;  value   (I,REQ) - Value to show. Will be evaluated according to the logic described in the
	;                    class documentation.
	;  numTabs (I,OPT) - Indentation level that this string needs to start at. Sub-levels (array
	;                    indices, lines set in object's .debugToString) will be indented by
	;                    numTabs+1. Defaults to 0 (no indentation).
	; RETURNS:        Formatted string for a single label/value passed in.
	; NOTES:          May be more than a single line, depending on the value - if it's an array or
	;                 object we'll show the contents too.
	;---------
	buildDebugStringForPair(label, value, numTabs := 0) {
		outString := ""
		outString .= this.getIndent(numTabs) label ": " ; Label
		outString .= this.buildValueDebugString(value, numTabs)      ; Value
		return outString
	}
	
	;---------
	; DESCRIPTION:    
	; PARAMETERS:
	;  value   (I,REQ) - Value to show. Will be evaluated according to the logic described in the
	;                    class documentation.
	;  numTabs (I,OPT) - Indentation level that this string needs to start at. Sub-levels (array
	;                    indices, lines set in object's .debugToString) will be indented by
	;                    numTabs+1. Defaults to 0 (no indentation).
	;  newLine (I,OPT) - If true, we will indent this line. Typically used because the value is
	;                    going on a new line (as opposed to next to the current label).
	;              			NOTE: subitems will be indented by numTabs+1 regardless.
	;  index   (I,OPT) - If set, row will be prefaced with "[index] "
	; RETURNS:        Formatted string for the single value (simple, array, or object) given.
	; NOTES:          May recurse to get at indices/sub-values or custom debug functions.
	;---------
	buildValueDebugString(value, numTabs := 0, newLine := false, index := "") {
		if(newLine)
			outString := this.getIndent(numTabs)
		
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
				outString .= "`n" this.buildValueDebugString(subVal, numTabs + 1, true, subIndex)
		}
		
		return outString
	}
	
	;---------
	; DESCRIPTION:    Get the given number of indentations as spaces.
	; PARAMETERS:
	;  numIndents (I,REQ) - The number of indentations.
	; RETURNS:        As many spaces are needed to indent to the given level.
	;---------
	getIndent(numIndents) {
		return StringLib.duplicate(Debug.singleIndent, numIndents)
	}
	
	;---------
	; DESCRIPTION:    Determine the name we should show for an object (array or class instance)
	; PARAMETERS:
	;  value (I,REQ) - Object to determine the name of.
	; RETURNS:        "{debugName}" for objects that implement .debugName
	;                 "Array (numIndices)" for arrays and objects that don't implement .debugName
	;---------
	getObjectName(value) {
		; If an object has its own name specified, use it.
		if(value.debugName)
			return "{" value.debugName "}"
			
		; For other objects, just use a generic "Array"/"Object" label and add the number of elements.
		if(value.isArray)
			return "Array (" value.count() ")"
		return "Object (" value.count() ")"
	}
	; #END#
}
