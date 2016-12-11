/* Generic, flexible custom class for parsing lists.
	
	This class will read in a file (using TableList.parseFile()) and return an array of arrays, where each 2nd-level array corresponds to a row in the file (excluding mods, see below). The inner arrays will be the contents of each row, broken up by any number of tabs (>1 tabs are ignored until the next non-tab character), and changed based on the mods that were active at that point in the file.
	
	Certain characters have special meaning when parsing the lines of a file. They include:
		[ - Mod
			A line which begins with this character will be processed as a mod (see mod section below for details).
		
		# - Pass
			Any row that begins with one of these characters will not be broken up into multiple pieces, but will be a single-element array in the final output.
			Override (with an array) with settings["CHARS", "PASS"].
		
		; - Comment
			If at the beginning of a line (ignoring any whitespace before that), the line is ignored and not added to the array of lines.
			Override with settings["CHARS", "COMMENT"].
		
		( - Model
			You can have each line use string indices per value by creating a row that begins with this character. You can tab-separate this line to visually line up with your rows.
			Override with settings["CHARS", "MODEL"].
		
		<No default> - Placeholder
			Having this allows you to have a truly empty value for a column in a given row (useful when optional columns are in the middle).
			Override with settings["CHARS", "PLACEHOLDER"].
		
		| - Multiple
			In a row that's being split, if an individual column within the row has this character, then that entry will be an array of the pipe-delimited values.
	
	These settings are also available:
		settings["FORMAT", "SEPARATE_MAP"]
			Associative array of CHAR => NAME.
			Rows that begin with a character that's a key (CHAR) in this array will be:
				Split like the rest, but will be numerically indexed (even if a model row is given or DEFAULT_INDICES setting is set)
				Stored separately in TableList.separateRows[NAME]
			Example
				Settings
					settings["FORMAT", "SEPARATE_MAP"] := {")": "DATA_INDEX"}
					Model row
						(	NAME	ABBREV	DOACTION
				Input row
					)	A	B	C
				Output array (stored in TableList.separateRows["DATA_INDEX"])
					[1]	A
					[2]	B
					[3]	C
					
			
		settings["FORMAT", "DEFAULT_INDICES"]
			Numerically-indexed array that provides what string indices should be used. A model row will override this, and any data that falls outside of the given indices will be numerically indexed.
			Example
				Settings
					settings["FORMAT", "DEFAULT_INDICES"] := ["NAME", "ABBREV", "DOACTION"]
					(No model row)
				Input row
					A	B	C	D	E
				Output array (for the single row, stored in output)
					["NAME"]			A
					["ABBREV"]		B
					["DOACTION"]	C
					[4]				D
					[5]				E
		
		settings["FILTER", "COLUMN"]
			Which row to filter rows by, defaults to none.
		settings["FILTER", "VALUE"]
			Ignored unless settings["FILTER", "COLUMN"] is set.
			Any rows where the column specified by settings["FILTER", "COLUMN"] doesn't match the given value will be excluded from the output.
		settings["FILTER", "INCLUDE", "BLANKS"]
			If set to true (default), rows with no value in the filter column will be included in the output.
			
	
	The bulk of the utility that this class provides comes from mods. Mods are created by specially-formatted rows in the file, and are represented by TableListMod objects. Note that each mod object holds only one sort of operation, to one piece of affected rows - mod creation rows with multiple operations specified will result in one mod per operation. Mods are typically executed in the order that they were added, with the exception of the pre-process modifier (*, see below). The format for mod rows is as follows:
	
	1. Mod rows should always start and end with square brackets (start with [, end with ]).
	2. Mod rows may have any number of the following mod actions per line, separated by pipes (|):
			[] - Clear all mods
				A line with nothing but "[]" on it will clear all current mods added before that point in the file.
			
			b - Begin
				Adds the given string at the beginning of the part.
				Example
					Mods
						[b:eee]
					Input
						AAA
					Result
						eeeAAA
			
			e - End
				Adds the given string at the end of a part.
				Example
					Mods
						[e:eee]
					Input
						AAA
					Result
						AAAeee
			
			m(x,y) - Modify (x can be any number, y can be any number. y is optional and defaults to 0.)
				Changes the given string, replace the given range with the given text.
				Example
					Mods
						[m(2,3):eee]
					Input
						AAABBBCCCDDD
					Result
						AAeeeDDD
			
	3. Mod actions can be further changed by the following modifiers (placed at the beginning of the mod action, in order declared here):
			* - Pre-process mod
				Places that mod first in order of execution, before any mods above it.
				Example
					Mods
						[e:.exe]
						[*e:Portable]
					Input
						firefox
					Result
						firefoxPortable.exe
			
			{x} - Row part to modify with mod (x can be any number, defaults to 1)
				Sets which part of each row the mod will affect. Default is 1, first element.
				Example
					Mods
						[{3}b:AAA]
					Input
						W	X	Y	Z
					Result
						W
						X
						AAAY
						Z
			
	4. Mod rows may also have these modifiers (typically the first thing in the mod line, separated from other actions by pipes):
			+x - Add label (x can be any number)
				Labels all following mods on the same row with the given numeric label, which can be used to remove them from executing on further lines further on with the - operator.
				Example: adds action1 and action2 as mods, both with a label of 5.
					[+5|action1|action2]	
			
			-x - Remove mods with label (x can be any number)
				Removes all currently active mods with this label. Typically the only thing on its row.
				Example: Removes all mods with the label 5.
					[-5]
			
	

*/

