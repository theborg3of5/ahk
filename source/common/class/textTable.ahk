/* GDB TODO --=
	
	GDB TODO Call out that this requires a monospace font
	
	Example Usage
;		GDB TODO
	
	GDB TODO
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
	
	addRow(newRow) {
		; If any of the values are multi-line, split the row up into multiple and add those.
		For _,value in newRow {
			if(value.countMatches("`n")) {
				this.handleMultiLineValues(newRow)
				return
			}
		}
		
		this._addRow(newRow)
	}
	
	generateString() {
		outputString := ""
		columnPadding := StringLib.getSpaces(this.spacesBetweenColumns)
		
		For _,row in this.dataTable {
			rowString := ""
			For columnIndex,value in row {
				cellString := this.padValue(value, columnIndex)
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
	columnWidths := [] ; Numbers of characters
	columnAlignments := [] ; TextAlignment.* values, defaults to this.defaultAlignment
	spacesBetweenColumns := 2 ; Minimum number of spaces between cell values
	defaultAlignment := TextAlignment.Left ; The default alignment for all cells
	
	;  - functions
	
	_addRow(newRow) {
		; Add the row to the table
		this.dataTable.push(newRow.clone())
		
		; Keep track of columns' max width
		For columnIndex,value in newRow
			this.columnWidths[columnIndex] := DataLib.max(this.columnWidths[columnIndex], value.length())
	}
	
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
	
	handleMultiLineValues(originalRow) {
		numColumns := originalRow.count()
		
		; Split the row up into a transposed table (columns, then rows)
		flippedTable := []
		maxNumLines := 0
		For columnIndex,value in originalRow {
			valueLines := value.split("`n", "`r") ; Drop carriage returns if they're in there too
			DataLib.updateMax(maxNumLines, valueLines.count())
			flippedTable.push(valueLines)
		}
		
		; Build each new row using a value from each column.
		Loop, % maxNumLines {
			rowIndex := A_Index
			newRow := []
			
			Loop, % numColumns {
				columnIndex := A_Index
				
				value := flippedTable[columnIndex, rowIndex]
				newRow.push(value)
			}
			
			this._addRow(newRow)
		}
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
