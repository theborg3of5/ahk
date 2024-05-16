#Include tableListMod.ahk

/* Class that parses and processes a specially-formatted file.
	Motivation
		The goal of the .tl/.tls file format is to allow the file to be formatted with tabs so that it looks like a table in plain text, regardless of the size of the contents.
		
		For example, say we want to store and reference a list of folder paths. A simple tab-delimited file might look something like this:
			AHK Config	AHK_CONFIG	C:\ahk\config
			AHK Source	AHK_SOURCE	C:\ahk\source
			Downloads	DOWNLOADS	C:\Users\user\Downloads
			VB6 Compile	VB6_COMPILE	C:\Users\user\Dev\Temp\Compile	WORK_LAPTOP
			Music	MUSIC	C:\Users\user\Music	HOME_DESKTOP
			Music	MUSIC	C:\Users\user\Music	HOME_LAPTOP
			Music	MUSIC	D:\Music	WORK_LAPTOP
		
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
		
	File Format
		At its simplest, a TL file is a bunch of line which are tab-delimited, but each row can:
			1. Be indented (tabs and spaces at the beginning of the line) as desired with no effect on data
			2. Be indented WITHIN the line as desired - effectively, multiple tabs between columns are treated the same as a single tab
		So for our paths example above, we can now do this (would normally be tabs between terms, but I'm replacing them with spaces in this documentation so your tab width doesn't matter):
			AHK Config     AHK_CONFIG     C:\ahk\config
			AHK Source     AHK_SOURCE     C:\ahk\source
			Downloads      DOWNLOADS      C:\Users\user\Downloads
			VB6 Compile    VB6_COMPILE    C:\Users\user\Dev\Temp\Compile   WORK_LAPTOP
			Music          MUSIC          C:\Users\user\Music              HOME_DESKTOP
			Music          MUSIC          C:\Users\user\Music              HOME_LAPTOP
			Music          MUSIC          D:\Music                         WORK_LAPTOP
		
		We can also use comments, and add a model row (which this class will use as indices in the 2D array you get back):
			[  NAME           ABBREV         PATH                             MACHINE	]
			
			; AHK Folders
				AHK Config     AHK_CONFIG     C:\ahk\config
				AHK Source     AHK_SOURCE     C:\ahk\source
			
			; User Folders
				Downloads      DOWNLOADS      C:\Users\user\Downloads
				VB6 Compile    VB6_COMPILE    C:\Users\user\Dev\Temp\Compile   WORK_LAPTOP
			
			; Music variations per machine
				Music          MUSIC          C:\Users\user\Music              HOME_DESKTOP
				Music          MUSIC          C:\Users\user\Music              HOME_LAPTOP
				Music          MUSIC          D:\Music                         WORK_LAPTOP
		
		We can also use the Mods feature (see "Mods" section below) to de-duplicate some info:
			[  NAME           ABBREV         PATH              MACHINE	]
			
			; AHK Folders
			~PATH.addToStart(C:\ahk\) {
				AHK Config     AHK_CONFIG     config
				AHK Source     AHK_SOURCE     source
			}
			
			; User Folders
			~PATH.addToStart(C:\Users\user\) {
				Downloads      DOWNLOADS      Downloads
				VB6 Compile    VB6_COMPILE    Dev\Temp\Compile  WORK_LAPTOP
			}
			
			; Music variations per machine
			~PATH.addToEnd(\Music) {
				Music          MUSIC          C:\Users\user     HOME_DESKTOP
				Music          MUSIC          C:\Users\user     HOME_LAPTOP
				Music          MUSIC          D:                WORK_LAPTOP
			}
		
	Mods
		A "Mod" (short for "modification") line allows you to apply the same changes to all following rows (until the mod(s) are cleared). They are formatted as follows:
			* Individual mod strings (in format ~COLUMN.OPERATION(TEXT)) are separated by a pipe (|).
			* The lines that a mod affects are wrapped in curly brackets:
				* Any line that adds mods should end with an opening bracket ({)
				* Closing brackets may be their own line, or may start another line (a la else-if statements).
			* Like other lines, they can be indented as desired.
			* Additional information about mod actions can be found in the TableListMod class.
		
		For example, these two files have the same result:
			File A
				[	NAME           TYPE     COLOR	VALUE	]
					Apple          FRUIT    RED
					Strawberry     FRUIT    RED		
					Bell pepper    VEGGIE   RED
					Radish         VEGGIE   RED		5
					Cherry         FRUIT    RED		5
			File B
				[		NAME           TYPE     COLOR		VALUE	]
				
				~COLOR.replaceWith(RED) {
					~TYPE.replaceWith(FRUIT) {
						Apple
						Strawberry
						Cherry
					} ~TYPE.replaceWith(VEGGIE) | ~VALUE.replaceWith(5) {
						Bell pepper    VEGGIE
						Radish         VEGGIE
					}
				}
	
	Special Characters
		At the start of a row:
			Ignore - ;
				If the line starts with this character (ignoring any whitespace before that), the line is ignored and not added to the table.
			
			Model - [
				This is the model row mentioned above - the 2D array that you get back will use these column headers as string indices into each "row" array.
				The row should end with the corresponding ending character (a closing bracket)
			
			Column info - (
				Similar to the model row, this row stores information about each column as a whole. This will be stored separately from the normal rows, and can be retrieved via the .columnInfo property.
				The row should end with the corresponding ending character (a closing paren)
			
			Setting - @
				Any row that begins with this is assumed to be of the form @SettingName(value). Settings can be accessed using the .settings property.
			
			Header - # (with a space after)
				Any row starting with this will be added to the .headers property instead of the main table, with its index being that of the next row added to the table.
			
			Mods - ~ or }
				A line which begins with either of these characters will be processed as a mod (see "Mods" section for details).
				
		Within a "normal" row (not started with any of the special characters above):
			Placeholder - - (hyphen)
				Having this allows you to have a truly empty value for a column in a given row (useful when optional columns are in the middle).
			
			Multi-entry - |
				If this is included in a value for a column, the value for that row will be an array of the pipe-delimited values.
				If you need to include this character in your actual value, simply escape it with backslash (i.e. \|)
		
		Within a mod row (see "Mods" section for details):
			Mod apply open - {
				This should appear at the end of a mod row that's adding a new set of mods.
			Mod apply close - }
				This can appear at the start of the mod line instead of on its own line, for else-if-style bracketing.
		
	Other features
		Column info row
			Using the column info character, you can provide information about each column as a whole. Just start a row with that character, and the caller can retrieve that info, indexed by column name, using the .columnInfo property.
			Note that there should only be one column info row per file - if there are multiple, only the last one will be available via the property.
			Example:
				File:
					[  NAME  ABBREV   VALUE	]
					(  0     2        1		)
					...
				Code:
;					tl := new TableList(filePath)
;					table := tl.getTable()
;					overrideIndex := tl.columnInfo
				Result:
					table does not include the column info row
					overrideIndex["ABBREV"] := 2
										["NAME"]   := 0
										["VALUE"]  := 1
		
		Filtering
			The table can be filtered in-place with .filterOutIfColumn[No]Match and .filterOutIfColumnBlank. Notably, .filterOutIfColumn[No]Match never filters out rows with a blank value for the provided column - .filterOutIfColumnBlank can be used to get rid of those if needed.
				
			Example:
				File:
					[  NAME     ABBREV   PATH                                         MACHINE	]
						Spotify  spot     C:\Program Files (x86)\Spotify\Spotify.exe   HOME_DESKTOP
						Spotify  spot     C:\Program Files\Spotify\Spotify.exe         WORK_LAPTOP
						Spotify  spot     C:\Spotify\Spotify.exe                       ASUS_LAPTOP
						Firefox  fox      C:\Program Files\Firefox\firefox.exe
				Code:
;					tl := new TableList(filePath).filterOutIfColumnNoMatch("MACHINE", "HOME_DESKTOP")
;					tl.filterOutIfColumnBlank("MACHINE")
;					table := tl.getTable()
				Result:
					table[1, "NAME"]   = Spotify
					table[1, "ABBREV"] = spot
					table[1, "PATH"]   = C:\Program Files (x86)\Spotify\Spotify.exe
					<"Firefox" line excluded because it was blank for this column>
*/