class TableList {
	static debugNoRecurse := true
	static debugName := "TableList"
	
	static whiteSpaceChars := [ A_Space, A_Tab ]
	static multiEntryChar := "|"
	
	static preChar := "*"
	static addChar := "+"
	static remChar := "-"
	
	static modBeginChar  := "b"
	static modEndChar    := "e"
	static modModifyChar := "m"
	static modFirstChar  := "["
	
	__New() {
		this.init()
	}
	
	init(overrides) {
		; Initialize the objects.
		this.mods  := []
		this.table := []
		
		; Character defaults and overrides
		defaultChars := []
		defaultChars["DELIMITER"]   := A_Tab
		defaultChars["COMMENT"]     := ";"
		defaultChars["MODEL"]       := "("
		defaultChars["PLACEHOLDER"] := ""
		defaultChars["PASS"]        := ["#"] ; This one supports multiple entries
		this.chars := mergeArrays(defaultChars, overrides["CHARS"])
		
		; Format defaults and overrides
		this.separateMap := processOverride([], overrides["FORMAT", "SEPARATE_MAP"])
		this.indexLabels := processOverride([], overrides["FORMAT", "DEFAULT_INDICES"])
		
		; Other settings
		defaultFilter := []
		defaultFilter["INCLUDE","BLANKS"] := true
		this.filter := mergeArrays(defaultFilter, overrides["FILTER"])
		
		; DEBUG.popup("TableList", "Setup processing done", "Chars", this.chars, "Formats", this.formats, "Filter", this.filter)
	}
	
	parseFile(fileName, settings = "") {
		if(!fileName || !FileExist(fileName)) {
			; DEBUG.popup("File does not exist", fPath)
			return ""
		}
		
		; Read the file into an array.
		lines := fileLinesToArray(fileName)
		; DEBUG.popup("Filename", fileName, "Lines from file", lines)
		
		return this.parseList(lines, settings)
	}
	
