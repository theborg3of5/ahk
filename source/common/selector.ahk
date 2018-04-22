/* Generic, flexible custom class for selecting from multiple choices, adding arbitrary input, and performing an action.
	
	This class will read in a file (using the TableList class) and turn it into a group of choices, which is then displayed to the user in a graphical list. The programmatic entry points are .selectGui() and .selectChoice().
	
	Certain characters have special meaning when parsing the lines of a file. They include:
		# - Section title
			This character starts a line that will be shown as a section label in the UI (to group individual choices).
		
		| - Abbreviation delimiter
			You can give an individual choice multiple abbreviations that will work for the user, separated by this character. Only the first one will be displayed, however.
		
		* - Hidden
			Putting this character at the start of a line will hide that choice from the UI, but still allow it to be selected via its abbreviation.
		
		( - Model
			You can have more than the simple layout of NAME-ABBREV-ACTION by using a model row that begins with this character. This line is tab-separated in the same way as the choices, with each entry being the name for the corresponding column of each choice.
		
		) - Model Index
			This row corresponds to the model row, giving each of the named columns an index, which is the order in which the additional arbitrary fields in the UI (turned on using +ShowOverrideFields, see settings below) will be shown. An index of 0 tells the UI not to show the field corresponding to that column at all.
		
		| - New column (in section title row)
			If this character is put at the beginning of a section title row (with a space on either side, such as "# | Title"), that title will force a new column in the UI.
		
		+ - Settings
			Lines which start with this character denote a setting that changes how the UI acts in some manner. They are always in the form "+Option=x", and include:
				ShowOverrideFields
					If set to 1, the UI will show an additional input box on the UI for each piece defined by the model row (excluding NAME, ABBREV, and ACTION). Note that these will be shown in the order they are listed by the model row, unless a model index row is present, at which point it respects that.
				
				MinColumnWidth
					Set this to any number X to have the UI be X pixels wide at a minimum (per column if multiple columns are shown). The UI might be larger if names are too long to fit.
	
	When the user selects their choice, the action passed in at the beginning will be evaluated as a function which receives a loaded SelectorRow object to perform the action on. See SelectorRow class for data structure.
	
	Once the UI is shown, the user can enter either the index or abbreviation for the choice that they would like to select. The user can give information to the popup in a variety of ways:
		Simplest case (+ShowOverrideFields != 1, no model or model index rows):
			The user will only have a single input box, where they can add their choice and additional input using the arbitrary character (see below)
			Resulting SelectorRow object will have the name, abbreviation, and action. Arbitrary input is added to the end of the action.
		
		Model row, but +ShowOverrideFields != 1
			The user still has a single input box.
			Resulting SelectorRow will have the various pieces in named subscripts of its data array, where the names are those from the model row. Note that name and abbreviation are still separate from the data array, and arbitrary additions are added to action, whether it is set or not.
		
		Model row, with +ShowOverrideFields=1 (model index row optional)
			The user will see multiple input boxes, in the order listed in the input file, or in the order of the model index row if defined. The user can override the values defined by the selected choice for each of the columns shown before the requested action is performed.
			Resulting SelectorRow will have the various pieces in named subscripts of its data array, where the names are those from the model row. Note that name and abbreviation are still separate from the data array, and arbitrary additions are ignored entirely (as the user can use the additional inputs instead).
		
	The input that the user puts in the first (sometimes only) input box can also include some special characters:
		+ - Special actions
			These are special changes that can be made to the choice/UI at runtime, when the user is interacting with the UI. They include:
				e - edit
					Putting +e in the input will open the input file. If this is something like a txt or ini file, then it should open in a text editor.
	
*/

; GUI Events
SelectorClose() {
	Gui, Destroy
}
SelectorSubmit() {
	Gui, Submit ; Actually saves edit controls' values to respective GuiIn* variables
	Gui, Destroy
}

class Selector {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	__New(filePath = "", filter = "", tableListSettings = "") {
		this.setSpecialChars()
		this.setDefaultGuiSettings()
		
		tlSettings := mergeArrays(this.getDefaultTableListSettings(), tableListSettings)
		
		if(filePath) {
			this.filePath := findConfigFilePath(filePath)
			this.loadChoicesFromFile(tlSettings, filter)
		}
		
		; DEBUG.popup("Selector.__New", "Finish", "Filepath", this.filePath, "TableListSettings", this.tableListSettings, "Filter", this.filter, "State", this)
	}
	
	
	setChoices(choices) {
		this.choices := choices
	}
	
	setGuiSetting(name, value = "") {
		if(name = "")
			return
		
		this.guiSettings[name] := value
	}
	
