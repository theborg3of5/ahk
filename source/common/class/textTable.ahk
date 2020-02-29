/* This class takes a table of values and turns it into an aligned plain-text table. --=
	NOTE: This only really works with a monospace font, as it aligns based on characters.
	
	Example Usage
;		dataTable := []
;		dataTable.push(["val1", "val2", "val3"])
;		dataTable.push(["value4", "value5", "value6"])
;		tt := new TextTable(dataTable)
;		tt.setColumnDivider(" ") ; Divider between columns (1 space)
;		tt.setDefaultAlignment(TextAlignment.Center) ; All columns default to centered
;		tt.setColumnAlignment(2, TextAlignment.Right) ; Column 2 (base-1 indexed)
;		tt.addRow("v7", "v8", "v9") ; Add a new row dynamically (settings still apply)
;		output := tt.generateText()
;		
;		output:
;		 val1    val2  val3 
;		value4 value5 value6
;		  v7       v8   v9  
;
*/ ; =--

;GDB TODO update various documentation for this class, including the above

class TextTable {
	; #PUBLIC#
	
	static BorderType_None     := "NONE"
	static BorderType_Line     := "LINE"
	static BorderType_BoldLine := "BOLD_LINE"
	
	;---------
	; PARAMETERS:
	;  dataTable (I,OPT) - 2-dimensional array of string values to include in the table.
	;---------
	__New(dataTable := "") {
		this.addRows(dataTable*)
	}
	
	
	setTopTitle(title) {
		this.topTitle := title
		return this
	}
	setBottomTitle(title) {
		this.bottomTitle := title
		return this
	}
	