	parseList(lines, settings = "") {
		this.init(settings)
		delim := this.chars["DELIMITER"]
		currItem := []
		
		; Loop through and do work on them.
		For i,row in lines {
			; Strip off any leading whitespace.
			Loop {
				firstChar := SubStr(row, 1, 1)
			
				if(!contains(TableList.whiteSpaceChars, firstChar)) {
					; DEBUG.popup("First not blank, moving on", firstChar)
					Break
				}
				
				; originalRow := row
				StringTrimLeft, row, row, 1
				; DEBUG.popup("Row", originalRow, "First Char", firstChar, "Trimmed", row)
			}
			
			; Squash any empty spots, so only one delimeter in between each element.
			Loop {
				if(!stringContains(row, delim delim))
					Break
				
				StringReplace, row, row, %delim%%delim%, %delim%
			}
			
			; Split up the row by tabs.
			rowBits := StrSplit(row, delim)
			firstChar := SubStr(row, 1, 1)
			; DEBUG.popup("Looking at row", row, "Bits", rowBits, "First char", firstChar)
			
			; Ignore it entirely if it's an empty line or beings with ; (a comment).
			if(firstChar = this.chars["COMMENT"] || firstChar = "") {
				; DEBUG.popup("Comment or blank line", firstChar)
			
			; Special row for modifying the current modifications in play.
			} else if(firstChar = this.modFirstChar) {
				; DEBUG.popup("Modifier Line", row, "First Char", firstChar)
				this.updateMods(row)
			
			; Special row for label/title later on, leave it untouched.
			} else if(contains(this.chars["PASS"], firstChar)) {
				; DEBUG.popup("Pass line", row, "First Char", firstChar)
				currItem := Object()
				currItem.Insert(row)
				this.table.Insert(currItem)
			
			; Separate characters mean that we split the row, but always store it numerically and separately from everything else.
			} else if(this.separateMap.hasKey(firstChar)) {
				; DEBUG.popup("Separate row", rowBits)
				this.parseSeparateRow(firstChar, rowBits)
			
			; Model row, causes us to use string subscripts instead of numeric per entry.
			} else if(firstChar = this.chars["MODEL"]) {
				this.parseModelRow(rowBits)
			
			; Normal line.
			} else {
				; Transform to use string indices if given.
				if(IsObject(this.indexLabels)) {
					tempBits := rowBits
					rowBits := []
					For i,value in tempBits {
						idxLabel := this.indexLabels[i]
						if(idxLabel)
							rowBits[idxLabel] := value
						else
							rowBits[i] := value
					}
					; DEBUG.popup("Bits before named indices", tempBits, "After named indices", rowBits)
				}
				
				; Apply any active modifications.
				currItem := this.applyMods(rowBits)
				
				; If any of the values were a placeholder, remove them now.
				For i,value in currItem.clone() { ; Have to clone array as calling .Delete changes the indices (causing us to miss some in our loop).
					if(value = this.chars["PLACEHOLDER"])
						currItem.Delete(i)
				}
				
				; Split up any entries that include the multiEntryChar (pipe by default).
				For i,value in currItem {
					if(stringContains(value, this.multiEntryChar))
						currItem[i] := StrSplit(value, this.multiEntryChar)
				}
				
				; DEBUG.popup("Normal Row", originalRow, "Input rowbits", rowBits, "Current Mods", this.mods, "Processed Row", currItem, "Table", this.table)
				if(this.shouldIncludeItem(currItem))
					this.table.Insert(currItem)
			}
			
		}
		
		return this.table
	}
	
	; If a filter is given, exclude any rows that don't fit.
	shouldIncludeItem(currItem) {
		valueToCompare := currItem[this.filter["COLUMN"]]
		
		if(!this.filter["COLUMN"])
			return true
		
		; DEBUG.popup("Filter column", this.filter["COLUMN"], "Filter value", this.filter["INCLUDE","VALUE"], "Value to compare", valueToCompare)
		if(this.filter["INCLUDE","BLANKS"] && !valueToCompare)
			return true
		
		if(valueToCompare = this.filter["INCLUDE","VALUE"])
			return true
		
		; Array case - multiple values in filter column.
		if(IsObject(valueToCompare) && contains(valueToCompare, this.filter["INCLUDE","VALUE"]))
			return true
		
		return false
	}
	
	; Function to deal with special model rows.
	parseModelRow(rowBits) {
		this.indexLabels := []
		
		rowBits.RemoveAt(1) ; Get rid of the "(" bit.
		; DEBUG.popup("Row bits", rowBits)
		
		For i,r in rowBits
			this.indexLabels[i] := r
		
		; DEBUG.popup("Index labels", this.indexLabels)
	}
	
	; Row that starts with a special char, where we keep the row split but don't apply mods or labels.
	parseSeparateRow(char, rowBits) {
		if(!IsObject(this.separateRows))
			this.separateRows := []
		
		rowBits.RemoveAt(1) ; Get rid of the separate char bit.
		; DEBUG.popup("Row bits", rowBits)
		
		this.separateRows[this.separateMap[char]] := rowBits
		; DEBUG.popup("Separate rows", this.separateRows)
	}

	; Update the given modifier string given the new one.
	updateMods(newRow) {
		; DEBUG.popup("Current Mods", this.mods, "New Mod", newRow)
		
		label := 0
		
		; Strip off the square brackets.
		newRow := SubStr(newRow, 2, -1)
		
		; If it's just blank, all previous mods are wiped clean.
		if(newRow = "") {
			this.mods := Object()
		} else {
			; Check for a remove row label.
			; Assuming here that it will be the first and only thing in the mod row.
			if(SubStr(newRow, 1, 1) = this.remChar) {
				remLabel := SubStr(newRow, 2)
				this.killMods(remLabel)
				label := 0
				
				return
			}
			
			; Split new into individual mods.
			newModsSplit := StrSplit(newRow, "|")
			; DEBUG.popup("Row", newRow, "Row Split", newModsSplit)
			For i,currMod in newModsSplit {
				firstChar := SubStr(currMod, 1, 1)
				
				; Check for an add row label.
				if(i = 1 && firstChar = this.addChar) {
					label := SubStr(currMod, 2)
					; DEBUG.popup("Adding label", label)
				} else {
					; Allow backwards stacking - that is, a later mod can go first in mod order.
					if(firstChar = this.preChar) {
						newMod := this.parseModLine(SubStr(currMod, 2), label)
						this.mods := insertFront(this.mods, newMod)
					} else {
						newMod := this.parseModLine(currMod, label)
						this.mods.Insert(newMod)
					}
				}
				
				; DEBUG.popup("Mod processed", currMod, "First Char", firstChar, "Label", label, "Premod", preMod, "Current Mods", this.mods)
			}
		}
	}