class TableList {
	;region ------------------------------ PUBLIC ------------------------------
	;region Special characters within a TableList file
	static Char_Ignore           := ";"  ; Ignore (comment) character
	static Char_Model_Start      := "["  ; The start of the model row
	static Char_Model_End        := "]"  ; The end of the model row
	static Char_ColumnInfo_Start := "("  ; The start of the column info row
	static Char_ColumnInfo_End   := ")"  ; The start of the column info row
	static Char_Setting          := "@"  ; Settings prefix
	static Char_Header           := "# " ; Header character (must include the trailing space)
	static Char_Placeholder      := "-"  ; Placeholder character
	static Char_MultiEntry       := "|"  ; Multi-entry character
	static Char_Mod_Open         := "{"  ; The character which starts applying mods to rows.
	static Char_Mod_Close        := "}"  ; The character which stops applying mods to rows.
	static Char_MultiEscape      := "\"  ; Escape character used to include multi-entry character in normal values.
	;endregion Special characters within a TableList file
	
	;---------
	; DESCRIPTION:    Information about each column, from the column info row of the file (assuming
	;                 one existed).
	;---------
	columnInfo {
		get {
			return this._columnInfo
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
	
	;---------
	; DESCRIPTION:    Create a new TableList instance.
	; PARAMETERS:
	;  filePath    (I,REQ) - Path to the file to read from. May be a partial path if
	;                        FileLib.findConfigFilePath() can find the correct thing.
	; RETURNS:        Reference to new TableList object
	;---------
	__New(filePath) {
		if(!filePath)
			return ""
		
		filePath := FileLib.findConfigFilePath(filePath)
		if(!FileExist(filePath))
			return ""
		
		lines := FileLib.fileLinesToArray(filePath)
		this.parseList(lines)
		
		; Apply any automatic filters.
		For _,filter in TableList.autoFilters
			this.filterOutIfColumnNoMatch(filter["COLUMN"], filter["VALUE"])
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
	; DESCRIPTION:    Remove all rows that do NOT have the given value (or blank) in the specified column.
	; PARAMETERS:
	;  filterColumn (I,REQ) - The column to check
	;  filterValue  (I,REQ) - The value to check
	; RETURNS:        This object (for chaining)
	; NOTES:          Rows with a blank value for the specified column will not be touched - use filterOutIfColumnBlank()
	;                 to get rid of those if needed.
	;---------
	filterOutIfColumnNoMatch(filterColumn, filterValue) {
		this.doFilterOnColumn(filterColumn, filterValue, true, true)
		return this
	}
	
	;---------
	; DESCRIPTION:    Remove all rows that have the given value (or blank) in the specified column.
	; PARAMETERS:
	;  filterColumn (I,REQ) - The column to check
	;  filterValue  (I,REQ) - The value to check
	; RETURNS:        This object (for chaining)
	; NOTES:          Rows with a blank value for the specified column will not be touched - use filterOutIfColumnBlank()
	;                 to get rid of those if needed.
	;---------
	filterOutIfColumnMatch(filterColumn, filterValue) {
		this.doFilterOnColumn(filterColumn, filterValue, false, true)
		return this
	}
	
	;---------
	; DESCRIPTION:    Remove all rows from the table that have a blank value in the provided column.
	; PARAMETERS:
	;  filterColumn (I,REQ) - The column to check
	; RETURNS:        This object (for chaining)
	;---------
	filterOutIfColumnBlank(filterColumn) {
		this.doFilterOnColumn(filterColumn, "", false, false)
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
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	static autoFilters := [] ; Array of {"COLUMN":filterColumn, "VALUE":filterValue} objects
	
	modSets     := [] ; Array of sets of mods, treated like a stack.
	table       := []
	indexLabels := []
	
	_columnInfo := {} ; {columnName: value}
	_settings   := {} ; {settingName: settingValue}
	_headers    := {} ; {firstRowNumberUnderHeader: headerText}
	
	;---------
	; DESCRIPTION:    Given an array of lines from a file, parse out the data into internal structures.
	; PARAMETERS:
	;  linesAry (I,REQ) - Numeric array of lines from the file.
	;---------
	parseList(linesAry) {
		; Loop through and do work on them.
		For _,row in linesAry {
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
		
		if(row.startsWith(this.Char_Setting))
			this.processSetting(row)
		
		else if(row.startsWith(this.Char_Model_Start) && row.endsWith(this.Char_Model_End)) ; Model row, tells us which string subscripts to use for columns.
			this.processModel(row)
		
		else if(row.startsWith(this.Char_Header))
			this.processHeader(row)
		
		else if(row.startsWith(this.Char_ColumnInfo_Start) && row.endsWith(this.Char_ColumnInfo_End))
			this.processColumnInfo(row)
		
		else if(row.startsWith(TableListMod.Char_TargetPrefix) || row.startsWith(this.Char_Mod_Close))
			this.processMods(row)
		
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
		
		name  := row.beforeString("(")
		value := row.allBetweenStrings("(", ")")
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
		
		rowAry.removeAt(1) ; Get rid of the leading "[" (and shift elements to fill).
		rowAry.pop() ; Get rid of the ending "]"
		
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
	; DESCRIPTION:    Save off the column-level info in this row.
	; PARAMETERS:
	;  row (I,REQ) - Column info row to process.
	;---------
	processColumnInfo(row) {
		rowAry := row.split(A_Tab)
		
		rowAry.removeAt(1) ; Get rid of the leading "(" (and shift elements to fill).
		rowAry.pop() ; Get rid of the ending ")"
		this.applyIndexLabels(rowAry)
		
		this._columnInfo := rowAry
	}
	
	;---------
	; DESCRIPTION:    Update the active mods based on a given mod row.
	; PARAMETERS:
	;  row (I,REQ) - Mod row that we're processing (string).
	; SIDE EFFECTS:   May change the currently active mods
	;---------
	processMods(row) {
		; A closing bracket means we're remove the last set of mods.
		if(row.startsWith(this.Char_Mod_Close)) {
			this.modSets.pop()
			row := row.removeFromStart(this.Char_Mod_Close).withoutWhitespace()
		}
		; If we were only closing the last mode, we're done.
		if(row = "")
			return
		
		; An opening bracket at the end means we're opening new mods.
		if(row.endsWith(this.Char_Mod_Open)) {
			row := row.removeFromEnd(this.Char_Mod_Open).withoutWhitespace()
			newMods := []
			For _,modString in row.split("|", A_Space)
				newMods.push(new TableListMod(modString))
			
			; Add the set of new mods to our stack of them.
			this.modSets.push(newMods)
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
		
		; If any of the values were a placeholder, remove them now.
		For i,value in rowAry.clone() ; Clone since we're deleting things.
			if(value = this.Char_Placeholder)
				rowAry.Delete(i)
		
		; Split up any entries that include the multi-entry character (pipe).
		For i,value in rowAry {
			if(value.contains(this.Char_MultiEntry))
				rowAry[i] := this.splitMultiEntry(value)
		}
		
		; Apply any active mods.
		this.applyMods(rowAry)
		
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
		For _,modSet in this.modSets {
			For _,mod in modSet
				mod.executeMod(rowAry)
		}
	}
	
	;---------
	; DESCRIPTION:    Split a multi-entry value into an array.
	; PARAMETERS:
	;  value (I,REQ) - The value to split (assumed to contain Char_MultiEntry [pipe]).
	; RETURNS:        Appropriately-split value, either a string (if value only contained escaped pipes) or an array.
	; SIDE EFFECTS:   Unescapes any escaped pipes (after splitting on any non-escaped pipes).
	;---------
	splitMultiEntry(value) {
		value := value.replace(this.Char_MultiEscape this.Char_MultiEntry, "<PLACEHOLDER>") ; Temporarily replace escaped pipes
		
		; Only escaped pipes, just return the original value (unescaping the pipes)
		if(!value.contains(this.Char_MultiEntry))
			return value.replace("<PLACEHOLDER>", this.Char_MultiEntry)
		
		; Split it up and put back escaped (now unescaped) pipes.
		valueAry := value.split(this.Char_MultiEntry, A_Space)
		For i,piece in valueAry
			valueAry[i] := piece.replace("<PLACEHOLDER>", this.Char_MultiEntry)
		
		return valueAry
	}
	
	;---------
	; DESCRIPTION:    Filter the table rows based on the given filter.
	; PARAMETERS:
	;  filterColumn   (I,REQ) - The column to filter on - we'll consider the value(s) in each row for this column.
	;  filterValue    (I,REQ) - The value to filter based on.
	;  includeMatches (I,REQ) - true to include rows that match the given value, false to exclude them instead. Defaults to true (include).
	;  blanksAreWild  (I,OPT) - If true, blank values in the given column are treated as wildcards, so they stay in the table
	;                           regardless of whether the filter is including or excluding matches. Defaults to true (blanks will
	;                           always be included).
	; SIDE EFFECTS:   Updates this.table and this._headers.
	;---------
	doFilterOnColumn(filterColumn, filterValue, includeMatches, blanksAreWild := true) {
		if(filterColumn = "")
			return
		
		newTable   := []
		newHeaders := {} ; {firstRowNumberUnderHeader: headerText}
		For rowNum,row in this.table {
			; If there's a header for this row, keep track of it until we can add it to an unfiltered
			; row (or another header overwrites it because this one has no unfiltered rows)
			headerText := this._headers[rowNum]
			if(headerText != "")
				currHeader := headerText
			
			rowIsMatch := this.rowMatchesFilter(row, filterColumn, filterValue, blanksAreWild)
			if(includeMatches && rowIsMatch || !includeMatches && !rowIsMatch) {
				newIndex := newTable.push(row)
				if(currHeader != "") {
					newHeaders[newIndex] := currHeader
					currHeader := "" ; We've inserted the header, no longer need to hold it.
				}
			}
		}
		
		this.table    := newTable
		this._headers := newHeaders
	}
	
	;---------
	; DESCRIPTION:    Based on a filter (column and value to restrict to), determine whether the given row array passes
	;                 that filter.
	; PARAMETERS:
	;  row           (I,REQ) - A row in the table. The value inside can be a string or array (to allow for multi-entry values).
	;  filterColumn  (I,REQ) - The column to filter on - we will check the value of this column (index) in the row array to see if
	;                          it matches filterValue.
	;  filterValue   (I,REQ) - Only include rows which have this value (or possibly blank, see blanksAreWild parameter) in their
	;                          filter column pass.
	;  blanksAreWild (I,OPT) - If this is true, blank values are treated as wildcards and will always pass the filter.
	; RETURNS:        true if the row passes the filter and can stay, false if it should be filtered out.
	;---------
	rowMatchesFilter(row, filterColumn, filterValue, blanksAreWild := true) {
		value := row[filterColumn]
		
		if(blanksAreWild && value = "")
			return true
		
		if(isObject(value))
			return value.contains(filterValue)
		else
			return (value = filterValue)
	}
	;endregion ------------------------------ PRIVATE ------------------------------
	
	;region ------------------------------ DEBUG ------------------------------
	Debug_ToString(ByRef table) {
		table.addLine("Index labels", this.indexLabels)
		table.addLine("Mods",         this.modSets)
		table.addLine("Column info",  this._columnInfo)
		table.addLine("Settings",     this._settings)
		table.addLine("Headers",      this._headers)
		table.addLine("Table",        this.table)
	}
	;endregion ------------------------------ DEBUG ------------------------------
}
