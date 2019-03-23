/* Non-static class for building custom debug strings for use by the DEBUG class.
	
	Motivation
		This is a simple class that can be passed to classes that want the DEBUG class to show something different than just their class properties with those variable names.
		
	Usage
		Classes which wish to have a custom debug string should implement a .debugToString function that takes an instance of this class as its only parameter. Within that function they can call <debugBuilderVariable>.addLine() to add a label/value pair to the custom string.
		Example:
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
			
			When an instance of this class is evaluated with the DEBUG class, we will call the .debugToString() function to get the value to show, giving something like this (label specified by caller to DEBUG):
				<label>: {ObjectWithDebug}
					Descriptive name of property 1: A
					Descriptive name of property 2: B
			
			Note that indentation is handled by this class - each line will be shown one line deeper than the overall line (with the debugName) for the class.
*/

class DebugBuilder {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	;---------
	; DESCRIPTION:    Create a new TableList instance.
	; PARAMETERS:
	;  numTabs (I,OPT) - How many levels of indentation the string should start at. Added lines will
	;                    be at this level + 1.
	; RETURNS:        Reference to new DebugBuilder object
	;---------
	__New(numTabs := 0) {
		this.numTabs := numTabs
	}
	
	;---------
	; DESCRIPTION:    Add a properly-indented line* with the given label and value to the output
	;                 string.
	; PARAMETERS:
	;  label (I,REQ) - The label to show for the given value
	;  value (I,REQ) - The value to evaluate and show. Will be treated according to the logic
	;                  described in the DEBUG class (see that class documentation for details).
	; NOTES:          A "line" may actually contain multiple newlines, but anything below the
	;                 initial line will be indented 1 level deeper.
	;---------
	addLine(label, value) {
		newLine := DEBUG.buildDebugStringForPair(label, value, this.numTabs)
		this.outString := appendLine(this.outString, newLine)
	}
	
	;---------
	; DESCRIPTION:    Retrieve the debug string built by this class.
	; RETURNS:        The string built by this class, in full.
	;---------
	toString() {
		return this.outString
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	numTabs   := 0  ; How indented our base level of text should be.
	outString := "" ; Built-up string to eventually return.
	
}
