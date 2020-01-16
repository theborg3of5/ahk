/* GDB TODO --=
	
	Example Usage
;		GDB TODO
	
	GDB TODO
		Update auto-complete and syntax highlighting notepad++ definitions
		Call out that this requires a monospace font
	
*/ ; =--

class TextTable {
	; #PUBLIC#
	
	;  - Constants
	
	;  - staticMembers
	
	;  - nonStaticMembers
	columnPadding := 2 ; Minimum number of spaces between cell values
	
	;  - properties
	
	__New(dataTable := "", columnPadding := "") {
		if(columnPadding != "")
			this.columnPadding := columnPadding
		
		; Add any provided rows
		For _,row in dataTable
			this.addRow(row)
		
		; Debug.popup("dataTable",dataTable, "this.dataTable",this.dataTable, "this.columnWidths",this.columnWidths)
		Debug.popup("this",this)
	}
	
	;  - otherFunctions
	
	addRow(row) {
		; Add the row to the table
		this.dataTable.push(row.clone())
		
		; Track the max width of all elements per column
		For columnIndex,cellValue in row
			this.columnWidths[columnIndex] := DataLib.max(this.columnWidths[columnIndex], cellValue.length())
	}
	
	generateString() {
		outputString := ""
		
		For _,row in this.dataTable {
			rowString := ""
			For columnIndex,cellValue in row {
				cellString := cellValue.postPadToLength(this.columnWidths[columnIndex])
				rowString := rowString.appendPiece(cellString, StringLib.getSpaces(this.columnPadding))
			}
			outputString := outputString.appendLine(rowString)
		}
		
		return outputString
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
	dataTable := []
	columnWidths := []
	
	;  - functions
	
	
	; #DEBUG#
	
	Debug_TypeName() {
		return "TextTable"
	}
	
	; Debug_ToString(ByRef builder) {
		; builder.addLine("Internal table", this.dataTable)
		; builder.addLine("Column widths", this.columnWidths)
		; builder.addLine("Generated table", this.generateString())
	; }
	; #END#
}
