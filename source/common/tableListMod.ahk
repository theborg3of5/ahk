/* Modification class for parsing lists.
*/

global MODOP_REPLACE := "r"
global MODOP_BEGIN   := "b"
global MODOP_END     := "e"

class TableListMod {
	column    := ""
	operation := ""
	text      := ""
	label     := ""
	
	;---------
	; DESCRIPTION:    Create a new TableListMod instance.
	; PARAMETERS:
	;  modActString (I,REQ) - String defining the mod.
	;  label        (I,REQ) - Label associated with this mod
	; RETURNS:        Reference to new TableListMod object
	;---------
	__New(modActString, label) {
		; Check to see whether we have an explicit column. Syntax: line starts with {columnLabel}
		if(doesStringStartWith(modActString, "{")) {
			modActString := removeStringFromStart(modActString, "{")
			closeCurlyPos := InStr(modActString, "}")
			this.column := subStr(modActString, 1, closeCurlyPos - 1)
			modActString := subStr(modActString, closeCurlyPos + 1)
		}
		
		this.operation := subStr(modActString, 1, 1)
		this.text      := subStr(modActString, 3) ; Ignore mod and colon at start
		this.label     := label
		
		; DEBUG.popup("New TableListMod","Finished", "State",this)
	}
	
	;---------
	; DESCRIPTION:    Perform the action described in this mod on the given row.
	; PARAMETERS:
	;  row (IO,REQ) - Associative array of column names => column values for a single row.
	;                 Will be updated according to the action described in this mod.
	;---------
	executeMod(ByRef row) {
		columnValue := row[this.column]
		
		if(this.operation = MODOP_REPLACE)
			newValue := this.text
		else if(this.operation = MODOP_BEGIN)
			newValue := this.text columnValue
		else if(this.operation = MODOP_END)
			newValue := columnValue this.text
		
		; DEBUG.popup("Row", row, "Column value to modify", columnValue, "Operation", this.operation, "Text", this.text, "Result", newValue, "Mod",this)
		
		; Put the column back into the full row.
		row[this.column] := newValue
	}
	
	; Debug info (used by the Debug class)
	debugName := "TableListMod"
	debugToString(debugBuilder) {
		debugBuilder.addLine("Column",    this.column)
		debugBuilder.addLine("Operation", this.operation)
		debugBuilder.addLine("Text",      this.text)
		debugBuilder.addLine("Label",     this.label)
	}
}