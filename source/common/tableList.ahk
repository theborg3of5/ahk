#Include tableListMod.ahk

/* Class that parses and processes a specially-formatted file.
	
	Motivation
		The goal of the .tl file format is to allow the file to be formatted with tabs so that it looks like a table in plain text, regardless of the size of the contents.
		
		For example, say we want to store and reference a list of folder paths. A simple tab-delimited file might look something like this:
			AHK Config	AHK_CONFIG	C:\ahk\config
			AHK Source	AHK_SOURCE	C:\ahk\source
			Downloads	DOWNLOADS	C:\Users\user\Downloads
			VB6 Compile	VB6_COMPILE	C:\Users\user\Dev\Temp\Compile	EPIC_LAPTOP
			Music	MUSIC	C:\Users\user\Music	HOME_DESKTOP
			Music	MUSIC	C:\Users\user\Music	HOME_ASUS
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
		
	File Format
		At its simplest, a TL file is a bunch of line which are tab-delimited, but each row can:
			1. Be indented (tabs and spaces at the beginning of the line) as desired with no effect on data
			2. Be indented WITHIN the line as desired - effectively, multiple tabs between columns are treated the same as a single tab
		So for our paths example above, we can now do this (would normally be tabs between terms, but I'm replacing them with spaces in this documentation so your tab width doesn't matter):
			AHK Config     AHK_CONFIG     C:\ahk\config
			AHK Source     AHK_SOURCE     C:\ahk\source
			Downloads      DOWNLOADS      C:\Users\user\Downloads
			VB6 Compile    VB6_COMPILE    C:\Users\user\Dev\Temp\Compile   EPIC_LAPTOP
			Music          MUSIC          C:\Users\user\Music              HOME_DESKTOP
			Music          MUSIC          C:\Users\user\Music              HOME_ASUS
			Music          MUSIC          D:\Music                         EPIC_LAPTOP
		
		We can also use comments, and add a header row (which this class will use as indices in the 2D array you get back):
			(  NAME           ABBREV         PATH                             MACHINE
			
			; AHK Folders
			   AHK Config     AHK_CONFIG     C:\ahk\config
			   AHK Source     AHK_SOURCE     C:\ahk\source
			
			; User Folders
			   Downloads      DOWNLOADS      C:\Users\user\Downloads
			   VB6 Compile    VB6_COMPILE    C:\Users\user\Dev\Temp\Compile   EPIC_LAPTOP
			
			; Music variations per machine
			   Music          MUSIC          C:\Users\user\Music              HOME_DESKTOP
			   Music          MUSIC          C:\Users\user\Music              HOME_ASUS
			   Music          MUSIC          D:\Music                         EPIC_LAPTOP
		
		We can also use the Mods feature (see "Mods" section below) to de-duplicate some info:
			(  NAME           ABBREV         PATH              MACHINE
			
			; AHK Folders
			[{PATH}b:C:\ahk\]
			   AHK Config     AHK_CONFIG     config
			   AHK Source     AHK_SOURCE     source
			[]
			
			; User Folders
			[{PATH}b:C:\Users\user\]
			   Downloads      DOWNLOADS      Downloads
			   VB6 Compile    VB6_COMPILE    Dev\Temp\Compile  EPIC_LAPTOP
			[]
			
			; Music variations per machine
			[{PATH}e:\Music]
			   Music          MUSIC          C:\Users\user     HOME_DESKTOP
			   Music          MUSIC          C:\Users\user     HOME_ASUS
			   Music          MUSIC          D:                EPIC_LAPTOP
			[]
		
	Mods
		A "Mod" (short for "modification") line allows you to apply the same changes to all following rows (until the mod(s) are cleared). They are formatted as follows:
			* They should start with the MOD,START ([) character and end with the MOD,END (]) character. Like other lines, they can be indented as desired.
			* A mod line can contain 0 or more mod actions, separated by the MOD,DELIM (|) character.
			* Additional information about mod actions can be found in the TableListMod class.
		
		Some special meta mod actions (not covered by the TableListMod class):
			(none) - Clear all mods
				If no actions are specified at all (i.e. a line containing only "[]"), we will clear all previously added mods.
				
			+n - Add label (n can be any number)
				Labels all following mods on the same row with the given number, which can be used to specifically clear them later.
				Example:
					Mod line
						[+5|b:aaa|e:zzz]
					Result
						Rows after this mod line will have "aaa" prepended and "zzz" appended to their first column (same as if we'd left out the "+5|").
				
			-n - Remove mods with label (n can be any number)
				Removes all currently active mods with this label. Typically the only thing on its row.
				Example:
					Mod line
						[-5]
					Result
			
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
					
					[{COLOR}r:RED]
					   [+1|{TYPE}r:FRUIT]
					      Apple
					      Strawberry
					      Cherry
					   [-1]
					   [+2|{TYPE}r:VEGGIE]
					      Bell pepper    VEGGIE
					      Radish         VEGGIE
					   [-2]
					[]
		
	Special Characters
		Certain characters can have special meaning when included in the file. Each of the following can be changed by setting the relevant subscript in the chars array passed to the constructor (i.e. chars["SETTING"] or chars["MOD","ADD_LABEL"]).
		
		Defaults:
			SETTING          @
			IGNORE           ;
			MODEL            (
			MOD,START        [
			MOD,END          ]
			PASS             (no default)
			PLACEHOLDER      -
			MULTIENTRY       |
			MOD,ADD_LABEL    +
			MOD,REMOVE_LABEL -
			MOD,DELIM        |
		
		At the start of a row:
			SETTING - @
				Any row that begins with one of these is assumed to be of the form @SettingName=value, where SettingName is one of the following:
					PlaceholderChar - the placeholder character to use
				Note that if any of these conflict with the settings passed programmatically, the programmatic settings win.
			
			IGNORE - ;
				If any of these characters are at the beginning of a line (ignoring any whitespace before that), the line is ignored and not added to the array of lines.
			
			MODEL - (
				This is the header row mentioned above - if you specify this, the 2D array that you get back will use these column headers as string indices into each "row" array.
			
			MOD,START - [
				A line which begins with this character will be processed as a mod (see "Mods" section for details).
				
			PASS - (no default)
				Any row that begins with one of these characters will not be broken up into multiple pieces, but will be a single-element array in the final output.
				Note that the chars["IGNORE"] subscript is an array and can contain multiple characters.
			
		Within a "normal" row (not started with any of the special characters above):
			PLACEHOLDER - - (hyphen)
				Having this allows you to have a truly empty value for a column in a given row (useful when optional columns are in the middle).
			
			MULTIENTRY - |
				If this is included in a value for a column, the value for that row will be an array of the pipe-delimited values.
		
		Within a mod row (after the MOD,START character, see "Mods" section for details):
			MOD,ADD_LABEL - +
				Associate the mods on this line with the numeric label following this character.
				
			MOD,REMOVE_LABEL - - (hyphen)
				Remove all mods with the numeric label following this character.
				
			MOD,DELIM - |
				Multiple mod actions may be included in a mod line by separating them with this character.
				
			MOD,END - ]
				Mod lines should end with this character.
		
	Other features
		Key rows
			The constructor's keyRowChars parameter can be used to separate certain rows from the others based on their starting character, excluding them from the main table. Instead, those rows (which will still be split and indexed based on the model row, if present) are stored off using the key name given as part of the parameter, and are accessible using the .getKeyRow() function.
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
					overrideIndex := tl.getKeyRow("OVERRIDE_INDEX")
				Result:
					table does not include row starting with ")"
					overrideIndex["ABBREV"] := 2
					             ["NAME"]   := 0
					             ["VALUE"]  := 1
		
		Filtering
			A version of the table which does not include all rows can be retrieved with the .getFilteredTable() and .getFilteredTableUnique() functions. For these functions, you can specify the column and value you'd like to filter on, with an option to include/exclude rows with a blank value for that column.
			Example:
				File:
					(  NAME     ABBREV   PATH                                         MACHINE
					   Spotify  spot     C:\Program Files (x86)\Spotify\Spotify.exe   HOME_DESKTOP
   					Spotify  spot     C:\Program Files\Spotify\Spotify.exe         EPIC_LAPTOP
   					Spotify  spot     C:\Spotify\Spotify.exe                       ASUS_LAPTOP
   					Firefox  fox      C:\Program Files\Firefox\firefox.exe         
				Code:
					tl := new TableList(filePath)
					table := tl.getFilteredTable("MACHINE", "HOME_DESKTOP", true) ; true - exclude blanks
				Result:
					table[1, "NAME"]   = Spotify
					table[1, "ABBREV"] = spot
					table[1, "PATH"]   = C:\Program Files (x86)\Spotify\Spotify.exe
					<"Firefox" line excluded because it was blank for this column>
		
	Example Usage
		File:
			(  NAME           ABBREV         PATH              MACHINE
			
			; AHK Folders
			[{PATH}b:C:\ahk\]
			   AHK Config     AHK_CONFIG     config
			   AHK Source     AHK_SOURCE     source
			[]
			
			; User Folders
			[{PATH}b:C:\Users\user\]
			   Downloads      DOWNLOADS      Downloads
			   VB6 Compile    VB6_COMPILE    Dev\Temp\Compile  EPIC_LAPTOP
			[]
			
			; Music variations per machine
			[{PATH}e:\Music]
			   Music          MUSIC          C:\Users\user     HOME_DESKTOP
			   Music          MUSIC          C:\Users\user     HOME_ASUS
			   Music          MUSIC          D:                EPIC_LAPTOP
			[]
		
		Code A:
			tl := new TableList(filePath)
			table := tl.getTable()
		Result A:
			table[1, "NAME"]    = AHK Config
			         "ABBREV"]  = AHK_CONFIG
			         "PATH"]    = C:\ahk\config
			         "MACHINE"] = 
			     [2, "NAME"]    = AHK Source
			         "ABBREV"]  = AHK_SOURCE
			         "PATH"]    = C:\ahk\source
			         "MACHINE"] = 
			     [3, "NAME"]    = Downloads
			         "ABBREV"]  = DOWNLOADS
			         "PATH"]    = C:\Users\user\Downloads
			         "MACHINE"] = 
			     [4, "NAME"]    = VB6 Compile
			         "ABBREV"]  = VB6_COMPILE
			         "PATH"]    = C:\Users\user\Dev\Temp\Compile
			         "MACHINE"] = EPIC_LAPTOP
			     [5, "NAME"]    = Music
			         "ABBREV"]  = MUSIC
			         "PATH"]    = C:\Users\user\Music
			         "MACHINE"] = HOME_DESKTOP
			     [6, "NAME"]    = Music
			         "ABBREV"]  = MUSIC
			         "PATH"]    = C:\Users\user\Music
			         "MACHINE"] = HOME_ASUS
			     [7, "NAME"]    = Music
			         "ABBREV"]  = MUSIC
			         "PATH"]    = D:\Music
			         "MACHINE"] = EPIC_LAPTOP
			
		Code B:
			tl := new TableList(filePath)
			table := tl.getFilteredTable("MACHINE", "HOME_DESKTOP", false) ; false - include blanks
		Result B (only rows with MACHINE column = HOME_DESKTOP or blank are included):
			table[1, "NAME"]    = AHK Config
			         "ABBREV"]  = AHK_CONFIG
			         "PATH"]    = C:\ahk\config
			         "MACHINE"] = 
			     [2, "NAME"]    = AHK Source
			         "ABBREV"]  = AHK_SOURCE
			         "PATH"]    = C:\ahk\source
			         "MACHINE"] = 
			     [3, "NAME"]    = Downloads
			         "ABBREV"]  = DOWNLOADS
			         "PATH"]    = C:\Users\user\Downloads
			         "MACHINE"] = 
			     [4, "NAME"]    = Music
			         "ABBREV"]  = MUSIC
			         "PATH"]    = C:\Users\user\Music
			         "MACHINE"] = HOME_DESKTOP
*/

