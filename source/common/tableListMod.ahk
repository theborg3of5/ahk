/* Class which represents a particular change (mod action) that should be made to a "row" array in a TableList.
	
	A mod action is defined by a string using a particular syntax:
		{<columnName>}<operation>:<text>
			columnName - The name of the column that this mod action should apply to. This portion (including the {}) is optional - if not given the mod will affect the first column in the table.
			operation  - A letter (that matches one of the MODOP_* constants below) what we want to do (see "Operations" section).
			text       - The text that is used by the operation (see "Operations" section).
		Example:
			{PATH}b:C:\users\
		Result:
			All following rows will have the string "C:\users\" added to the beginning of their "PATH" column.
	
	The mod action also takes a numeric label, which is used by the parent TableList to remove specific mods later as needed.
	
	Operations
		The operation of a mod action determines how it changes the chosen column:
			r - Replace
				Replace the column.
				Example:
					Mod line
						[r:z]
					Normal line
						AAA
					Result
						z
			
			b - Begin
				Prepend to the column (add to the beginning).
				Example:
					Mod line
						[b:z]
					Normal line
						AAA
					Result
						zAAA
			
			e - End
				Append to the column (add to the end).
				Example:
					Mod line
						[e:z]
					Normal line
						AAA
					Result
						AAAz
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
	;  modActString (I,REQ) - String defining the mod. Format (explained in class documentation):
	;                         	{<columnName>}<operation>:<text>
	;  label        (I,REQ) - Label associated with this mod.
	; RETURNS:        Reference to new TableListMod object
	;---------
	__New(modActString, label) {
		; Check to see whether we have an explicit column. Syntax: line starts with {columnLabel}
		if(stringStartsWith(modActString, "{")) {
			this.column := getStringBetweenStr(modActString, "{", "}")
			modActString := getStringAfterStr(modActString, "}")
		}
		
		this.operation := getStringBeforeStr(modActString, ":")
		this.text      := getStringAfterStr(modActString, ":")
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