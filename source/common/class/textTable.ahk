/* This class takes a table of values and turns it into an aligned plain-text table.
	NOTE: This only really works with a monospace font, as it aligns based on characters.
	
	Example Usage
;		tt := new TextTable().addRow("val1", "val2", "val3")
;		tt.addRow("value4", "value5", "value6")
;		; OR
;		tt := new TextTable().addRows(["val1", "val2", "val3"], ["value4", "value5", "value6"])
;		
;		; Change settings, add more data
;		tt.setColumnDivider(" ")                      ; Divider between columns (1 space)
;		tt.setDefaultAlignment(TextAlignment.Center)  ; All columns default to centered
;		tt.setColumnAlignment(2, TextAlignment.Right) ; Column 2 (base-1 indexed)
;		tt.addRow("v7", "v8", "v9")                   ; Add a new row dynamically (settings still apply)
;		
;		; Generate output
;		output := tt.getText()
;		
;		output:
;		 val1    val2  val3 
;		value4 value5 value6
;		  v7       v8   v9  
;		
;		
;		; Borders example
;		tt := new TextTable().setBorderType(TextTable.BorderType_Line)
;		tt.setColumnDivider(" | ")
;		tt.setTopTitle("Fruits")
;		tt.setBottomTitle("Yum!")
;		tt.addRow("apple", "banana", "coconut")
;		output := tt.getText()
;		
;		output:
;		┌───────── Fruits ─────────┐
;		│ apple | banana | coconut │
;		└────────── Yum! ──────────┘
*/

class TextTable {
	;region ------------------------------ PUBLIC ------------------------------
	;region Border types
	static BorderType_None     := "NONE"      ; No border
	static BorderType_Line     := "LINE"      ; A thin line border using Unicode characters
	static BorderType_BoldLine := "BOLD_LINE" ; A thick line border using Unicode characters
	;endregion Border types
	
	;---------
	; PARAMETERS:
	;  title (I,OPT) - Title to show at the top of the table.
	;---------
	__New(title := "") {
		if(title != "")
			this.setTopTitle(title)
	}
	
	;---------
	; DESCRIPTION:    Set the title to show at the top of the table, as part of the border.
	; PARAMETERS:
	;  title (I,REQ) - The title to show
	; RETURNS:        this
	;---------
	setTopTitle(title) {
		this.topTitle := title
		return this
	}
	
	;---------
	; DESCRIPTION:    Set the title to show at the bottom of the table, as part of the border.
	; PARAMETERS:
	;  title (I,REQ) - The title to show
	; RETURNS:        this
	;---------
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
	
