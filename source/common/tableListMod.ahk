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
	;  c (I,REQ) - Column that this mod applies to
	;  o (I,REQ) - Operation to perform, from MODOP_* constants above
	;  t (I,REQ) - Text that we will perform the action with
	;  l (I,REQ) - Label associated with this mod
	; RETURNS:        Reference to new TableListMod object
	;---------
	__New(c, o, t, l) {
		this.column    := c
		this.operation := o
		this.text      := t
		this.label     := l
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