	;---------
	; DESCRIPTION:    Set the string that will be put between each cell in a row.
	; PARAMETERS:
	;  dividerString (I,REQ) - The new divider string
	; RETURNS:        this
	;---------
	setColumnDivider(dividerString) {
		this.columnDividerString := dividerString
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
	
	
	setBorderType(borderType) {
		if(borderType = this.BorderType_None) {
			this.borderH  := ""
			this.borderV  := ""
			this.borderTL := ""
			this.borderTR := ""
			this.borderBL := ""
			this.borderBR := ""
			this.outerPaddingH := 0
			this.outerPaddingV := 0
			
		} else if(borderType = this.BorderType_Line) {
			this.borderH  := Chr(0x2500) ; ─
			this.borderV  := Chr(0x2502) ; │
			this.borderTL := Chr(0x250C) ; ┌
			this.borderTR := Chr(0x2510) ; ┐
			this.borderBL := Chr(0x2514) ; └
			this.borderBR := Chr(0x2518) ; ┘
			this.outerPaddingH := 1
			this.outerPaddingV := 0
			
		} else if(borderType = this.BorderType_BoldLine) {
			this.borderH  := Chr(0x2501) ; ━
			this.borderV  := Chr(0x2503) ; ┃
			this.borderTL := Chr(0x250F) ; ┏
			this.borderTR := Chr(0x2513) ; ┓
			this.borderBL := Chr(0x2517) ; ┗
			this.borderBR := Chr(0x251B) ; ┛
			this.outerPaddingH := 1
			this.outerPaddingV := 0
		}
		
		return this
	}
	
	;---------
	; DESCRIPTION:    Add a new row to the table.
	; PARAMETERS:
	;  newValues* (I,REQ) - Variadic parameter, pass in however many elements you want in column order.
	; RETURNS:        this
	;---------
	addRow(newValues*) {
		; If any of the values are multi-line, split the row up into multiple and add those.
		For _,value in newValues {
			if(value.countMatches("`n")) {
				this.handleMultiLineValues(newValues)
				return
			}
		}
		
		this._addRow(newValues)
		
		return this
	}
	
	
	addRows(newRows*) {
		For _,row in newRows
			this.addRow(row*)
		
		return this
	}
	
	;---------
	; DESCRIPTION:    Get the current total width of the table in characters.
	; RETURNS:        The current width of the table, including all columns and padding.
	;---------
	getWidth() {
		contentWidth      := this.getContentWidth()
		outerPaddingWidth := this.outerPaddingH    * 2
		bordersWidth      := this.borderV.length() * 2
		
		; GDB TODO take top/bottom title widths into account - probably a max() call
		
		return contentWidth + outerPaddingWidth + bordersWidth
	}
	
	;---------
	; DESCRIPTION:    Get the current total height of the table in lines.
	; RETURNS:        The current height of the table.
	;---------
	getHeight() {
		contentHeight      := this.getContentHeight()
		outerPaddingHeight := this.outerPaddingV    * 2
		bordersHeight      := this.borderH.length() * 2
		
		return contentHeight + outerPaddingHeight + bordersHeight
	}
	
	;---------
	; DESCRIPTION:    Generate the table as a string
	; RETURNS:        The table, as a string
	;---------
	generateText() {
		output := ""
		
		output := output.appendLine(this.generateTopBlock())
		output := output.appendLine(this.generateContent())
		output := output.appendLine(this.generateBottomBlock())
		
		return output
	}
	
	; #PRIVATE#
	
	topTitle            := ""                 ; Title to show above the table.
	bottomTitle         := ""                 ; Title to show below the table.
	dataTable           := []                 ; Our 2-dimensional array of values.
	columnWidths        := []                 ; Numbers of characters
	columnAlignments    := []                 ; TextAlignment.* values, defaults to this.defaultAlignment
	columnDividerString := "  "               ; The text that should divide cells in a row
	defaultAlignment    := TextAlignment.Left ; The default alignment for all cells
	
	outerPaddingH := 0 ; Spaces between borders and values on left/right
	outerPaddingV := 0 ; Lines between borders and values on top/bottom
	borderH  := ""
	borderV  := ""
	borderTL := ""
	borderTR := ""
	borderBL := ""
	borderBR := ""
	
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
	
	
	generateTopBlock() {
		block := ""
		
		; Use spaces for any blank border characters, to ensure spacing stays correct
		lineH    := DataLib.firstNonBlankValue(this.borderH,  " ")
		cornerTL := DataLib.firstNonBlankValue(this.borderTL, " ")
		cornerTR := DataLib.firstNonBlankValue(this.borderTR, " ")
		
		; Title/border line
		if(this.needTopBorderTitleLine()) {
			insideWidth := this.getContentWidth() + (this.outerPaddingH * 2) ; Width between corners
			if(this.topTitle != "") {
				title := " " this.topTitle " " ; Go ahead and pad the title so we don't have to take that padding into account separately
				
				; GDB TODO figure out how to handle titles that make the box longer than the content - need to pass that info around somehow, probably a parameter?
				
				leftoverWidth := insideWidth - title.length()
				leftSpace := leftoverWidth // 2
				rightSpace := leftoverWidth - leftSpace ; Bias left if uneven leftover space
				
				topLine := cornerTL StringLib.duplicate(lineH, leftSpace) title StringLib.duplicate(lineH, rightSpace) cornerTR
			} else {
				topLine := cornerTL StringLib.duplicate(lineH, insideWidth) cornerTR
			}
			
			block := block.appendLine(topLine)
		}
		
		; Padding
		block .= StringLib.getNewlines(this.outerPaddingV)
		
		return block
	}
	
	needTopBorderTitleLine() {
		if(this.topTitle != "")
			return true
		if(this.borderH != "" || this.borderTL != "" || this.borderTR != "")
			return true
		
		return false
	}
	
	generateContent() {
		lineV := DataLib.firstNonBlankValue(this.borderV, " ")
		padding := StringLib.getSpaces(this.outerPaddingH)
		
		content := ""
		For _,row in this.dataTable {
			rowString := ""
			
			For columnIndex,value in row {
				cellString := this.formatValue(value, columnIndex)
				rowString := rowString.appendPiece(cellString, this.columnDividerString)
			}
			
			rowString := padding rowString padding
			
			if(this.needSideBorders())
				rowString := lineV rowString lineV
			
			content := content.appendLine(rowString)
		}
		
		return content
	}
	
	generateBottomBlock() { ; GDB TODO there's a lot of overlap between this and generateTopBlock - is there anything shared that would make sense to pull out?
		block := ""
		
		; Use spaces for any blank border characters, to ensure spacing stays correct
		lineH    := DataLib.firstNonBlankValue(this.borderH,  " ")
		cornerBL := DataLib.firstNonBlankValue(this.borderBL, " ")
		cornerBR := DataLib.firstNonBlankValue(this.borderBR, " ")
		
		; Padding
		block .= StringLib.getNewlines(this.outerPaddingV)
		
		; Title/border line
		if(this.needBottomBorderTitleLine()) {
			insideWidth := this.getContentWidth() + (this.outerPaddingH * 2) ; Width between corners
			if(this.bottomTitle != "") {
				title := " " this.bottomTitle " " ; Go ahead and pad the title so we don't have to take that padding into account separately
				
				leftoverWidth := insideWidth - title.length()
				leftSpace := leftoverWidth // 2
				rightSpace := leftoverWidth - leftSpace ; Bias left if uneven leftover space
				
				bottomLine := cornerBL StringLib.duplicate(lineH, leftSpace) title StringLib.duplicate(lineH, rightSpace) cornerBR
			} else {
				bottomLine := cornerBL StringLib.duplicate(lineH, insideWidth) cornerBR
			}
			
			block := block.appendLine(bottomLine)
		}
		
		return block
	}
	
	needBottomBorderTitleLine() {
		if(this.bottomTitle != "")
			return true
		if(this.borderH != "" || this.borderBL != "" || this.borderBR != "")
			return true
		
		return false
	}
	
	needSideBorders() {
		if(this.borderV != "")
			return true
		
		return false
	}
	
	
	getContentWidth() {
		columnsWidth := DataLib.sum(this.columnWidths*)
		dividersWidth := this.columnDividerString.length() * (this.columnWidths.count() - 1)
		
		return columnsWidth + dividersWidth
	}
	
	
	getContentHeight() {
		return this.dataTable.count()
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
