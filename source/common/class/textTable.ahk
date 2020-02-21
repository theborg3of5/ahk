/* This class takes a table of values and turns it into an aligned plain-text table. --=
	NOTE: This only really works with a monospace font, as it aligns based on characters.
	
	Example Usage
;		dataTable := []
;		dataTable.push(["val1", "val2", "val3"])
;		dataTable.push(["value4", "value5", "value6"])
;		tt := new TextTable(dataTable)
;		tt.setColumnPadding(1) ; Minimum number of spaces between values
;		tt.setDefaultAlignment(TextAlignment.Center) ; All columns default to centered
;		tt.setColumnAlignment(2, TextAlignment.Right) ; Column 2 (base-1 indexed)
;		tt.addRow(["v7", "v8", "v9"]) ; Add a new row dynamically (settings still apply)
;		output := tt.generateText()
;		
;		output:
;		 val1    val2  val3 
;		value4 value5 value6
;		  v7       v8   v9  
;
*/ ; =--

class TextTable {
	; #PUBLIC#
	
	;---------
	; PARAMETERS:
	;  dataTable (I,OPT) - 2-dimensional array of string values to include in the table.
	;---------
	__New(dataTable := "") {
		; Add any provided rows
		For _,row in dataTable
			this.addRow(row)
	}
	
	;---------
	; DESCRIPTION:    Set the minimum number of spaces between values in each row.
	; PARAMETERS:
	;  numSpaces (I,REQ) - How many spaces to require
	; RETURNS:        this
	;---------
	setColumnPadding(numSpaces) {
		this.spacesBetweenColumns := numSpaces
		return this
	}
	
	;---------
	; DESCRIPTION:    Set the default alignment for all columns in this table.
	; PARAMETERS:
	;  newAlignment (I,REQ) - A text-alignment value from TextAlignment.*
	; RETURNS:        this
	;---------
	setDefaultAlignment(newAlignment) {
		this.defaultAlignment := newAlignment
		return this
	}
	
	;---------
	; DESCRIPTION:    Set the alignment for a specific column.
	; PARAMETERS:
	;  columnIndex  (I,REQ) - The column index (base-1) to update
	;  newAlignment (I,REQ) - A text-alignment value from TextAlignment.*
	; RETURNS:        this
	;---------
	setColumnAlignment(columnIndex, newAlignment) {
		this.columnAlignments[columnIndex] := newAlignment
		return this
	}
	
	;---------
	; DESCRIPTION:    Add a new row to the table.
	; PARAMETERS:
	;  newRow (I,REQ) - An array of values to add as a new row in the table.
	;---------
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
	
	;---------
	; DESCRIPTION:    Get the current total width of the table.
	; RETURNS:        The current width of the table, including all columns and padding.
	;---------
	getWidth() {
		columnsTotal := DataLib.sum(this.columnWidths*)
		paddingTotal := this.spacesBetweenColumns * (this.columnWidths.count() - 1)
		
		return columnsTotal + paddingTotal
	}
	
	;---------
	; DESCRIPTION:    Generate the table as a string
	; RETURNS:        The table, as a string
	;---------
	generateText() {
		outputString := ""
		columnPadding := StringLib.getSpaces(this.spacesBetweenColumns)
		
		For _,row in this.dataTable {
			rowString := ""
			For columnIndex,value in row {
				cellString := this.formatValue(value, columnIndex)
				rowString := rowString.appendPiece(cellString, columnPadding)
			}
			outputString := outputString.appendLine(rowString)
		}
		
		return outputString
	}
	
	; #PRIVATE#
	
	dataTable            := []                 ; Our 2-dimensional array of values.
	columnWidths         := []                 ; Numbers of characters
	columnAlignments     := []                 ; TextAlignment.* values, defaults to this.defaultAlignment
	spacesBetweenColumns := 2                  ; Minimum number of spaces between cell values
	defaultAlignment     := TextAlignment.Left ; The default alignment for all cells
	
	;---------
	; DESCRIPTION:    Add a new row to the table, without extra handling for multi-line values.
	; PARAMETERS:
	;  newRow (I,REQ) - The array to add to the table.
	; SIDE EFFECTS:   Updates column widths
	;---------
	_addRow(newRow) {
		; Add the row to the table
		this.dataTable.push(newRow.clone())
		
		; Keep track of columns' max width
		For columnIndex,value in newRow
			this.columnWidths[columnIndex] := DataLib.max(this.columnWidths[columnIndex], value.length())
	}
	
	;---------
	; DESCRIPTION:    Pad and align the provided value according to the column specifications.
	; PARAMETERS:
	;  value       (I,REQ) - The value to update
	;  columnIndex (I,REQ) - The index of the column the value is in
	; RETURNS:        The formatted value, with appropriate padding
	;---------
	formatValue(value, columnIndex) {
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
	
	;---------
	; DESCRIPTION:    Turn a row which has values containing newlines into multiple rows, and add
	;                 those rows to our table.
	; PARAMETERS:
	;  originalRow (I,REQ) - The row to split
	;---------
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
	; #END#
}
