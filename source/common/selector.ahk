/* Class that selects an option from a given set of choices, and returns info about that choice.
	
	Choices
		Choices are read from a TableList (TL) file. See documentation for the TableList class for general file format, and "File Format" below for additional Selector-specific details.
		These choices may also be filtered (see the documentation for __New() below) - this allows you to use a single .tl file of information to be used in different ways.
		
	Selection
		This class can be used in one of two ways:
		1. Gui method (.selectGui())
				Show a popup containing the available choices and a field where the user can enter their selection using either the index or abbreviation of a choice. If override fields are visible (see "Data Override Fields" below) they can override specific information about that choice (or even submit the popup without a choice, only overrides) as well.
				
				The user may also enter the command character (+) followed by one of these letters to do something instead of picking a choice:
					e - edit
						Entering +e in the choice field will open the TableList file used to generate the popup.
			
		2. Silent method (.selectChoice())
				Select a choice silently, based on programmatic input.
		
	File Format
		Starting a row in the TableList file with certain characters has special meaning (beyond those documented in the TableList class):
			( - Model row (required)
				The file should include a single model row (above all choices), which gives a name to each column in the file. Most column names will simply determine the subscript in the return array that the data from that column will be returned in, but these columns have special meaning:
						NAME   - This is the display name for a choice in the popup that can be shown to a user.
						ABBREV - This is displayed next to the display name for a choice in the popup. Additionally, a choice can be selected using the abbreviation (in addition to the index).
				Example:
					(	NAME		ABBREV		PATH
				Result:
					Values in the NAME and ABBREV columns will be displayed for choices as described above, and the return array will have a "PATH" subscript with the corresponding value from the selected choice.
				
			) - Model index row
				These rows assign a numeric index to each column in the model row. This index will be the position the corresponding data override field will have in the popup. An index of 0 tells the UI not to show the field corresponding to that column at all. Note that the existence of this row will cause data override fields to be shown - the fields can be programmatically suppressed using .selectGui()'s suppressOverrideFields parameter. See "Data Override Fields" below for more details.
				Example:
					(	NAME		ABBREV		PATH
					)	0			0				1
				Result:
					A "PATH" field will appear next to the choice field.
				
			+ - Gui setting
				All gui settings (see "Gui Settings" below for a list) may be preset in the file using a line that starts with the + character, with an = between the name of the setting and the value. This is not to be confused with the TableList class's setting character (@).
				Example:
					+WindowTitle=This is the new title!
				Result:
					The popup's title will be "This is the new title!"
				
			# - Section title
				Starting a row with this character (plus a space) will start a new "section" in the popup, with an extra newline followed by the rest of the row's text as a title (bolded/underlined). Note that if no choices appear after one of these rows (which can happen when filtering choices), only the most recent section title row will apply. Additionally, you can force a new super-column in the popup using a pipe (|) character - see "New column" character below.
				Example:
					# Stuff
				Result:
					The popup will contain a (bolded/underlined) header of "Stuff".
				
			* - Hidden choice
				Adding this character to an otherwise normal choice row will hide that choice from the gui, but still allow it to be selected using its abbreviation.
				Example:
					*Windows		win			windows.tl
				Result:
					The "Windows" choice will not be visible, but the user can still select that choice using the "win" abbreviation.
			
		Certain characters can be included within a row to additional effect:
			| - Abbreviation delimiter
				You can give an individual choice multiple abbreviations that can all be used to select the choice, separated by this character. Only the first abbreviation will be displayed.
				Example:
					Programs		prog|prg		programs.tl
				Result:
					The "Programs" choice will appear in the popup with an abbreviation of "prog", but the "prg" abbreviation may also be used to select that choice.
				
			| - New column (in section title row)
				If this character is put at the beginning of a section title row (with a space on either side), that title will force a new super-column in the popup.
				Example:
					# | Title
				Result:
					The "Title" section will start a new super-column in the popup.
		
	Gui Settings
		Some settings related to the popup may be customized using one of the following methods:
			1. Specified in the TL file (using the + character, see "Settings" character above)
			2. Programmatically, using the .setGuiSetting() function
		Note that these settings only have an effect on the popup shown by .selectGui().
		
		Available settings:
			WindowTitle
				This will be the title of the popup shown to the user. This setting may also be set using the title parameter of .selectGui().
			
			MinColumnWidth
				If this is set, each super-column in the popup will be that number of pixels wide at a minimum (each may be wider if the choices in that column are wider). See the FlexTable class for how super-columns work.
		
	Data Override Fields
		If a model index row is specified in the TL file, the popup shown by .selectGui() will include not only a choice field, but also fields for each column given a non-zero index in the model index row. The fields are shown in the order specified by the row (i.e. 1 is first after the choice field, 2 is second, etc.). That the fields can be programmatically suppressed using .selectGui()'s suppressOverrideFields parameter.
		These fields give a user the ability to override data from their selected choice (or submit the popup without a choice, only overrides). If the user changes the value of the field (it defaults to the column label), that value will be used instead of the selected choice's value for that column.
		Even if there is no model index row in the TL file, the .addExtraOverrideFields() function may be used to add additional fields to the popup. The values from these fields will appear in the return array just like other override fields, under the subscript with their name.
		Values may be defaulted into these fields using .selectGui()'s defaultOverrideData parameter.
	
	Example Usage (Popup)
		filter := {COLUMN:"MACHINE", VALUE:HOME_DESKTOP}           ; Only include choices which which have the "MACHINE" column set to "HOME_DESKTOP" (or blank)
		extraDataFields := ["CONFIG_NAME", "CONFIG_NUM"]           ; Two additional override fields for the popup.
		defaultOverrideData := {CONFIG_NAME: "Windows"}            ; Default a value of "Windows" into the "CONFIG_NAME" override field
		
		s := new Selector("C:\ahk\configs.tl", filter)             ; Read in the "configs.tl" TL file, filtering it
		s.setGuiSetting("MinColumnWidth", 500)                     ; Set the minimum super-column width to 500 pixels
		s.addExtraOverrideFields(extraDataFields)                  ; Add the extra override fields
		data := s.selectGui("", "New title!", defaultOverrideData) ; Show the popup with a title of "New title!" and the default override field values specified above
		MsgBox, % "Chosen config name: " data["CONFIG_NAME"]
		MsgBox, % "Chosen config num: "  data["CONFIG_NUM"]
		
	Example Usage (Silent)
		pathAbbrev := <user input>
		filter := {COLUMN:"MACHINE", VALUE:HOME_DESKTOP}           ; Only include choices which which have the "MACHINE" column set to "HOME_DESKTOP" (or blank)
		
		s := new Selector("C:\ahk\paths.tl", filter)               ; Read in the "paths.tl" TL file, filtering it
		path := s.selectChoice(pathAbbrev, "PATH")                 ; Return only the "PATH" value, not the whole return array
*/

