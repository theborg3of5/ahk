/* GDB TODO --=
	
	Example Usage
;		GDB TODO
	
	GDB TODO
		Update auto-complete and syntax highlighting notepad++ definitions
		Setting for how much space between columns
		Functions for adding rows individually
	
*/ ; =--

class TextTable {
	; #PUBLIC#
	
	;  - Constants
	
	;  - staticMembers
	
	;  - nonStaticMembers
	spacesBetweenColumns := 2
	
	;  - properties
	
	__New(dataTable := "", columnPadding := "") {
		if(columnPadding != "")
			this.spacesBetweenColumns := columnPadding
		
		; Copy the data over
		For _,row in dataTable
			this.table.push(row.clone())
		Debug.popup("dataTable",dataTable, "this.table",this.table)
		
		; Figure out the max width of each column.
		For _,row in this.table {
			For columnIndex,cellValue in row
				this.columnWidths[columnIndex] := DataLib.max(this.columnWidths[columnIndex], cellValue.length())
		}
		Debug.popup("this.table",this.table, "this.columnWidths",this.columnWidths)
	}
	
	;  - otherFunctions
	
	generateString() {
		outputString := ""
		
		For _,row in this.table {
			rowString := ""
			For columnIndex,cellValue in row {
				cellString := cellValue.postPadToLength(this.columnWidths[columnIndex])
				rowString := rowString.appendPiece(cellString, StringLib.getSpaces(this.spacesBetweenColumns))
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
	table := []
	columnWidths := []
	
	;  - functions
	
	
	; #DEBUG#
	
	Debug_TypeName() {
		return "GDB TODO"
	}
	
	Debug_ToString(ByRef builder) {
		builder.addLine("GDB TODO", this.GDBTODO)
	}
	; #END#
}