	;---------
	; DESCRIPTION:    Set the type of border to show the table with.
	; PARAMETERS:
	;  borderType (I,REQ) - The type of border to set, from .BorderType_* constants.
	; RETURNS:        this
	;---------
	setBorderType(borderType) {
		Switch borderType {
			Case this.BorderType_None:
				this.borderH  := ""
				this.borderV  := ""
				this.borderTL := ""
				this.borderTR := ""
				this.borderBL := ""
				this.borderBR := ""
				this.outerPaddingH := 0
				this.outerPaddingV := 0
				
			Case this.BorderType_Line:
				this.borderH  := "─" ; U+0x2500
				this.borderV  := "│" ; U+0x2502
				this.borderTL := "┌" ; U+0x250C
				this.borderTR := "┐" ; U+0x2510
				this.borderBL := "└" ; U+0x2514
				this.borderBR := "┘" ; U+0x2518
				this.outerPaddingH := 1
				this.outerPaddingV := 0
				
			Case this.BorderType_BoldLine:
				this.borderH  := "━" ; U+0x2501
				this.borderV  := "┃" ; U+0x2503
				this.borderTL := "┏" ; U+0x250F
				this.borderTR := "┓" ; U+0x2513
				this.borderBL := "┗" ; U+0x2517
				this.borderBR := "┛" ; U+0x251B
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
		newValues := DataLib.rebaseVariadicAry(newValues)
		
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
	
	;---------
	; DESCRIPTION:    Add multiple new rows to the table
	; PARAMETERS:
	;  newRows* (I,REQ) - Variadic parameter, pass in however many [cell, cell, cell] rows as desired.
	; RETURNS:        this
	;---------
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
		bodyWidth    := this.borderV.length()  + this.outerPaddingH + this.getContentWidth() + this.outerPaddingH + this.borderV.length()
		topLineWidth := this.borderTL.length() + 1                  + this.topTitle.length() + 1                  + this.borderTR.length() ; 1s for padding around title
		
		return DataLib.max(bodyWidth, topLineWidth)
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
	getText() {
		output := ""
		
		output := output.appendLine(this.generateTopBottomLine(this.topTitle, this.borderTL, this.borderTR))
		output .= StringLib.getNewlines(this.outerPaddingV)
		
		output := output.appendLine(this.generateContent())
		
		output .= StringLib.getNewlines(this.outerPaddingV)
		output := output.appendLine(this.generateTopBottomLine(this.bottomTitle, this.borderBL, this.borderBR))
		
		return output
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	topTitle            := ""                 ; Title to show above the table.
	bottomTitle         := ""                 ; Title to show below the table.
	dataTable           := []                 ; Our 2-dimensional array of values.
	columnWidths        := []                 ; Numbers of characters
	columnAlignments    := []                 ; TextAlignment.* values, defaults to this.defaultAlignment
	columnDividerString := "  "               ; The text that should divide columns in a row
	defaultAlignment    := TextAlignment.Left ; The default alignment for all cells
	
	outerPaddingH := 0  ; Spaces between borders and values on left/right
	outerPaddingV := 0  ; Lines between borders and values on top/bottom
	borderH       := "" ; Horizontal border character
	borderV       := "" ; Vertical border character
	borderTL      := "" ; Top-left corner border character
	borderTR      := "" ; Top-right corner border character
	borderBL      := "" ; Bottom-left corner border character
	borderBR      := "" ; Bottom-right corner border character
	
	;---------
	; DESCRIPTION:    Add a new row to the table, without extra handling for multi-line values.
	; PARAMETERS:
	;  newRow (I,REQ) - The array to add to the table.
	; SIDE EFFECTS:   Updates column widths
	;---------
	_addRow(newRow) {
		row := newRow.clone()
		
		; Do a little pre-processing on values and track columns' max width.
		For columnIndex,value in row {
			value := value.replace("`t", "{Tab}") ; We can't easily deal with the width of tabs, so replace them with something else instead
			row[columnIndex] := value
			
			this.columnWidths[columnIndex] := DataLib.max(this.columnWidths[columnIndex], value.length())
		}
		
		; Add the row to the table
		this.dataTable.push(row)
	}
	
	;---------
	; DESCRIPTION:    Generate the border line for the top or bottom of the table.
	; PARAMETERS:
	;  title       (I,OPT) - The title to show within the line. If blank, we'll just fill the space with more border.
	;  leftCorner  (I,OPT) - The left-corner character
	;  rightCorner (I,OPT) - The right-corner character
	; RETURNS:        The border line requested, or "" if no line is needed
	;---------
	generateTopBottomLine(title := "", leftCorner := "", rightCorner := "") {
		; Don't need the line at all if there's nothing to show.
		if(title = "" && leftCorner = "" && rightCorner = "" && this.borderH = "")
			return ""
		
		; Use spaces for any blank border characters, to ensure spacing stays correct
		lineH       := DataLib.coalesce(this.borderH, " ")
		leftCorner  := DataLib.coalesce(leftCorner,   " ")
		rightCorner := DataLib.coalesce(rightCorner,  " ")
		
		; If there's no title, it's just the corners + horizontal lines as needed.
		if(title = "")
			return leftCorner lineH.repeat(this.getInnerWidth()) rightCorner
		
		; Otherwise, center the title in the space with padding and borders around it.
		return leftCorner StringLib.padCenter(" " title " ", this.getInnerWidth(), lineH) rightCorner
	}
	
	;---------
	; DESCRIPTION:    Generate the content for the table, including side borders if needed.
	; RETURNS:        The text of the content of the table.
	;---------
	generateContent() {
		lineV := DataLib.coalesce(this.borderV, " ")
		padding := StringLib.getSpaces(this.outerPaddingH)
		
		content := ""
		For _,row in this.dataTable {
			rowString := ""
			
			For columnIndex,value in row {
				cellString := this.formatValue(value, columnIndex)
				rowString := rowString.appendPiece(this.columnDividerString, cellString)
			}
			
			rowString := padding rowString padding
			
			; Pad out the right edge if the title was wider.
			leftoverWidth := this.getInnerWidth() - rowString.length()
			rowString .= StringLib.getSpaces(leftoverWidth)
			
			if(this.borderV != "")
				rowString := lineV rowString lineV
			
			content := content.appendLine(rowString)
		}
		
		return content
	}
	
	;---------
	; DESCRIPTION:    Get the width of the inside of the table (everything except for the border characters).
	; RETURNS:        The width needed to fit everything in the table (content and title)
	;---------
	getInnerWidth() {
		bodyWidth    := this.outerPaddingH + this.getContentWidth() + this.outerPaddingH
		topLineWidth := 1                  + this.topTitle.length() + 1                  ; 1s for padding around title
		
		return DataLib.max(bodyWidth, topLineWidth)
	}
	
	;---------
	; DESCRIPTION:    Get the width of the content of the table (just the data + column dividers).
	; RETURNS:        Number of characters across for the table content
	;---------
	getContentWidth() {
		columnsWidth := DataLib.sum(this.columnWidths*)
		dividersWidth := this.columnDividerString.length() * (this.columnWidths.count() - 1)
		
		return columnsWidth + dividersWidth
	}
	
	;---------
	; DESCRIPTION:    Get the height of the table content (just the data).
	; RETURNS:        Number of lines tall the content is.
	;---------
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
		alignment := DataLib.coalesce(this.columnAlignments[columnIndex], this.defaultAlignment) ; Default to left-aligned
		
		Switch alignment {
			Case TextAlignment.Left:   return value.postPadToLength(width)
			Case TextAlignment.Right:  return value.prePadToLength(width)
			Case TextAlignment.Center: return this.centerPadToLength(value, width)
			Default:                   return value
		}
	}
	
	;---------
	; DESCRIPTION:    Center the given value within the provided number of characters wide.
	; PARAMETERS:
	;  value (I,REQ) - The value to center
	;  width (I,REQ) - The width to pad out to/center within.
	; RETURNS:        The padded value
	; NOTES:          If the leftover space is not evenly divisible, left side gets one extra space.
	;---------
	centerPadToLength(value, width) {
		numSpacesNeeded := width - value.length()
		numRightSpaces := numSpacesNeeded // 2 ; If there's an odd number, right gets one less (floor division)
		numLeftSpaces := numSpacesNeeded - numRightSpaces
		return StringLib.getSpaces(numLeftSpaces) value StringLib.getSpaces(numRightSpaces)
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
	;endregion ------------------------------ PRIVATE ------------------------------
}
