/* GDB TODO --=
	
	GDB TODO Call out that this requires a monospace font
	
	Example Usage
;		GDB TODO
	
	GDB TODO
		Somehow support sub-tables as well? Maybe just additional instances of these same 'text tables"?
		Update auto-complete and syntax highlighting notepad++ definitions
	
*/ ; =--

class TextTable {
	; #PUBLIC#
	
	;  - Constants
	
	;  - staticMembers
	
	;  - nonStaticMembers
	
	;  - properties
	
	__New(dataTable := "") {
		if(spacesBetweenColumns != "")
			spacesBetweenColumns := spacesBetweenColumns
		
		; Add any provided rows
		For _,row in dataTable
			this.addRow(row)
	}
	
	;  - otherFunctions
	
	setColumnPadding(numSpaces) {
		this.spacesBetweenColumns := numSpaces
		return this
	}
	
	setDefaultAlignment(newAlignment) { ; From TextAlignment.*
		this.defaultAlignment := newAlignment
		return this
	}
	
	setColumnAlignment(columnIndex, newAlignment) { ; From TextAlignment.*
		this.columnAlignments[columnIndex] := newAlignment
		return this
	}
	
	addRow(row) {
		; Add the row to the table
		this.dataTable.push(row.clone())
		
		; Track the max width of all elements per column
		For columnIndex,cellValue in row
			this.columnWidths[columnIndex] := DataLib.max(this.columnWidths[columnIndex], cellValue.length())
	}
	
	generateString() {
		outputString := ""
		columnPadding := StringLib.getSpaces(this.spacesBetweenColumns)
		
		For _,row in this.dataTable {
			rowString := ""
			For columnIndex,cellValue in row {
				cellString := this.padValue(cellValue, columnIndex)
				rowString := rowString.appendPiece(cellString, columnPadding)
			}
			outputString := outputString.appendLine(rowString)
		}
		
		return outputString
	}
	
	; #PRIVATE#
	
	;  - Constants
	
	;  - staticMembers
	
	;  - nonStaticMembers
	dataTable := []
	columnWidths := []
	columnAlignments := [] ; TextAlignment.* values, defaults to this.defaultAlignment
	spacesBetweenColumns := 2 ; Minimum number of spaces between cell values
	defaultAlignment := TextAlignment.Left ; The default alignment for all cells
	
	;  - functions
	padValue(value, columnIndex) {
		width := this.columnWidths[columnIndex]
		alignment := DataLib.firstNonBlankValue(this.columnAlignments[columnIndex], this.defaultAlignment) ; Default to left-aligned
		
		; Left or right alignment, just put any remaining space there.
		if(alignment = TextAlignment.Left)
			return value.postPadToLength(width)
		if(alignment = TextAlignment.Right)
			return value.prePadToLength(width)
		
		; Center alignment, split it in between.
		if(alignment = TextAlignment.Center) {
			numSpacesNeeded := width - value.length()
			numRightSpaces := numSpacesNeeded // 2 ; If there's an odd number, right gets one less (floor division)
			numLeftSpaces := numSpacesNeeded - numRightSpaces
			
			return StringLib.getSpaces(numLeftSpaces) value StringLib.getSpaces(numRightSpaces)
		}
		
		return value
	}
	
	
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
