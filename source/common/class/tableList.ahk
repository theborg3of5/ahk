#Include tableListMod.ahk

/* Class that parses and processes a specially-formatted file. =--
	=-- Motivation
			The goal of the .tl/.tls file format is to allow the file to be formatted with tabs so that it looks like a table in plain text, regardless of the size of the contents.
			
			For example, say we want to store and reference a list of folder paths. A simple tab-delimited file might look something like this:
				AHK Config	AHK_CONFIG	C:\ahk\config
				AHK Source	AHK_SOURCE	C:\ahk\source
				Downloads	DOWNLOADS	C:\Users\user\Downloads
				VB6 Compile	VB6_COMPILE	C:\Users\user\Dev\Temp\Compile	EPIC_LAPTOP
				Music	MUSIC	C:\Users\user\Music	HOME_DESKTOP
				Music	MUSIC	C:\Users\user\Music	HOME_LAPTOP
				Music	MUSIC	D:\Music	EPIC_LAPTOP
			
			There's a few non-desirable things here:
				1. None of the columns align, because the content is different widths
				2. You can't have comments, to make it more obvious what rows in the file represent
				3. There's no way to reduce duplication (lots of "C:\Users\" above, and several lines that are nearly identical)
			
			Another option is an INI file, but that has issues of its own:
				1. The file gets very tall (many lines) very quickly
				2. There's no good way to see the values for all entities for a specific key
			
			So the goal is to have a file format that:
				1. Can be formatted like a table - this allows us to see the value for each entity (row) for each column
				2. Can be formatted so that columns are aligned nicely - without this, the table format is useless
				3. Contains features that allow us to de-duplicate some of the data therein
			
	--- File Format
			At its simplest, a TL file is a bunch of line which are tab-delimited, but each row can:
				1. Be indented (tabs and spaces at the beginning of the line) as desired with no effect on data
				2. Be indented WITHIN the line as desired - effectively, multiple tabs between columns are treated the same as a single tab
			So for our paths example above, we can now do this (would normally be tabs between terms, but I'm replacing them with spaces in this documentation so your tab width doesn't matter):
				AHK Config     AHK_CONFIG     C:\ahk\config
				AHK Source     AHK_SOURCE     C:\ahk\source
				Downloads      DOWNLOADS      C:\Users\user\Downloads
				VB6 Compile    VB6_COMPILE    C:\Users\user\Dev\Temp\Compile   EPIC_LAPTOP
				Music          MUSIC          C:\Users\user\Music              HOME_DESKTOP
				Music          MUSIC          C:\Users\user\Music              HOME_LAPTOP
				Music          MUSIC          D:\Music                         EPIC_LAPTOP
			
			We can also use comments, and add a key row (which this class will use as indices in the 2D array you get back):
				(  NAME           ABBREV         PATH                             MACHINE
				
				; AHK Folders
					AHK Config     AHK_CONFIG     C:\ahk\config
					AHK Source     AHK_SOURCE     C:\ahk\source
				
				; User Folders
					Downloads      DOWNLOADS      C:\Users\user\Downloads
					VB6 Compile    VB6_COMPILE    C:\Users\user\Dev\Temp\Compile   EPIC_LAPTOP
				
				; Music variations per machine
					Music          MUSIC          C:\Users\user\Music              HOME_DESKTOP
					Music          MUSIC          C:\Users\user\Music              HOME_LAPTOP
					Music          MUSIC          D:\Music                         EPIC_LAPTOP
			
			We can also use the Mods feature (see "Mods" section below) to de-duplicate some info:
				(  NAME           ABBREV         PATH              MACHINE
				
				; AHK Folders
				[PATH.addToStart(C:\ahk\)]
					AHK Config     AHK_CONFIG     config
					AHK Source     AHK_SOURCE     source
				[]
				
				; User Folders
				[PATH.addToStart(C:\Users\user\)]
					Downloads      DOWNLOADS      Downloads
					VB6 Compile    VB6_COMPILE    Dev\Temp\Compile  EPIC_LAPTOP
				[]
				
				; Music variations per machine
				[PATH.addToEnd(\Music)]
					Music          MUSIC          C:\Users\user     HOME_DESKTOP
					Music          MUSIC          C:\Users\user     HOME_LAPTOP
					Music          MUSIC          D:                EPIC_LAPTOP
				[]
			
	--- Mods
			A "Mod" (short for "modification") line allows you to apply the same changes to all following rows (until the mod(s) are cleared). They are formatted as follows:
				* They should start with the mod start ([) character and end with the mod end (]) character. Like other lines, they can be indented as desired.
				* A mod line can contain 0 or more mod actions, separated by the multi-entry (|) character.
				* Additional information about mod actions can be found in the TableListMod class.
			
			Some special meta mod actions (not covered by the TableListMod class):
				(none) - Clear all mods
					If no actions are specified at all (i.e. a line containing only "[]"), we will clear all previously added mods.
				
				+n - Add label (n can be any number)
					Labels all following mods on the same row with the given number, which can be used to specifically clear them later.
					Example:
						Mod line
							[+5|COL.addToStart(aaa)|COL.addToEnd(zzz)]
						Result
							Rows after this mod line will have "aaa" prepended and "zzz" appended to their COL column (same as if we'd left out the "+5|").
				
				-n - Remove mods with label (n can be any number)
					Removes all currently active mods with this label. Typically the only thing on its row.
					Example:
						Mod line
							[-5]
						Result
							If there was a mod with a label of 5, it will not apply to any rows after this line.
				
				For example, these two files have the same result:
					File A
						(     NAME           TYPE     COLOR
								Apple          FRUIT    RED
								Strawberry     FRUIT    RED
								Bell pepper    VEGGIE   RED
								Radish         VEGGIE   RED
								Cherry         FRUIT    RED
					File B
						(     NAME           TYPE     COLOR
						
						[COLOR.replaceWith(RED)]
							[+1|TYPE.replaceWith(FRUIT)]
								Apple
								Strawberry
								Cherry
							[-1]
							[+2|TYPE.replaceWith(VEGGIE)]
								Bell pepper    VEGGIE
								Radish         VEGGIE
							[-2]
						[]
			
	--- Special Characters
			At the start of a row:
				Ignore - ;
					If the line starts with this character (ignoring any whitespace before that), the line is ignored and not added to the table.
				
				Model - (
					This is the key row mentioned above - the 2D array that you get back will use these column headers as string indices into each "row" array.
				
				Setting - @
					Any row that begins with this is assumed to be of the form @SettingName=value. Settings can be accessed using the .settings property.
				
				Header - # (with a space after)
					Any row starting with this will be added to the .headers property instead of the main table, with its index being that of the next row added to the table.
				
				Mod start - [
					A line which begins with this character will be processed as a mod (see "Mods" section for details).
					
			Within a "normal" row (not started with any of the special characters above):
				Placeholder - - (hyphen)
					Having this allows you to have a truly empty value for a column in a given row (useful when optional columns are in the middle).
				
				Multi-entry - |
					If this is included in a value for a column, the value for that row will be an array of the pipe-delimited values.
			
			Within a mod row (after the MOD,START character, see "Mods" section for details):
				Mod add label - +
					Associate the mods on this line with the numeric label following this character.
					
				Mod remove label - - (hyphen)
					Remove all mods with the numeric label following this character.
					
				Mod end - ]
					Mod lines should end with this character.
			
	--- Other features
			Key rows
				The constructor's keyRowChars parameter can be used to separate certain rows from the others based on their starting character, excluding them from the main table. Instead, those rows (which will still be split and indexed based on the model row) are stored off using the key name given as part of the parameter, and are accessible using the .keyRow[<keyName>] property.
				Note that there should be only one row per character/key in this array.
				Example:
					File:
						(  NAME  ABBREV   VALUE
						)  0     2        1
						...
					Code:
						keyRowChars := {")": "OVERRIDE_INDEX"}
						tl := new TableList(filePath, "", keyRowChars)
						table := tl.getTable()
						overrideIndex := tl.keyRow["OVERRIDE_INDEX"]
					Result:
						table does not include row starting with ")"
						overrideIndex["ABBREV"] := 2
										 ["NAME"]   := 0
										 ["VALUE"]  := 1
			
			Filtering
				The table can be filtered in-place with .filterByColumn and .filterOutEmptyForColumn. Notably, .filterByColumn never filters out rows with a blank value for the provided column - .filterOutEmptyForColumn can be used to get rid of those if needed.
					
				Example:
					File:
						(  NAME     ABBREV   PATH                                         MACHINE
							Spotify  spot     C:\Program Files (x86)\Spotify\Spotify.exe   HOME_DESKTOP
							Spotify  spot     C:\Program Files\Spotify\Spotify.exe         EPIC_LAPTOP
							Spotify  spot     C:\Spotify\Spotify.exe                       ASUS_LAPTOP
							Firefox  fox      C:\Program Files\Firefox\firefox.exe         
					Code:
						tl := new TableList(filePath).filterByColumn("MACHINE", "HOME_DESKTOP")
						tl.filterOutEmptyForColumn("MACHINE")
						table := tl.getTable()
					Result:
						table[1, "NAME"]   = Spotify
						table[1, "ABBREV"] = spot
						table[1, "PATH"]   = C:\Program Files (x86)\Spotify\Spotify.exe
						<"Firefox" line excluded because it was blank for this column>
			
	--=
*/ ; --=

