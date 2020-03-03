/* GDB TODO --=
	
	Example Usage
;		GDB TODO
	
	GDB TODO
		Update auto-complete and syntax highlighting notepad++ definitions
		Should this literally be an extension of TextTable?
			Can we override getText() like we want to, and still call into the base logic?
				If that's the only problem, should we just rename one of the two getText()s?
	
*/ ; =--

class DebugTable {
	; #PUBLIC#
	
	;  - Constants
	;  - staticMembers
	;  - nonStaticMembers
	;  - properties
	;  - __New()/Init()
	__New(title) {
		this.title := title
		this.table.setTopTitle(title)
	}
	;  - otherFunctions
	thickBorderOn() {
		this.table.setBorderType(TextTable.BorderType_BoldLine)
		return this
	}
	
	addPairs(params*) {
		Loop, % params.MaxIndex() // 2 {
			label := params[A_Index * 2 - 1]
			value := params[A_Index * 2]
			this.addLine(label, value)
		}
	}
	
	addLine(label, value) {
		this.table.addRow(label ":", this.buildValueDebugString(value))
	}
	
	getText() {
		; Also add the title to the bottom if the table ends up tall enough.
		if(this.table.getHeight() > 50)
			this.table.setBottomTitle(this.title)
		
		return this.table.getText()
	}
	
	getWidth() {
		return this.table.getWidth()
	}
	
	getHeight() {
		return this.table.getHeight()
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
	table := new TextTable().setBorderType(TextTable.BorderType_Line)
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
		return "GDB TODO"
	}
	
	Debug_ToString(ByRef builder) {
		builder.addLine("GDB TODO", this.GDBTODO)
	}
	; #END#
}