	; Takes a modifier string and spits out the mod object/array. Assumes no [] around it, and no special chars at start.
	parseModLine(modLine, label = 0) {
		origModLine := modLine
		
		currMod := new TableListMod(modLine, 1, 0, "", label, "")
		; MsgBox % currMod.__Class
		; MsgBox, % "Modline " modLine "`nIsObject " IsObject(currMod) "`nIsFunc " IsFunc(currMod.toDebugString) "`nDebug no recurse " currMod.debugNoRecurse
		
		; Next, check to see whether we have an explicit bit. Syntax: starts with {#}
		firstChar := SubStr(modLine, 1, 1)
		if(firstChar = "{") {
			closeCurlyPos := InStr(modLine, "}")
			currMod.bit := SubStr(modLine, 2, closeCurlyPos - 2)
			; DEBUG.popup(currMod.bit, "Which bit")
			
			modLine := SubStr(modLine, closeCurlyPos + 1)
			; DEBUG.popup(modLine, "Trimmed current mod")
		}
		
		; First character of remaining string indicates what sort of operation we're dealing with: b, e, or m.
		currMod.operation := Substr(modLine, 1, 1)
		if(currMod.operation = this.modBeginChar) {
			currMod.start := 1
		} else if(currMod.operation = this.modEndChar) {
			currMod.start := -1
		}
		
		; Shave that off too. (leaving colon)
		StringTrimLeft, modLine, modLine, 1
		
		; Figure out the rest of the innards: parentheses and string.
		commaPos := InStr(modLine, ",")
		closeParenPos := InStr(modLine, ")")
		
		; Snag the rest of the info.
		if(currMod.operation = this.modModifyChar) {
			currMod.text := SubStr(modLine, closeParenPos + 2)
			if(commaPos) { ; two arguments in parens.
				currMod.start := SubStr(modLine, 2, commaPos - 2)
				currMod.len := SubStr(modLine, commaPos + 1, closeParenPos - (commaPos + 1))
			} else {
				currMod.start := SubStr(modLine, 2, closeParenPos - 2)
				currMod.len := 0
			}
		} else {
			currMod.text := SubStr(modLine, 2)
		}
		
		; DEBUG.popup("Mod Line", origModLine, "Mod processed", currMod, "Comma position", commaPos, "Close paren position", closeParenPos)
		return currMod
	}

	; Kill mods with the given label.
	killMods(killLabel = 0) {
		; DEBUG.popup(killLabel, "Killing all mods with label")
		
		i := 1
		modsLen := this.mods.MaxIndex()
		Loop, %modsLen% {
			if(this.mods[i].label = killLabel) {
				; DEBUG.popup(mods[i], "Removing Mod")
				this.mods.Remove(i)
				i--
			}
			i++
		}
	}

	; Apply currently active string modifications to given row.
	applyMods(rowBits) {
		; DEBUG.popup("Row", row, "Row bits", rowBits)
		; origBits := rowBits
		
		; If there aren't any mods, just split the row and send it on.
		if(this.mods.MaxIndex() != "") {
			; Apply the mods.
			For i,currMod in this.mods {
				; beforeBits := rowBits
				
				rowBits := currMod.executeMod(rowBits)
				
				; DEBUG.popup("Row bits", beforeBits, "Mod to apply", currMod, "Processed bits", rowBits)
			}
			
			; DEBUG.popup("Row bits", origBits, "Finished bits", rowBits)
			return rowBits
		}
		
		return rowBits
	}
	
	toDebugString(numTabs = 0) {
		outStr .= DEBUG.buildDebugString("Mods", this.mods, numTabs)
		outStr .= DEBUG.buildDebugString("Table", this.table, numTabs)
		
		return outStr
	}
}