	; Extra data fields - should be added to overrideFields (so they show up in the popup)
	; extraDataFields - simple array of column names. Default values (if desired) should be in selectGui > defaultOverrideData.
	addExtraDataFields(extraDataFields) {
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
		
		; DEBUG.popup("User Input",userChoiceString, "data",data)
		data := this.doSelectGui(defaultOverrideData)
		if(returnColumn)
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
	
	chars          := [] ; Special characters (see getSpecialChars)
	choices        := [] ; Visible choices the user can pick from (array of SelectorRow objects).
	hiddenChoices  := [] ; Invisible choices the user can pick from (array of SelectorRow objects).
	sectionTitles  := [] ; Lines that will be displayed as titles (index matches the first choice that should be under this title)
	overrideFields := [] ; Mapping from override field indices => data labels (column headers)
	guiSettings    := [] ; Settings related to the GUI popup we show
	filePath       := "" ; Where the .tl file lives if we're reading one in.
	
	; Names for global variables that we'll use for values of fields. This way they can be declared global and retrieved in the same way, without having to pre-define global variables.
	choiceFieldName         := "SelectorChoice"
	overrideFieldNamePrefix := "SelectorOverride"
	
	setSpecialChars() {
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
		this.choices       := [] ; Visible choices the user can pick from.
		this.hiddenChoices := [] ; Invisible choices the user can pick from.
		this.sectionTitles := [] ; Lines that will be displayed as titles, extra newlines, etc, but have no other significance.
		
		; DEBUG.popup("TableList Settings", tableListSettings)
		tl := new TableList(this.filePath, tableListSettings)
		if(filter)
			list := tl.getFilteredTable(filter["COLUMN"], filter["VALUE"])
		else
			list := tl.getTable()
		; DEBUG.popup("Filepath", this.filePath, "Parsed List", list, "Index labels", tl.getIndexLabels(), "Separate rows", tl.getSeparateRows())
		
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
		
		For i,currItem in list {
			; Parse this size-n array into a new SelectorRow object.
			currRow := new SelectorRow(currItem)
			if(currItem["NAME"])
				firstChar := SubStr(currItem["NAME"], 1, 1)
			else
				firstChar := SubStr(currItem[1], 1, 1) ; Only really populated for the non-normal rows.
			; DEBUG.popup("Curr Row", currRow, "First Char", firstChar)
			
			; Options for the selector in general.
			if(firstChar = this.chars["SETTING"]) {
				this.processSettingFromFile(currRow.data[1])
			
			; Special: add a section title to the list display.
			} else if(firstChar = this.chars["SECTION_TITLE"]) {
				; Format should be "# Title"
				idx := 0
				if(this.choices.MaxIndex())
					idx := this.choices.MaxIndex()
				idx++ ; The next actual choice will be the first one under this header, so match that.
				
				this.sectionTitles[idx] := SubStr(currItem[1], 3) ; If there are multiple headers in a row (for example when choices are filtered out) they should get overwritten in order here (which is correct).
				; DEBUG.popup("Just added section title:", this.sectionTitles[this.sectionTitles.MaxIndex()], "At index", idx)
				
			; Invisible, but viable, choice.
			} else if(firstChar = this.chars["HIDDEN"]) {
				this.hiddenChoices.push(currRow)
				; DEBUG.popup("Hidden choice added", currRow)
			
			; Otherwise, it's a visible, viable choice!
			} else {
				this.choices.push(currRow)
				; DEBUG.popup("Choice added", currRow)
			}
		}
	}
	
	processSettingFromFile(settingString) {
		if(settingString = "")
			return
		
		settingString := SubStr(settingString, 2) ; Trim off settings character (+)
		
		settingSplit := StrSplit(settingString, "=")
		this.setGuiSetting(settingSplit[1], settingSplit[2]) ; name, value
	}
	
	doSelectGui(defaultData) {
		sGui := new SelectorGui(this.choices, this.sectionTitles, this.overrideFields, this.guiSettings["MinColumnWidth"])
		sGui.show(this.guiSettings["WindowTitle"], defaultData)
		data := []
		
		; User's choice is main data source
		choiceData := this.parseChoice(sGui.getChoiceQuery())
		data := mergeArrays(data, choiceData)
		
		; Override fields can add to that too.
		overrideData := sGui.getOverrideData()
		data := mergeArrays(data, overrideData)
		
		return data
	}
	
	; Function to turn the input into something useful.
	parseChoice(userChoiceString) {
		; Command choice - edit ini, etc.
		commandCharPos := InStr(userChoiceString, this.chars["COMMAND"])
		if(commandCharPos = 1) {
			commandChar := SubStr(userChoiceString, 2, 1)
			
			; Special case: +e is the edit action, which will open the current INI file for editing.
			if(commandChar = this.chars["COMMANDS", "EDIT"])
				Run(this.filePath)
			
			return ""
		
		; Otherwise, we search through the data structure by both number and shortcut and look for a match.
		} else {
			rowToDo := this.searchAllTables(userChoiceString)
			; DEBUG.popup("Row to do", rowToDo)
			return rowToDo.data
		}
	}

	; Search both given tables, the visible and the invisible.
	searchAllTables(input) {
		if(input = "")
			return ""
		
		; Try the visible choices.
		out := this.searchTable(this.choices, input)
		if(out)
			return out
		
		; Try the invisible choices.
		out := this.searchTable(this.hiddenChoices, input)
		
		return out
	}

	; Function to search our generated table for a given index/shortcut.
	searchTable(table, input) {
		For i,t in table {
			if(input = i) ; They picked the index itself.
				return t.clone()
			
			; Abbreviation could be an array, so account for that.
			if(!IsObject(t.data["ABBREV"]) && (input = t.data["ABBREV"]))
				return t.clone()
			if(IsObject(t.data["ABBREV"]) && contains(t.data["ABBREV"], input))
				return t.clone()
		}
		
		return ""
	}
	
	; Debug info
	debugName := "Selector"
	debugToString(debugBuilder) {
		debugBuilder.addLine("Chars",           this.chars)
		debugBuilder.addLine("Override fields", this.overrideFields)
		debugBuilder.addLine("GUI settings",    this.guiSettings)
		debugBuilder.addLine("Filepath",        this.filePath)
		debugBuilder.addLine("Choices",         this.choices)
		debugBuilder.addLine("Hidden Choices",  this.hiddenChoices)
		debugBuilder.addLine("Section titles",  this.sectionTitles)
	}
}