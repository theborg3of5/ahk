/* GDB TODO --=
	
	Example Usage
;		GDB TODO
	
	GDB TODO
		Update auto-complete and syntax highlighting notepad++ definitions
	
*/ ; =--

class DebugTable extends TextTable {
	; #PUBLIC#
	
	;  - Constants
	;  - staticMembers
	;  - nonStaticMembers
	;  - properties
	;  - __New()/Init()
	__New(title) {
		this.title := title
		
		this.setBorderType(TextTable.BorderType_Line)
		this.setTopTitle(title)
	}
	
	;  - otherFunctions
	
	addPairs(params*) {
		Loop, % params.MaxIndex() // 2 {
			label := params[A_Index * 2 - 1]
			value := params[A_Index * 2]
			this.addLine(label, value)
		}
	}
	
	addLine(label, value) {
		this.addRow(label ":", this.buildValueDebugString(value))
	}
	
	getText() {
		; Also add the title to the bottom if the table ends up tall enough.
		if(this.getHeight() > 50)
			this.setBottomTitle(this.title)
		
		return base.getText()
	}
	
	
	; #INTERNAL#
	
	;  - Constants
	;  - staticMembers
	;  - nonStaticMembers
	;  - functions
	
	
	; #PRIVATE#
	
	;  - Constants
	;  - staticMembers
	;  - nonStaticMembers
	title := ""
	
	;  - functions
	buildValueDebugString(value) {
		; Base case - not a complex object, just return the value to show.
		if(!isObject(value))
			return value
		
		; Just display the name if it's an empty object (like an empty array)
		objName := this.getObjectName(value)
		if(value.count() = 0)
			return objName
		
		; Compile child values
		childTable := new DebugTable(objName)
		if(isFunc(value.Debug_ToString)) { ; If an object has its own debug logic, use that rather than looping.
			value.Debug_ToString(childTable)
		} else {
			For subLabel,subVal in value
				childTable.addLine(subLabel, subVal)
		}
		
		return childTable.getText()
	}

	getObjectName(value) {
		; If an object has its own name specified, use it.
		if(isFunc(value.Debug_TypeName))
			return value.Debug_TypeName()
			
		; For other objects, just use a generic "Array"/"Object" label and add the number of elements.
		if(value.isArray)
			return "Array (" value.count() ")"
		return "Object (" value.count() ")"
	}
	
	
	; #DEBUG#
	
	Debug_TypeName() {
		return "DebugTable"
	}
	; #END#
}