class Selector {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	__New(filePath = "", filter = "", tableListSettings = "") {
		this.setChars()
		this.setDefaultGuiSettings()
		
		tlSettings := mergeArrays(this.getDefaultTableListSettings(), tableListSettings)
		
		if(filePath) {
			this.filePath := findConfigFilePath(filePath)
			this.loadChoicesFromFile(tlSettings, filter)
		}
		
		; DEBUG.popup("Selector.__New", "Finish", "Filepath", this.filePath, "TableListSettings", this.tableListSettings, "Filter", this.filter, "State", this)
	}
	
	setGuiSetting(name, value = "") {
		if(name = "")
			return
		
		this.guiSettings[name] := value
	}
	
	; Extra data fields - should be added to overrideFields (so they show up in the popup)
	; extraDataFields - simple array of column names. Default values (if desired) should be in selectGui > defaultOverrideData.
	addExtraOverrideFields(extraDataFields) {
		if(!this.overrideFields)
			this.overrideFields := []
		
		baseLength := forceNumber(this.overrideFields.maxIndex())
		For i,label in extraDataFields
			this.overrideFields[baseLength + i] := label
	}
	
	selectGui(returnColumn = "", title = "", defaultOverrideData = "", suppressOverrideFields = false) {
		; DEBUG.popup("Selector.selectGui", "Start", "Default override data", defaultOverrideData, "GUI Settings", guiSettings)
		if(title)
			this.guiSettings["WindowTitle"] := title
		if(suppressOverrideFields)
			this.overrideFields := "" ; If user explicitly asked us to suppress override fields, get rid of them.
		
		data := this.doSelectGui(defaultOverrideData)
		
		if(isEmpty(data))
			return ""
		else if(returnColumn)
			return data[returnColumn]
		else
			return data
	}
	
