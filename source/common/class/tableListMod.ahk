/* Class which represents a particular change (mod action) that should be made to a "row" array in a TableList. --=
	
	A mod action is defined by a string using a particular syntax:
		~COLUMN.OPERATION(TEXT)
			COLUMN    - The name of the column that this mod action should apply to.
			OPERATION - A string (that matches one of the TableListMod.Operation_* constants below) what we want to do (see "Operations" section).
			TEXT      - The text that is used by the operation (see "Operations" section).
		Example:
			~PATH.addToStart(C:\users\)
		Result:
			All rows which the mod is applied to will have the string "C:\users\" added to the beginning of their "PATH" column.
	
	Operations
		The operation of a mod action determines how it changes the chosen column:
			replaceWith
				Replace the column.
				Example:
					Mod string
						~COL.replaceWith(z)
					Normal line (COL column)
						AAA
					Result
						z
			
			addToStart
				Prepend to the column (add to the beginning).
				Example:
					Mod string
						~COL.addToStart(z)
					Normal line (COL column)
						AAA
					Result
						zAAA
			
			addToEnd
				Append to the column (add to the end).
				Example:
					Mod string
						~COL.addToEnd(z)
					Normal line (COL column)
						AAA
					Result
						AAAz
	
*/ ; =--

class TableListMod {
	; #PUBLIC#
	
	static Char_TargetPrefix := "~"
	
	;---------
	; DESCRIPTION:    Create a new TableListMod instance.
	; PARAMETERS:
	;  modActString (I,REQ) - String defining the mod. Format (explained in class documentation):
	;                         	~COLUMN.OPERATION(TEXT)
	; RETURNS:        Reference to new TableListMod object
	;---------
	__New(modString) {
		; Pull the relevant info out of the string.
		this.column    := modString.firstBetweenStrings(this.Char_TargetPrefix, ".")
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
		
		; Each of these should have a matching stub + documentation in the TABLELIST STUBS - MOD OPERATIONS section. ; GDB TODO update
		if(this.operation = "replaceWith")
			newValue := this.text
		else if(this.operation = "addToStart")
			newValue := this.text columnValue
		else if(this.operation = "addToEnd")
			newValue := columnValue this.text
		
		; Debug.popup("Row", row, "Column value to modify", columnValue, "Operation", this.operation, "Text", this.text, "Result", newValue, "Mod",this)
		
		; Put the column back into the full row.
		row[this.column] := newValue
	}
	
	; GDB TODO add some highlighting for these start/end lines
	; @NPP-TABLELIST
	;---------
	; NPP-DEF-LINE:   addToStart(text)
	; DESCRIPTION:    Add the given text to the start of this column.
	; PARAMETERS:
	;  text (I,REQ) - Text to add to start.
	;---------
	
	;---------
	; NPP-DEF-LINE:   addToEnd(text)
	; DESCRIPTION:    Add the given text to the end of this column.
	; PARAMETERS:
	;  text (I,REQ) - Text to add to end.
	;---------
	
	;---------
	; NPP-DEF-LINE:   replaceWith(text)
	; DESCRIPTION:    Replace this column with the given value.
	; PARAMETERS:
	;  text (I,REQ) - Text to replace with.
	;---------
	; @NPP-TABLELIST-END
	
	
	; #PRIVATE#
	
	column    := "" ; The name of the column to operate on
	operation := "" ; The operation to perform
	text      := "" ; The text to use
	
	
	; #DEBUG#
	
	Debug_TypeName() {
		return "TableListMod"
	}
	; #END#
}