global TLROWTYPE_IGNORE  := "IGNORE"
global TLROWTYPE_SETTING := "SETTING"
global TLROWTYPE_MOD     := "MOD"
global TLROWTYPE_PASS    := "PASS"
global TLROWTYPE_KEY     := "KEY"
global TLROWTYPE_MODEL   := "MODEL"
global TLROWTYPE_NORMAL  := "NORMAL"

class TableList {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	;---------
	; DESCRIPTION:    Create a new TableList instance.
	; PARAMETERS:
	;  filePath    (I,REQ) - Path to the file to read from. May be a partial path if
	;                        findConfigFilePath() can find the correct thing.
	;  chars       (I,OPT) - Array of special characters to override, see class documentation
	;                        for more info. Format (charName is name of key i.e. "SETTING"):
	;                        	chars[charName] := char
	;  keyRowChars (I,OPT) - Array of characters and key names to keep separate, see class
	;                        documentation for more info. If a row starts with one of the
	;                        characters included here, that row will not appear in the main
	;                        table. Instead, it will be available using the .getKeyRow()
	;                        function. Note that the row is still split and indexed based
	;                        on the model row (if present). Format (where keyName is the string
	;                        you'll use with .getKeyRow() to retrieve the row later:
	;                        	keyRowChars[<char>] := keyName
	; RETURNS:        Reference to new TableList object
	;---------
	__New(filePath, chars := "", keyRowChars := "") {
		if(!filePath)
			return ""
		
		filePath := findConfigFilePath(filePath)
		if(!FileExist(filePath))
			return ""
		
		this.chars       := mergeArrays(this.getDefaultChars(), chars)
		this.keyRowChars := keyRowChars
		
		lines := fileLinesToArray(filePath)
		this.parseList(lines)
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
	; DESCRIPTION:    Retrieve a single row from the processed table.
	; PARAMETERS:
	;  lineNum (I,REQ) - The line number of the row to retrieve from the table.
	; RETURNS:        The row array for the row on the requested line, indexed using the model row
	;                 if present. Format:
	;                 	row[column] := value
	;---------
	getRow(index) {
		return this.table[index]
	}
	
	;---------
	; DESCRIPTION:    Retrieve a key row that was excluded from the table, based on the constructor's
	;                 keyRowChars parameter.
	; PARAMETERS:
	;  name (I,REQ) - The key name that was associated with the row that you want.
	; RETURNS:        The key row that matches the given name. Format:
	;                 	row[column] := value
	;---------
	getKeyRow(name) {
		return this.keyRows[name]
	}
	
	;---------
	; DESCRIPTION:    Get the numeric array with the labels used as columns, as defined by the model row.
	; RETURNS:        Array of column labels. Format (columnNum starts at 1):
	;                 	indexLabels[columnNum] := columnLabel
	;---------
	getIndexLabels() {
		return this.indexLabels
	}
	;---------
	; DESCRIPTION:    Get the label used as the index for a specific column.
	; PARAMETERS:
	;  index (I,REQ) - The numeric index (starting at 1) of the column.
	; RETURNS:        The label used to index rows in the table for this column.
	;---------
	getIndexLabel(index) {
		return this.indexLabels[index]
	}
	
	;---------
	; DESCRIPTION:    Retrieve a version of the table that excludes rows that don't match a certain
	;                 filter.
	; PARAMETERS:
	;  column        (I,REQ) - The string index (as defined by the model row) of the column you want
	;                          to filter on.
	;  allowedValue  (I,OPT) - Only include rows which have this value in their column (with the
	;                          exception of rows with a blank value, see includeBlanks parameter).
	;                          If this is left blank, any value is allowed .
	;  includeBlanks (I,OPT) - If set to false, columns which have a blank value for the given column
	;                          will be excluded. Defaults to true (include blanks).
	; RETURNS:        Processed table, excluding rows that do not fit the filter. Format:
	;                 	table[rowNum, column] := value
	;---------
	getFilteredTable(column, allowedValue := "", includeBlanks := true) {
		; DEBUG.popup("column",column, "allowedValue",allowedValue, "includeBlanks",includeBlanks)
		if(!column)
			return ""
		
		filteredTable := []
		For i,rowAry in this.table {
			if(this.shouldIncludeRow(rowAry, column, allowedValue, includeBlanks))
				filteredTable.push(rowAry)
		}
		
		return filteredTable
	}
	
	;---------
	; DESCRIPTION:    Retrieve a version of the table that excludes rows that don't match
	;                 a certain filter, and "flattens" the table so that there is only one
	;                 row per value of the given column.
	; PARAMETERS:
	;  uniqueColumn (I,REQ) - The column that we will "flatten" rows based on - there will
	;                         be only one row per value of this column.
	;  filterColumn (I,REQ) - The column to filter using - this column determines which row
	;                         wins if there are multiple with the same unique value.
	;  allowedValue (I,REQ) - The value that should win - that is, if 2 rows have uniqueColumn=A,
	;                         the one with filterColumn=allowedValue is the one that will be
	;                         included in the table. In the event that multiple rows have the same
	;                         uniqueColumn value and this allowedValue, the first one in the file
	;                         will win.
	; RETURNS:        Processed and flattened table. Format:
	;                 	table[rowNum, column] := value
	;---------
	getFilteredTableUnique(uniqueColumn, filterColumn, allowedValue) {
		if(!uniqueColumn || !filterColumn || !allowedValue)
			return ""
		
		uniqueAry := [] ; uniqueVal => {"INDEX":indexInTable, "FILTER_VALUE":filterVal}
		For i,rowAry in this.table {
			if(!this.shouldIncludeRow(rowAry, filterColumn, allowedValue))
				Continue
			
			uniqueVal := rowAry[uniqueColumn]
			filterVal := rowAry[filterColumn]
			
			if(!uniqueAry[uniqueVal]) {
				uniqueAry[uniqueVal, "INDEX"]        := i
				uniqueAry[uniqueVal, "FILTER_VALUE"] := filterVal
			} else if( (filterVal = allowedValue) && (uniqueAry[uniqueVal, "FILTER_VALUE"] != allowedValue) ) {
				uniqueAry[uniqueVal, "INDEX"]        := i
				uniqueAry[uniqueVal, "FILTER_VALUE"] := filterVal
			}
		}
		
		filteredTable := []
		For i,ary in uniqueAry {
			index := ary["INDEX"]
			filteredTable.push(this.table[index])
		}
		
		return filteredTable
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	mods    := []
	table   := []
	keyRows := []
	
	;---------
	; DESCRIPTION:    Get the array of default special characters.
	; RETURNS:        Array of special characters for use by the class, see header for character
	;                 meanings. Format:
	;                 	chars[name] := character
	;---------
	getDefaultChars() {
		chars := []
		
		chars["IGNORE"]  := ";"
		chars["MODEL"]   := "("
		chars["SETTING"] := "@"
		chars["PASS"]    := [] ; This one is an array
		
		chars["PLACEHOLDER"] := "-"
		chars["MULTIENTRY"]  := "|"
		
		chars["MOD", "START"]        := "["
		chars["MOD", "END"]          := "]"
		chars["MOD", "ADD_LABEL"]    := "+"
		chars["MOD", "REMOVE_LABEL"] := "-"
		chars["MOD", "DELIM"]        := "|"
		
		return chars
	}
	
	;---------
	; DESCRIPTION:    Given an array of lines from a file, parse out the data into internal structures.
	; PARAMETERS:
	;  lines (I,REQ) - Numeric array of lines from the file.
	;---------
	parseList(lines) {
		; Loop through and do work on them.
		For i,row in lines {
			row := dropWhitespace(row)
			
			; Reduce any sets of multiple tabs in a row to a single one.
			Loop {
				if(!stringContains(row, A_Tab A_Tab))
					Break
				row := StrReplace(row, A_Tab A_Tab, A_Tab)
			}
			
			this.processRow(row)
		}
		
		; DEBUG.popup("TableList.parseList","Finish", "State",this)
	}
	
	;---------
	; DESCRIPTION:    Process a single line from the file. We will parse the line, determine which
	;                 type it is, and store it in the correct place (along with any additional
	;                 processing).
	; PARAMETERS:
	;  row (I,REQ) - Line from the file (string).
	;---------
	processRow(row) {
		rowType := this.findRowType(row)
		; DEBUG.popup("Processing row",row, "Row type",rowType)
		
		if(rowType = TLROWTYPE_IGNORE)
			return ; Ignore - it's either empty or an ignore row.
		
		else if(rowType = TLROWTYPE_NORMAL)
			this.processNormal(row)
		
		else if(rowType = TLROWTYPE_SETTING)
			this.processSetting(row)
		
		else if(rowType = TLROWTYPE_MODEL) ; Model row, causes us to use string subscripts instead of numeric per entry.
			this.processModel(row)
		
		else if(rowType = TLROWTYPE_MOD)
			this.processMod(row)
		
		else if(rowType = TLROWTYPE_PASS)
			this.processPass(row)
		
		else if(rowType = TLROWTYPE_KEY) ; Key characters mean that we split the row, but always store it separately from everything else.
			this.processKey(row)
	}
	
	;---------
	; DESCRIPTION:    Determine which type of row we're trying to process.
	; PARAMETERS:
	;  row (I,REQ) - String with the line from the file we're trying to categorize.
	; RETURNS:        A TLROWTYPE_* constant describing the type of row.
	;---------
	findRowType(row) {
		if(!row)
			return TLROWTYPE_IGNORE
		
		if(stringStartsWith(row, this.chars["IGNORE"]))
			return TLROWTYPE_IGNORE
		
		if(stringStartsWith(row, this.chars["SETTING"]))
			return TLROWTYPE_SETTING
		
		if(stringStartsWith(row, this.chars["MOD", "START"]))
			return TLROWTYPE_MOD
		
		if(stringStartsWith(row, this.chars["MODEL"]))
			return TLROWTYPE_MODEL
		
		firstChar := subStr(row, 1, 1)
		if(contains(this.chars["PASS"], firstChar))
			return TLROWTYPE_PASS
		
		if(this.keyRowChars.hasKey(firstChar))
			return TLROWTYPE_KEY
		
		return TLROWTYPE_NORMAL
	}
	
	;---------
	; DESCRIPTION:    Parse a normal row - this is one that will be included in the processed table.
	; PARAMETERS:
	;  row (I,REQ) - Normal row to process (string).
	;---------
	processNormal(row) {
		rowAry := StrSplit(row, A_Tab)
		this.applyIndexLabels(rowAry)
		this.applyMods(rowAry)
		
		; If any of the values were a placeholder, remove them now.
		For i,value in rowAry.clone() ; Clone since we're deleting things.
			if(value = this.chars["PLACEHOLDER"])
				rowAry.Delete(i)
		
		; Split up any entries that include the multi-entry character (pipe by default).
		For i,value in rowAry
			if(stringContains(value, this.chars["MULTIENTRY"]))
				rowAry[i] := StrSplit(value, this.chars["MULTIENTRY"])
		
		this.table.push(rowAry)
	}
	
	;---------
	; DESCRIPTION:    Given an array representing a row in the table, switch it from numeric to
	;                 string indices (if defined by the model row).
	; PARAMETERS:
	;  rowAry (IO,REQ) - Numerically-indexed array representing a row in the table.
	;---------
	applyIndexLabels(ByRef rowAry) {
		if(!IsObject(this.indexLabels))
			return
		
		tempAry := []
		For i,value in rowAry {
			idxLabel := this.indexLabels[i]
			if(idxLabel)
				tempAry[idxLabel] := value
			else
				tempAry[i] := value
		}
		rowAry := tempAry
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
	; DESCRIPTION:    Given a row representing a setting, store off the value of that setting
	;                 for later use.
	; PARAMETERS:
	;  row (I,REQ) - Settings row that we're processing (string).
	;---------
	processSetting(row) {
		row := removeStringFromStart(row, this.chars["SETTING"])
		if(!row)
			return
		
		name  := getStringBeforeStr(row, "=")
		value := getStringAfterStr(row, "=")
		; DEBUG.popup("TableList.processSetting","Pulled out data", "Name",name, "Value",value)
		
		if(name = "PlaceholderChar")
			this.chars["PLACEHOLDER"] := value
	}
	
	;---------
	; DESCRIPTION:    Parse a model row - this is what determines the string indices that we use for
	;                 each column in following rows.
	; PARAMETERS:
	;  row (I,REQ) - Model row to process (string).
	;---------
	processModel(row) {
		rowAry := StrSplit(row, A_Tab)
		this.indexLabels := []
		
		rowAry.RemoveAt(1) ; Get rid of the "(" bit.
		
		For i,r in rowAry
			this.indexLabels[i] := r
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
		row := removeStringFromStart(row, this.chars["MOD", "START"])
		row := removeStringFromEnd(row, this.chars["MOD", "END"])
		
		; If it's just blank, all previous mods are wiped clean.
		if(row = "") {
			this.mods := Object()
		} else {
			; Check for a remove row label.
			; Assuming here that it will be the first and only thing in the mod row.
			if(stringStartsWith(row, this.chars["MOD", "REMOVE_LABEL"])) {
				remLabel := removeStringFromStart(row, this.chars["MOD", "REMOVE_LABEL"])
				this.killMods(remLabel)
				label := 0
				
				return
			}
			
			; Split into individual mods.
			newModsSplit := StrSplit(row, this.chars["MOD", "DELIM"])
			For i,currMod in newModsSplit {
				; Check for an add row label.
				if(i = 1 && stringStartsWith(currMod, this.chars["MOD", "ADD_LABEL"]))
					label := removeStringFromStart(currMod, this.chars["MOD", "ADD_LABEL"])
				else
					this.mods.push(new TableListMod(currMod, label))
			}
		}
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
	; DESCRIPTION:    Parse a pass row - this will be added to the table as just a string, rather than an array.
	; PARAMETERS:
	;  row (I,REQ) - Pass row to process (string).
	;---------
	processPass(row) {
		this.table.push(row)
	}
	
	;---------
	; DESCRIPTION:    Parse a key row - this is one that we will split and index like a normal row,
	;                 but will store separately.
	; PARAMETERS:
	;  row (I,REQ) - Key row that we're processing (string).
	;---------
	processKey(row) {
		rowAry := StrSplit(row, A_Tab)
		firstChar := subStr(row, 1, 1)
		
		rowAry.RemoveAt(1) ; Get rid of the separate char bit (")").
		this.applyIndexLabels(rowAry)
		
		this.keyRows[this.keyRowChars[firstChar]] := rowAry
	}
	
	;---------
	; DESCRIPTION:    Based on a filter (column and value to restrict to), determine whether the
	;                 given row array should be included.
	; PARAMETERS:
	;  rowAry        (I,REQ) - Array representing a row in the table. 
	;  column        (I,OPT) - The column to filter on - we will check the value of this column
	;                          (index) in the row array to see if it matches allowedValue.
	;  allowedValue  (I,OPT) - Only include rows which have this value in their column (with the
	;                          exception of rows with a blank value, see includeBlanks parameter).
	;                          If this is left blank, any value is allowed .
	;  includeBlanks (I,OPT) - If set to false, columns which have a blank value for the given column
	;                          will be excluded. Defaults to true (include blanks).
	; RETURNS:        True if we should exclude the row from the filtered table, false otherwise.
	;---------
	shouldIncludeRow(rowAry, column, allowedValue := "", includeBlanks := true) {
		if(!column)
			return true
		
		valueToCompare := rowAry[column]
		
		; If the value is blank, include/exclude it based on the includeBlanks parameter.
		if(!valueToCompare)
			return includeBlanks
		
		; If no allowed value, include everything (aside from blanks, which obey includeBlanks above)
		if(!allowedValue)
			return true
		
		; If the value isn't blank, compare it to our allowed value.
		if(IsObject(valueToCompare)) { ; Array case - multiple values in filter column.
			if(contains(valueToCompare, allowedValue))
				return true
		} else {
			if(valueToCompare = allowedValue)
				return true
		}
		
		; DEBUG.popup("Base","include", "row",rowAry, "column",column, "allowedValue",allowedValue, "includeBlanks",includeBlanks)
		return false
	}
	
	; Debug info
	debugName := "TableList"
	debugToString(debugBuilder) {
		debugBuilder.addLine("Chars",         this.chars)
		debugBuilder.addLine("Key row chars", this.keyRowChars)
		debugBuilder.addLine("Index labels",  this.indexLabels)
		debugBuilder.addLine("Mods",          this.mods)
		debugBuilder.addLine("Key rows",      this.keyRows)
		debugBuilder.addLine("Table",         this.table)
	}
}