class TableList {
	; #PUBLIC#
	
	; Special characters
	static Char_Ignore      := ";"
	static Char_Model       := "("
	static Char_Setting     := "@"
	static Char_Header      := "# " ; Must include the space
	static Char_Placeholder := "-"
	static Char_MultiEntry  := "|"
	static Char_Mod_Start       := "["
	static Char_Mod_End         := "]"
	static Char_Mod_AddLabel    := "+"
	static Char_Mod_RemoveLabel := "-"
	
	;---------
	; DESCRIPTION:    Create a new TableList instance.
	; PARAMETERS:
	;  filePath    (I,REQ) - Path to the file to read from. May be a partial path if
	;                        FileLib.findConfigFilePath() can find the correct thing.
	;  keyRowChars (I,OPT) - Array of characters and key names to keep separate, see class
	;                        documentation for more info. If a row starts with one of the characters
	;                        included here, that row will not appear in the main table. Instead, it
	;                        will be available using the .keyRow[<keyName>] property. Note that the
	;                        row is still split and indexed based on the model row. Format (where
	;                        keyName is the string you'll use with .keyRow[<keyName>] to retrieve
	;                        the row later:
	;                        	keyRowChars[<char>] := keyName
	; RETURNS:        Reference to new TableList object
	;---------
	__New(filePath, keyRowChars := "") {
		if(!filePath)
			return ""
		
		filePath := FileLib.findConfigFilePath(filePath)
		if(!FileExist(filePath))
			return ""
		
		this.keyRowChars := keyRowChars
		
		lines := FileLib.fileLinesToArray(filePath)
		this.parseList(lines)
		
		; Apply any automatic filters.
		For _,filter in TableList.autoFilters
			this.filterByColumn(filter["COLUMN"], filter["VALUE"])
	}
	
	;---------
	; DESCRIPTION:    Add a filter that will apply to all TableList instances in this script, automatically.
	; PARAMETERS:
	;  filterColumn (I,REQ) - The column to filter on. We'll look at the value of each row in this column.
	;  filterValue  (I,REQ) - The value to filter on. Rows with this value (or blank) in the filter
	;                         column will pass and not be filtered out.
	;---------
	addAutomaticFilter(filterColumn, filterValue) {
		filter := {"COLUMN":filterColumn, "VALUE":filterValue}
		TableList.autoFilters.push(filter)
	}
	
	;---------
	; DESCRIPTION:    Retrieve the processed table from the file you just loaded.
	; RETURNS:        Processed table. Format:
	;                 	table[rowNum, column] := value
	;---------
	getTable() {
		return this.table
	}
	
	;---------
	; DESCRIPTION:    Remove all rows that fail the provided filter.
	; PARAMETERS:
	;  filterColumn (I,REQ) - The column to check
	;  filterValue  (I,REQ) - The value to check. In order to pass the filter (so to NOT be removed),
	;                         a row must either have this value, or a blank value, for the filterColumn.
	; RETURNS:        This object (for chaining)
	;---------
	filterByColumn(filterColumn, filterValue) { ; Blank values always pass filter - callers can use filterOutEmptyForColumn() to get rid of those.
		if(filterColumn = "" || filterValue = "")
			return this
		
		newTable   := []
		newHeaders := {} ; {firstRowNumberUnderHeader: headerText}
		For oldIndex,row in this.table {
			; If there's a header for this row, keep track of it until we can add it to an unfiltered
			; row (or another header overwrites it because it has no unfiltered rows)
			headerText := this._headers[oldIndex]
			if(headerText != "")
				currHeader := headerText
			
			if(this.rowPassesFilter(row, filterColumn, filterValue)) {
				newIndex := newTable.push(row)
				if(currHeader != "") {
					newHeaders[newIndex] := currHeader
					currHeader := "" ; We've saved the header, done.
				}
			}
		}
		
		this.table    := newTable
		this._headers := newHeaders
		return this
	}
	
	;---------
	; DESCRIPTION:    Remove all rows from the table that have a blank value in the provided column.
	; PARAMETERS:
	;  column (I,REQ) - The column to remove rows based on.
	; RETURNS:        This object (for chaining)
	;---------
	filterOutEmptyForColumn(column) {
		if(column = "")
			return this
		
		newTable   := []
		newHeaders := {} ; {firstRowNumberUnderHeader: headerText}
		For oldIndex,row in this.table {
			; If there's a header for this row, keep track of it until we can add it to an unfiltered
			; row (or another header overwrites it because it has no unfiltered rows)
			headerText := this._headers[oldIndex]
			if(headerText != "")
				currHeader := headerText
			
			if(row[column] != "") {
				newIndex := newTable.push(row)
				if(currHeader != "") {
					newHeaders[newIndex] := currHeader
					currHeader := "" ; We've saved the header, done.
				}
			}
		}
		
		this.table    := newTable
		this._headers := newHeaders
		return this
	}
	
	;---------
	; DESCRIPTION:    Get one column of values from the table, indexed by another column.
	; PARAMETERS:
	;  valueColumn      (I,REQ) - The column to get values from
	;  indexColumn      (I,REQ) - The column to index by
	;  tiebreakerColumn (I,OPT) - If multiple rows have the same value in indexColumn, this column
	;                             will be used to break a tie. If a row has a blank value in this
	;                             column, it will lose to a row that has a value in this column.
	; RETURNS:        Indexed array of values. Format:
	;                   outputValues[indexColumnValue] := valueColumnValue
	; NOTES:          Since the value in the index column is the new subscript, it's possible there
	;                 will be some overlap. In the event that we have multiple rows with the same
	;                 value, the first one wins, except for the tiebreaker case (see tiebreakerColumn)
	;---------
	getColumnByColumn(valueColumn, indexColumn, tiebreakerColumn := "") {
		if(valueColumn = "" || indexColumn = "")
			return ""
		
		rowsByColumn := this.getRowsByColumn(indexColumn, tiebreakerColumn)
		
		outputValues := {} ; {index: value}
		For index,row in rowsByColumn
			outputValues[index] := row[valueColumn]
		
		return outputValues
	}
	
	;---------
	; DESCRIPTION:    Get the rows in the table, indexed by a particular column.
	; PARAMETERS:
	;  indexColumn      (I,REQ) - The column to index rows by.
	;  tiebreakerColumn (I,OPT) - If multiple rows have the same value in indexColumn, this column
	;                             will be used to break a tie. If a row has a blank value in this
	;                             column, it will lose to a row that has a value in this column.
	; RETURNS:        Indexed array of rows. Format:
	;                   outputRows[indexColumnValue] := row
	; NOTES:          Since the value in the index column is the new subscript, it's possible there
	;                 will be some overlap. In the event that we have multiple rows with the same
	;                 value, the first one wins, except for the tiebreaker case (see tiebreakerColumn)
	;---------
	getRowsByColumn(indexColumn, tiebreakerColumn := "") {
		if(indexColumn = "")
			return ""
		
		outputRows := {} ; {index: row}
		For _,row in this.table {
			rowIndex := row[indexColumn]
			if(rowIndex = "") ; Rows with a blank index value are ignored
				Continue
			
			; First row per index is always kept (but could get replaced)
			if(outputRows[rowIndex] = "") {
				outputRows[rowIndex] := row
				Continue
			}
			
			; A new row can only replace an existing row if it "wins" in the tiebreaker column,
			; by having a value when the existing row doesn't.
			if(tiebreakerColumn != "") {
				if(outputRows[rowIndex, tiebreakerColumn] = "" && row[tiebreakerColumn] != "") 
					outputRows[rowIndex] := row
			}
		}
		
		return outputRows
	}
	
	;---------
	; DESCRIPTION:    The key row (that was excluded from the table, based on the constructor's
	;                 keyRowChars parameter) that matches the given name. Format:
	;                   row[column] := value
	; PARAMETERS:
	;  name (I,REQ) - The key name that was associated with the row that you want.
	;---------
	keyRow[name] {
		get {
			return this._keyRows[name]
		}
	}
	
	;---------
	; DESCRIPTION:    The settings extracted from the file. Format:
	;                   settings[name] := value
	;---------
	settings {
		get {
			return this._settings
		}
	}
	
	;---------
	; DESCRIPTION:    The section headers extracted from the file. Format, where rowNum matches the
	;                 row number of the first row in this section:
	;                   headers[rowNum] := value
	;---------
	headers {
		get {
			return this._headers
		}
	}
	
	
	; #PRIVATE#
	
	static autoFilters := [] ; Array of {"COLUMN":filterColumn, "VALUE":filterValue} objects
	
	mods        := []
	table       := []
	indexLabels := []
	keyRowChars := {} ; {character: label}
	
	_keyRows    := {} ; {keyRowLabel: rowObj}
	_settings   := {} ; {settingName: settingValue}
	_headers    := {} ; {firstRowNumberUnderHeader: headerText}
	
	;---------
	; DESCRIPTION:    Given an array of lines from a file, parse out the data into internal structures.
	; PARAMETERS:
	;  lines (I,REQ) - Numeric array of lines from the file.
	;---------
	parseList(lines) {
		; Loop through and do work on them.
		For i,row in lines {
			row := row.withoutWhitespace()
			
			; Reduce any sets of multiple tabs in a row to a single one.
			Loop {
				if(!row.contains(A_Tab A_Tab))
					Break
				row := row.replace(A_Tab A_Tab, A_Tab)
			}
			
			this.processRow(row)
		}
		
		; Debug.popup("TableList.parseList","Finish", "State",this)
	}
	
	;---------
	; DESCRIPTION:    Process a single line from the file. We will parse the line, determine which
	;                 type it is, and store it in the correct place (along with any additional
	;                 processing).
	; PARAMETERS:
	;  row (I,REQ) - Line from the file (string).
	;---------
	processRow(row) {
		if(!row)
			return
		if(row.startsWith(this.Char_Ignore))
			return
		
		firstChar := row.sub(1, 1)
		if(row.startsWith(this.Char_Setting))
			this.processSetting(row)
		
		else if(row.startsWith(this.Char_Model)) ; Model row, causes us to use string subscripts instead of numeric per entry.
			this.processModel(row)
		
		else if(row.startsWith(this.Char_Header))
			this.processHeader(row)
		
		else if(this.keyRowChars.hasKey(firstChar)) ; Key characters mean that we split the row, but always store it separately from everything else.
			this.processKey(row)
		
		else if(row.startsWith(this.Char_Mod_Start))
			this.processMod(row)
		
		else
			this.processNormal(row)
	}
	
	;---------
	; DESCRIPTION:    Given a row representing a setting, store off the value of that setting
	;                 for later use.
	; PARAMETERS:
	;  row (I,REQ) - Settings row that we're processing (string).
	;---------
	processSetting(row) {
		row := row.removeFromStart(this.Char_Setting)
		if(!row)
			return
		
		name  := row.beforeString("=")
		value := row.afterString("=")
		; Debug.popup("TableList.processSetting","Pulled out data", "Name",name, "Value",value)
		
		this._settings[name] := value
	}
	
	;---------
	; DESCRIPTION:    Parse a model row - this is what determines the string indices that we use for
	;                 each column in following rows.
	; PARAMETERS:
	;  row (I,REQ) - Model row to process (string).
	;---------
	processModel(row) {
		rowAry := row.split(A_Tab)
		rowAry.RemoveAt(1) ; Get rid of the "(" bit and shift elements to fill.
		this.indexLabels := rowAry
	}
	
	;---------
	; DESCRIPTION:    Saves off the setting in the provided settings row.
	; PARAMETERS:
	;  row (I,REQ) - Header row that we're processing (string).
	;---------
	processHeader(row) {
		headerText := row.removeFromStart(this.Char_Header)
		firstRowNumber := DataLib.forceNumber(this.table.MaxIndex()) + 1 ; First row that will be under this section header (the next one added)
		this._headers[firstRowNumber] := headerText
	}
	
	;---------
	; DESCRIPTION:    Parse a key row - this is one that we will split and index like a normal row,
	;                 but will store separately.
	; PARAMETERS:
	;  row (I,REQ) - Key row that we're processing (string).
	;---------
	processKey(row) {
		firstChar := row.sub(1, 1)
		rowAry := row.split(A_Tab)
		
		rowAry.RemoveAt(1) ; Get rid of the separate char bit (")").
		this.applyIndexLabels(rowAry)
		
		this._keyRows[this.keyRowChars[firstChar]] := rowAry
	}
	
	;---------
	; DESCRIPTION:    Update the active mods based on a given mod row.
	; PARAMETERS:
	;  row (I,REQ) - Mod row that we're processing (string).
	; SIDE EFFECTS:   May change the currently active mods
	;---------
	processMod(row) {
		label := 0
		
		; Strip off the starting/ending mod characters ([ and ] by default).
		row := row.removeFromStart(this.Char_Mod_Start)
		row := row.removeFromEnd(this.Char_Mod_End)
		
		; If it's just blank, all previous mods are wiped clean.
		if(row = "") {
			this.mods := []
		} else {
			; Check for a remove row label.
			; Assuming here that it will be the first and only thing in the mod row.
			if(row.startsWith(this.Char_Mod_RemoveLabel)) {
				remLabel := row.removeFromStart(this.Char_Mod_RemoveLabel)
				this.killMods(remLabel)
				label := 0
				
				return
			}
			
			; Split into individual mods.
			newModsSplit := row.split(this.Char_MultiEntry)
			For i,currMod in newModsSplit {
				; Check for an add row label.
				if(i = 1 && currMod.startsWith(this.Char_Mod_AddLabel))
					label := currMod.removeFromStart(this.Char_Mod_AddLabel)
				else
					this.mods.push(new TableListMod(currMod, label))
			}
		}
	}
	
	;---------
	; DESCRIPTION:    Parse a normal row - this is one that will be included in the processed table.
	; PARAMETERS:
	;  row (I,REQ) - Normal row to process (string).
	;---------
	processNormal(row) {
		rowAry := row.split(A_Tab)
		this.applyIndexLabels(rowAry)
		this.applyMods(rowAry)
		
		; If any of the values were a placeholder, remove them now.
		For i,value in rowAry.clone() ; Clone since we're deleting things.
			if(value = this.Char_Placeholder)
				rowAry.Delete(i)
		
		; Split up any entries that include the multi-entry character (pipe by default).
		For i,value in rowAry
			if(value.contains(this.Char_MultiEntry))
				rowAry[i] := value.split(this.Char_MultiEntry)
		
		this.table.push(rowAry)
	}
	
	;---------
	; DESCRIPTION:    Given an array representing a row in the table, switch it from numeric to
	;                 string indices (if defined by the model row).
	; PARAMETERS:
	;  rowAry (IO,REQ) - Numerically-indexed array representing a row in the table.
	;---------
	applyIndexLabels(ByRef rowAry) {
		if(DataLib.isNullOrEmpty(this.indexLabels))
			return
		
		rowObj := {}
		For i,value in rowAry {
			idxLabel := this.indexLabels[i]
			if(idxLabel)
				rowObj[idxLabel] := value
			else
				rowObj[i] := value
		}
		rowAry := rowObj
	}

	;---------
	; DESCRIPTION:    Apply active string mods to the given row array.
	; PARAMETERS:
	;  rowAry (IO,REQ) - Array representing a row in the table. 
	;---------
	applyMods(ByRef rowAry) {
		For i,currMod in this.mods
			currMod.executeMod(rowAry)
	}
	
	;---------
	; DESCRIPTION:    Remove any active mods that match the given label.
	; PARAMETERS:
	;  killLabel (I,OPT) - Numeric label to remove matching mods. Defaults to 0 (default label for all mods).
	;---------
	killMods(killLabel := 0) {
		For i,mod in this.mods
			if(mod.label = killLabel)
				this.mods.Delete(i)
	}
	
	;---------
	; DESCRIPTION:    Based on a filter (column and value to restrict to), determine whether the
	;                 given row array passes that filter.
	; PARAMETERS:
	;  row           (I,REQ) - A row in the table. May be an array or string.
	;  column        (I,OPT) - The column to filter on - we will check the value of this column
	;                          (index) in the row array to see if it matches filterValue.
	;  value         (I,OPT) - Only include rows which have this value (or blank) in their filter
	;                          column pass.
	; RETURNS:        True if we should exclude the row from the filtered table, false otherwise.
	;---------
	rowPassesFilter(row, filterColumn, filterValue) {
		valueToCompare := row[filterColumn]
		
		; Blank values always pass
		if(valueToCompare = "")
			return true
		
		; Check the value
		if(isObject(valueToCompare))
			return valueToCompare.contains(value)
		else
			return (valueToCompare = filterValue)
	}
	
	
	; #DEBUG#
	
	debugName := "TableList"
	debugToString(debugBuilder) {
		debugBuilder.addLine("Chars",         this.chars)
		debugBuilder.addLine("Key row chars", this.keyRowChars)
		debugBuilder.addLine("Index labels",  this.indexLabels)
		debugBuilder.addLine("Mods",          this.mods)
		debugBuilder.addLine("Key rows",      this._keyRows)
		debugBuilder.addLine("Settings",      this._settings)
		debugBuilder.addLine("Headers",       this._headers)
		debugBuilder.addLine("Table",         this.table)
	}
	; #END#
}
