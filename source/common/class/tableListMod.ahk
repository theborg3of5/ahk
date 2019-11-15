/* Class which represents a particular change (mod action) that should be made to a "row" array in a TableList. --=
	
	A mod action is defined by a string using a particular syntax:
		COLUMN.OPERATION(TEXT)
			COLUMN    - The name of the column that this mod action should apply to.
			OPERATION - A string (that matches one of the TableListMod.Operation_* constants below) what we want to do (see "Operations" section).
			TEXT      - The text that is used by the operation (see "Operations" section).
		Example:
			PATH.addToStart(C:\users\)
		Result:
			All following rows will have the string "C:\users\" added to the beginning of their "PATH" column.
	
	The mod action also takes a numeric label, which is used by the parent TableList to remove specific mods later as needed.
	
	Operations
		The operation of a mod action determines how it changes the chosen column:
			replaceWith
				Replace the column.
				Example:
					Mod line
						[COL.replaceWith(z)]
					Normal line (COL column)
						AAA
					Result
						z
			
			addToStart
				Prepend to the column (add to the beginning).
				Example:
					Mod line
						[COL.addToStart(z)]
					Normal line (COL column)
						AAA
					Result
						zAAA
			
			addToEnd
				Append to the column (add to the end).
				Example:
					Mod line
						[COL.addToEnd(z)]
					Normal line (COL column)
						AAA
					Result
						AAAz
	
*/ ; =--

class TableListMod {
	; #PUBLIC#
	
	; Operation identifiers
	static Operation_Replace    := "replaceWith"
	static Operation_AddToStart := "addToStart"
	static Operation_AddToEnd   := "addToEnd"
	
	;---------
	; DESCRIPTION:    Create a new TableListMod instance.
	; PARAMETERS:
	;  modActString (I,REQ) - String defining the mod. Format (explained in class documentation):
	;                         	COLUMN.OPERATION(TEXT)
	;  label        (I,REQ) - Label associated with this mod.
	; RETURNS:        Reference to new TableListMod object
	;---------
	__New(modString, label) {
		this.labelFromParent := label
		
		; Pull the relevant info out of the string.
		this.column    := modString.beforeString(".")
		this.operation := modString.firstBetweenStrings(".", "(")
		this.text      := modString.allBetweenStrings("(", ")") ; Go to the last close-paren, to allow other close-parens in the string
		
		; Debug.popup("New TableListMod","Finished", "State",this)
	}
	
	;---------
	; DESCRIPTION:    Perform the action described in this mod on the given row.
	; PARAMETERS:
	;  row (IO,REQ) - Associative array of column names => column values for a single row.
	;                 Will be updated according to the action described in this mod.
	;---------
	executeMod(ByRef row) {
		columnValue := row[this.column]
		
		if(this.operation = TableListMod.Operation_Replace)
			newValue := this.text
		else if(this.operation = TableListMod.Operation_AddToStart)
			newValue := this.text columnValue
		else if(this.operation = TableListMod.Operation_AddToEnd)
			newValue := columnValue this.text
		
		; Debug.popup("Row", row, "Column value to modify", columnValue, "Operation", this.operation, "Text", this.text, "Result", newValue, "Mod",this)
		
		; Put the column back into the full row.
		row[this.column] := newValue
	}
	
	;---------
	; DESCRIPTION:    The label originally given for this mod action.
	;---------
	label {
		get {
			return this.labelFromParent
		}
	}
	
	
	; #PRIVATE#
	
	column          := ""
	operation       := ""
	text            := ""
	labelFromParent := ""
	
	
	; #DEBUG#
	
	debugName := "TableListMod"
	debugToString(debugBuilder) {
		debugBuilder.addLine("Column",    this.column)
		debugBuilder.addLine("Operation", this.operation)
		debugBuilder.addLine("Text",      this.text)
		debugBuilder.addLine("Label",     this.labelFromParent)
	}
	; #END#
}