	selectChoice(choiceString, returnColumn = "") {
		if(!choiceString)
			return ""
		
		data := this.parseChoice(choiceString)
		if(returnColumn)
			return data[returnColumn]
		else
			return data
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	chars          := []    ; Special characters (see getSpecialChars)
	choices        := []    ; Visible choices the user can pick from (array of SelectorChoice objects).
	hiddenChoices  := []    ; Invisible choices the user can pick from (array of SelectorChoice objects).
	sectionTitles  := []    ; Lines that will be displayed as titles (index matches the first choice that should be under this title)
	overrideFields := ""    ; Mapping from override field indices => data labels (column headers)
	guiSettings    := []    ; Settings related to the GUI popup we show
	filePath       := ""    ; Where the .tl file lives if we're reading one in.
	suppressData   := false ; Whether to ignore any override data the user entered.
	
	; Names for global variables that we'll use for values of fields. This way they can be declared global and retrieved in the same way, without having to pre-define global variables.
	choiceFieldName         := "SelectorChoice"
	overrideFieldNamePrefix := "SelectorOverride"
	
	setChars() {
		this.chars["SECTION_TITLE"] := "#"
		this.chars["HIDDEN"]        := "*"
		this.chars["MODEL_INDEX"]   := ")"
		this.chars["SETTING"]       := "+"
		this.chars["COMMAND"]       := "+"
		
		this.chars["COMMANDS"] := []
		this.chars["COMMANDS", "EDIT"]  := "e"
	}
	
	setDefaultGuiSettings() {
		this.guiSettings["MinColumnWidth"] := 0
		this.guiSettings["WindowTitle"]    := "Please make a choice by either number or abbreviation:"
	}
	
	; Default settings to use with TableList object when parsing input file.
	getDefaultTableListSettings() {
		tableListSettings := []
		
		tableListSettings["CHARS"] := []
		tableListSettings["CHARS",  "PASS"]            := [this.chars["SECTION_TITLE"], this.chars["SETTING"]]
		tableListSettings["FORMAT", "SEPARATE_MAP"]    := {this.chars["MODEL_INDEX"]: "DATA_INDEX"} 
		tableListSettings["FORMAT", "DEFAULT_INDICES"] := ["NAME", "ABBREV", "VALUE"]
		
		return tableListSettings
	}
	
	; Load the choices and other such things from a specially formatted file.
	loadChoicesFromFile(tableListSettings, filter) {
		; DEBUG.popup("TableList Settings", tableListSettings)
		tl := new TableList(this.filePath, tableListSettings)
		if(filter)
			table := tl.getFilteredTable(filter["COLUMN"], filter["VALUE"])
		else
			table := tl.getTable()
		; DEBUG.popup("Filepath", this.filePath, "Parsed table", table, "Index labels", tl.getIndexLabels(), "Separate rows", tl.getSeparateRows())
		
		if(!IsObject(tl.getIndexLabels())) {
			DEBUG.popup("Selector.loadChoicesFromFile","Got TableList", "Invalid settings","No column index labels")
			return
		}
		
		; Special model index row that tells us how we should arrange data inputs.
		if(tl.getSeparateRow("DATA_INDEX")) {
			this.overrideFields := []
			For i,fieldIndex in tl.getSeparateRow("DATA_INDEX") {
				if(fieldIndex > 0) ; Filter out data columns we don't want fields for (fieldIndex = 0)
					this.overrideFields[fieldIndex] := tl.getIndexLabel(i) ; Numeric, base-1 field index => column label (also the subscript in data array)
			}
		}
		; DEBUG.popup("Selector.loadChoicesFromFile","Processed indices", "Index labels",tl.getIndexLabels(), "Separate rows",tl.getSeparateRows(), "Selector label indices",this.overrideFields)
		
		this.choices       := [] ; Visible choices the user can pick from.
		this.hiddenChoices := [] ; Invisible choices the user can pick from.
		this.sectionTitles := [] ; Lines that will be displayed as titles, extra newlines, etc, but have no other significance.
		For i,row in table {
			if(this.isChoiceRow(row))
				this.addChoiceRow(row)
			else
				this.processSpecialRow(row)
		}
	}
	
	;---------
	; DESCRIPTION:    Check whether the given row (array) of data should become a 
	;                 SelectorChoice, or whether it is instead a special row (setting 
	;                 or section title). Rows that should become choices have a "NAME" 
	;                 subscript with a value.
	; PARAMETERS:
	;  row (I,REQ) - Row of data from a TableList, will be checked 
	;                for whether it should become a SelectorChoice or not.
	; RETURNS:        Whether this is a choice-ready row or not.
	;---------
	isChoiceRow(row) {
		return (row["NAME"] != "")
	}
	
	addChoiceRow(row) {
		choice := new SelectorChoice(row)
		if(SubStr(row["NAME"], 1, 1) = this.chars["HIDDEN"])
			this.hiddenChoices.push(choice) ; First char is hidden character (*), don't show it but allow user to choose it via abbrev.
		else
			this.choices.push(choice)
	}
	
	processSpecialRow(row) {
		rowText   := row[1] ; Only one element containing everything
		firstChar := SubStr(rowText, 1, 1)
		rowText   := subStr(rowText, 2) ; Go ahead and trim off the special character
		
		; Setting
		if(firstChar = this.chars["SETTING"]) {
			if(rowText != "") {
				settingSplit := StrSplit(settingString, "=")
				this.setGuiSetting(settingSplit[1], settingSplit[2]) ; name, value
			}
		
		; Section title
		} else if(firstChar = this.chars["SECTION_TITLE"]) {
			title := SubStr(rowText, 2) ; Format should be "# Title", strip off the space (# already removed above)
			idx := forceNumber(this.choices.MaxIndex()) + 1 ; The next actual choice will be the first one under this header, so match that.
			this.sectionTitles[idx] := title ; If there are multiple headers in a row (for example when choices are filtered out) they should get overwritten in order here (which is correct).
		}
	}
	
	doSelectGui(defaultData) {
		sGui := new SelectorGui(this.choices, this.sectionTitles, this.overrideFields, this.guiSettings["MinColumnWidth"])
		sGui.show(this.guiSettings["WindowTitle"], defaultData)
		data := []
		
		; User's choice is main data source
		choiceData := this.parseChoice(sGui.getChoiceQuery())
		data := mergeArrays(data, choiceData)
		
		; Override fields can add to that too.
		if(!this.suppressData) {
			overrideData := sGui.getOverrideData()
			data := mergeArrays(data, overrideData)
		}
		
		; DEBUG.popup("Selector.doSelectGui","Finish", "Choice data",choiceData, "Override data",overrideData, "Merged data",data)
		return data
	}
	
	; Function to turn the input into something useful.
	parseChoice(userChoiceString) {
		; Command choice - edit ini, etc.
		if(InStr(userChoiceString, this.chars["COMMAND"])) {
			commandChar := SubStr(userChoiceString, 2, 1)
			
			; Edit action - open the current INI file for editing
			if(commandChar = this.chars["COMMANDS", "EDIT"]) {
				this.suppressData := true
				Run(this.filePath)
			}
			
			return ""
		
		; Otherwise, we search through the data structure by both number and shortcut and look for a match.
		} else {
			return this.searchAllTables(userChoiceString)
		}
	}

	; Search both given tables, the visible and the invisible.
	searchAllTables(input) {
		if(input = "")
			return ""
		
		; Try the visible choices.
		data := this.searchTable(this.choices, input)
		if(data)
			return data
		
		; Try the invisible choices.
		data := this.searchTable(this.hiddenChoices, input, false)
		
		return data
	}

	; Function to search our generated table for a given index/shortcut.
	searchTable(table, input, checkIndex = true) {
		For i,t in table {
			; Index
			if(checkIndex && (input = i))
				return t.getData()
			
			; Abbreviation could be an array, so account for that.
			abbrev := t.getAbbrev()
			if(!IsObject(abbrev) && (input = abbrev))
				return t.getData()
			else if(IsObject(abbrev) && contains(abbrev, input))
				return t.getData()
		}
		
		return ""
	}
	
	; Debug info
	debugName := "Selector"
	debugToString(debugBuilder) { ; GDB TODO update this with new list of properties
		debugBuilder.addLine("Chars",           this.chars)
		debugBuilder.addLine("Override fields", this.overrideFields)
		debugBuilder.addLine("GUI settings",    this.guiSettings)
		debugBuilder.addLine("Filepath",        this.filePath)
		debugBuilder.addLine("Choices",         this.choices)
		debugBuilder.addLine("Hidden Choices",  this.hiddenChoices)
		debugBuilder.addLine("Section titles",  this.sectionTitles)
	}
}