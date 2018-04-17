/* Generic, flexible custom class for selecting from multiple choices, adding arbitrary input, and performing an action.
	
	This class will read in a file (using the TableList class) and turn it into a group of choices, which is then displayed to the user in a graphical list. The programmatic entry points are .selectGui() and .selectChoice().
	
	Certain characters have special meaning when parsing the lines of a file. They include:
		= - Window title
			This character starts a line that will be the title shown on the popup UI as a whole.
		
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
				
				RowsPerColumn
					Set this to any number X to have the UI start a new column when it hits that many rows in the current column. Note that the current section title will carry over with a (2) if it's the first time it's been broken across columns, (3) if it's the second time, etc.
				
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
		this.chars       := this.getSpecialChars()
		this.guiSettings := this.getDefaultGuiSettings()
		
		tlSettings := mergeArrays(this.getDefaultTableListSettings(), tableListSettings)
		
		guiId := "Selector" getNextGuiId()
		Gui, %guiId%:Default ; GDB TODO if we want to truly run Selectors in parallel, we'll probably need to add guiId as a property and add it to all the Gui* calls.
		
		if(filePath) {
			this.filePath := findConfigFilePath(filePath)
			this.loadChoicesFromFile(tlSettings, filter)
		}
		
		; DEBUG.popup("Selector.__New", "Finish", "Filepath", this.filePath, "TableListSettings", this.tableListSettings, "Filter", this.filter, "State", this)
	}
	
	setChoices(choices) {
		this.choices := choices
	}
	
	setGuiSettings(settings) {
		this.guiSettings := mergeArrays(this.guiSettings, guiSettings)
		if(settings["ExtraDataFields"])
			this.processExtraDataFields(settings["ExtraDataFields"])
	}
	
	; Extra data fields - should be added to dataIndices (so they show up in the popup)
	; extraDataFields - simple array of column names. Default values (if desired) should be in selectGui > defaultOverrideData.
	addExtraDataFields(extraDataFields) {
		this.guiSettings["ExtraDataFields"] := mergeArrays(this.guiSettings["ExtraDataFields"], extraDataFields)
		this.processExtraDataFields(extraDataFields)
	}
	
	; defaultOverrideData - If the indices for these overrides are also set by the user's overall choice, the override value will
	;                       only be used if the corresponding additional field is visible. That means if ShowOverrideFields isn't set
	;                       to true (via option in the file or guiSettings), default overrides will only affect blank values in
	;                       the user's choice.
	selectGui(returnColumn = "", title = "", showOverrideFields = "", defaultOverrideData = "") {
		; DEBUG.popup("Selector.selectGui", "Start", "Default override data", defaultOverrideData, "GUI Settings", guiSettings)
		data := []
		if(defaultOverrideData)
			data := mergeArrays(data, defaultOverrideData)
		
		if(title)
			this.guiSettings["WindowTitle"] := title
		if(showOverrideFields != "") ; Check against blank since this is a boolean value
			this.guiSettings["ShowOverrideFields"] := showOverrideFields
		if(extraDataFields)
			this.addExtraDataFields(extraDataFields)
		
		; DEBUG.popup("User Input",userChoiceString, "data",data)
		data := this.launchSelectorPopup(data)
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
	
	chars         := [] ; Special characters (see getSpecialChars)
	choices       := [] ; Visible choices the user can pick from (array of SelectorRow objects).
	hiddenChoices := [] ; Invisible choices the user can pick from (array of SelectorRow objects).
	sectionTitles := [] ; Lines that will be displayed as titles (index matches the first choice that should be under this title)
	dataIndices   := [] ; Mapping from data field indices => data labels (column headers)
	guiSettings   := [] ; Settings related to the GUI popup we show
	filePath      := "" ; Where the .tl file lives if we're reading one in.
	
	getSpecialChars() {
		chars := []
		
		chars["WINDOW_TITLE"]  := "="
		chars["SECTION_TITLE"] := "#"
		chars["NEW_COLUMN"]    := "|"
		chars["HIDDEN"]        := "*"
		chars["MODEL_INDEX"]   := ")"
		chars["SETTING"]       := "+"
		chars["COMMAND"]       := "+"
		
		chars["COMMANDS"] := []
		chars["COMMANDS", "EDIT"]  := "e"
		
		return chars
	}
	
	getDefaultGuiSettings() {
		settings := []
		
		settings["RowsPerColumn"]      := 99
		settings["MinColumnWidth"]     := 300
		settings["WindowTitle"]        := "Please make a choice by either number or abbreviation:"
		settings["ShowOverrideFields"] := false
		settings["ExtraDataFields"]    := ""
		
		return settings
	}
	
	; Default settings to use with TableList object when parsing input file.
	getDefaultTableListSettings() {
		tableListSettings := []
		
		tableListSettings["CHARS"] := []
		tableListSettings["CHARS",  "PASS"]            := [this.chars["WINDOW_TITLE"], this.chars["SECTION_TITLE"], this.chars["SETTING"]]
		tableListSettings["FORMAT", "SEPARATE_MAP"]    := {this.chars["MODEL_INDEX"]: "DATA_INDEX"} 
		tableListSettings["FORMAT", "DEFAULT_INDICES"] := ["NAME", "ABBREV", "VALUE"]
		
		return tableListSettings
	}
	
	processExtraDataFields(extraDataFields) {
		baseLength := forceNumber(this.dataIndices.maxIndex())
		For i,label in extraDataFields
			this.dataIndices[baseLength + i] := label
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
		if(IsObject(tl.getSeparateRows())) {
			this.dataIndices := []
			For i,fieldIndex in tl.getSeparateRow("DATA_INDEX") {
				if(fieldIndex > 0) ; Filters out data columns we don't want fields for
					this.dataIndices[fieldIndex] := tl.getIndexLabel(i) ; Numeric, base-1 field index => column label (also the subscript in data array)
			}
		}
		
		; DEBUG.popup("Selector.loadChoicesFromFile", "Processed indices", "Index labels", tl.getIndexLabels(), "Separate rows", tl.getSeparateRows(), "Selector label indices", this.dataIndices)
		
		For i,currItem in list {
			; Parse this size-n array into a new SelectorRow object.
			currRow := new SelectorRow(currItem)
			if(currItem["NAME"])
				firstChar := SubStr(currItem["NAME"], 1, 1)
			else
				firstChar := SubStr(currItem[1], 1, 1) ; Only really populated for the non-normal rows.
			; DEBUG.popup("Curr Row", currRow, "First Char", firstChar)
			
			; Popup title.
			if(firstChar = this.chars["WINDOW_TITLE"]) {
				; DEBUG.popup("Title char", this.chars["WINDOW_TITLE"], "First char", firstChar, "Row", currRow)
				this.guiSettings["WindowTitle"] := SubStr(currItem[1], 2)
			
			; Options for the selector in general.
			} else if(firstChar = this.chars["SETTING"]) {
				settingString := SubStr(currRow.data[1], 2) ; Strip off the = at the beginning
				this.processSettingFromFile(settingString)
			
			; Special: add a section title to the list display.
			} else if(firstChar = this.chars["SECTION_TITLE"]) {
				; DEBUG.popup("Label char", this.chars["SECTION_TITLE"], "First char", firstChar, "Row", currRow)
				; Format should be #{Space}Title
				idx := 0
				if(this.choices.MaxIndex())
					idx := this.choices.MaxIndex()
				idx++ ; The next actual choice will be the first one under this header, so match that.
				
				this.sectionTitles[idx] := SubStr(currItem[1], 3) ; If there are multiple headers in a row (for example when choices are filtered out) they should get overwritten in order here (which is correct).
				; DEBUG.popup("Just added nonchoice:", this.sectionTitles[this.sectionTitles.MaxIndex()], "At index", idx)
				
			; Invisible, but viable, choice.
			} else if(firstChar = this.chars["HIDDEN"]) {
				; DEBUG.popup("Hidden char", this.chars["HIDDEN"], "First char", firstChar, "Row", currRow)
				
				; DEBUG.popup("Hidden choice added", currRow)
				this.hiddenChoices.push(currRow)
			
			; Otherwise, it's a visible, viable choice!
			} else {
				; DEBUG.popup("Choice added", currRow)
				this.choices.push(currRow)
			}
		}
	}
	
	processSettingFromFile(settingString) {
		if(!settingString)
			return
		
		settingSplit := StrSplit(settingString, "=")
		name  := settingSplit[1]
		value := settingSplit[2]
		
		if(name = "ShowOverrideFields")
			this.guiSettings["ShowOverrideFields"] := (value = "1")
		else if(name = "RowsPerColumn")
			this.guiSettings["RowsPerColumn"] := value
		else if(name = "MinColumnWidth")
			this.guiSettings["MinColumnWidth"] := value
	}
	
	; Generate the text for the GUI and display it, returning the user's response.
	launchSelectorPopup(data) {
		static GuiInChoice
		GuiInChoice := "" ; Clear this to prevent bleed-over from previous uses. Must be on a separate line from the static declaration or it only happens once.
		
		; Create and begin styling the GUI.
		guiHandle := this.createSelectorGui()
		
		; GUI sizes
		marginLeft   := 10
		marginRight  := 10
		marginTop    := 10
		marginBottom := 10
		
		padIndexAbbrev := 5
		padAbbrevName  := 10
		padInputData   := 5
		padColumn      := 5
		
		widthIndex  := 25
		widthAbbrev := 50
		; (widthName and widthInputChoice/widthInputData exist but are calculated)
		
		heightLine  := 25
		heightInput := 24
	
		; Element starting positions (these get updated per column)
		xTitle       := marginLeft
		xIndex       := marginLeft
		xAbbrev      := xIndex  + widthIndex  + padIndexAbbrev
		xName        := xAbbrev + widthAbbrev + padAbbrevName
		xInputChoice := marginLeft
		
		xNameFirstCol := xName
		yCurrLine     := marginTop
		
		lineNum := 0
		columnNum := 1
		columnWidths := []
		
		For i,c in this.choices {
			lineNum++
			title := this.sectionTitles[i]
			
			; Add a new column as needed.
			if(this.needNewColumn(title, lineNum, this.guiSettings["RowsPerColumn"])) {
				columnNum++
				
				xLastColumnOffset := columnWidths[columnNum - 1] + padColumn
				xTitle  += xLastColumnOffset
				xIndex  += xLastColumnOffset
				xAbbrev += xLastColumnOffset
				xName   += xLastColumnOffset
				
				if(!title) { ; We're not starting a new title here, so show the previous one, continued.
					titleInstance++
					title := currTitle " (" titleInstance ")"
					isContinuedTitle := true
				}
				
				lineNum := 1
				yCurrLine := marginTop
			}
			
			; Title rows.
			if(title) {
				if(!isContinuedTitle) {
					titleInstance := 1
					currTitle := title
				} else {
					isContinuedTitle := false
				}
				
				; Extra newline above titles, unless they're on the first line of a column.
				if(lineNum > 1) {
					yCurrLine += heightLine
					lineNum++
				}
				
				applyTitleFormat()
				Gui, Add, Text, x%xTitle% y%yCurrLine%, %title%
				colWidthFromTitle := getLabelWidthForText(title, "title" i) ; This must happen before we revert formatting, so that current styling (mainly bolding) is taken into account.
				clearTitleFormat()
				
				yCurrLine += heightLine
				lineNum++
			}
			
			name := c.data["NAME"]
			if(IsObject(c.data["ABBREV"]))
				abbrev := c.data["ABBREV"][1]
			else
				abbrev := c.data["ABBREV"]
			
			Gui, Add, Text, x%xIndex%  y%yCurrLine% w%widthIndex%   Right, % i ")"
			Gui, Add, Text, x%xAbbrev% y%yCurrLine% w%widthAbbrev%,        % abbrev ":"
			Gui, Add, Text, x%xName%   y%yCurrLine%,                       % name
			
			widthName := getLabelWidthForText(name, "name" i)
			colWidthFromChoice := widthIndex + padIndexAbbrev + widthAbbrev + padAbbrevName + widthName
			
			columnWidths[columnNum] := max(columnWidths[columnNum], colWidthFromTitle, colWidthFromChoice, this.guiSettings["MinColumnWidth"])
			
			yCurrLine += heightLine
			maxColumnHeight := max(maxColumnHeight, yCurrLine)
		}
		
		widthTotal := this.getTotalWidth(columnWidths, padColumn, marginLeft, marginRight)
		yInput := maxColumnHeight + heightLine ; Extra empty row before inputs.
		if(this.guiSettings["ShowOverrideFields"])
			widthInputChoice := widthIndex + padIndexAbbrev + widthAbbrev ; Main edit control is same size as index + abbrev columns combined.
		else
			widthInputChoice := widthTotal - (marginLeft + marginRight)   ; Main edit control is nearly full width.
		Gui, Add, Edit, vGuiInChoice x%xInputChoice% y%yInput% w%widthInputChoice% h%heightInput% -E%WS_EX_CLIENTEDGE% +Border
		
		if(this.guiSettings["ShowOverrideFields"]) {
			numDataInputs := this.dataIndices.length()
			leftoverWidth  := widthTotal - xNameFirstCol - marginRight
			widthInputData := (leftoverWidth - ((numDataInputs - 1) * padInputData)) / numDataInputs
			
			xInput := xNameFirstCol
			For num,label in this.dataIndices {
				if(data[label]) ; Data given as default
					tempData := data[label]
				else            ; Data label (treat like ghost text, filter out later if not modified)
					tempData := label
				
				addInputField("GuiIn" num, xInput, yInput, widthInputData, heightInput, tempData)
				xInput += widthInputData + padInputData
			}
		}
		
		; Resize the GUI to show the newly added edit control row.
		heightTotal += maxColumnHeight + heightLine + heightInput + marginBottom ; maxColumnHeight includes marginTop, heightLine is for extra line between labels and inputs
		Gui, Show, h%heightTotal% w%widthTotal%, % this.guiSettings["WindowTitle"]
		
		; Focus the edit control.
		GuiControl, Focus,     GuiInChoice
		GuiControl, +0x800000, GuiInChoice
		
		; Wait for the user to submit the GUI.
		WinWaitClose, ahk_id %guiHandle%
		
		; Determine the user's choice (if any) and merge that info into the data array.
		if(GuiInChoice) ; User put something in the first box, which should come from the choices shown.
			choiceData := this.parseChoice(GuiInChoice)
			
		if(choiceData) {
			data := mergeArrays(data, choiceData)
			gotDataFromUser := true
		}
		
		; Read override data from any visible fields.
		if(this.guiSettings["ShowOverrideFields"]) {
			For num,label in this.dataIndices {
				inputVal := GuiIn%num% ; GuiIn* variables are declared via assume-global mode in addInputField(), and populated by Gui, Submit.
				if(inputVal && (inputVal != label)) {
					data[label] := inputVal
					gotDataFromUser := true
				}
			}
		}
		
		if(!gotDataFromUser)
			return ""
		return data
	}
	
	createSelectorGui() {
		Gui, Color, 2A211C
		Gui, Font, s12 cBDAE9D
		Gui, +LastFound
		Gui, Add, Button, Hidden Default +gSelectorSubmit ; Hidden button for {Enter} submission.
		return WinExist()
	}
	
	needNewColumn(ByRef sectionTitle, lineNum, rowsPerColumn) {
		; Special character in sectionTitle forces a new column
		if(SubStr(sectionTitle, 1, 2) = this.chars["NEW_COLUMN"] " ") {
			sectionTitle := SubStr(sectionTitle, 3) ; Strip special character and space off, they've served their purpose.
			return true
		}
		
		; Out of space in the column
		if(lineNum > rowsPerColumn)
			return true
		
		; Technically have one left, but the current one is a title
		; (which would leave the title by itself at the end of a column)
		if(sectionTitle && ((lineNum + 1) > rowsPerColumn))
			return true
		
		return false
	}
	
	getTotalWidth(columnWidths, paddingBetweenColumns, leftMargin, rightMargin) {
		totalWidth := 0
		
		totalWidth += leftMargin
		Loop, % columnWidths.MaxIndex() {
			if(A_Index > 1)
				totalWidth += paddingBetweenColumns
			totalWidth += columnWidths[A_Index]
		}
		totalWidth += rightMargin
		
		return totalWidth
	}
	
	; Function to turn the input into something useful.
	parseChoice(userChoiceString) {
		commandCharPos := InStr(userChoiceString, this.chars["COMMAND"])
		
		rowToDo := ""
		rest := SubStr(userChoiceString, 2)
		
		; No input in main box, but others possibly filled out
		if(userChoiceString = "") {
			return ""
		
		; Command choice - edit ini, etc.
		} else if(commandCharPos = 1) {
			; DEBUG.popup("Got command", rest)
			commandChar := SubStr(rest, 1, 1)
			
			; Special case: +e is the edit action, which will open the current INI file for editing.
			if(commandChar = this.chars["COMMANDS", "EDIT"]) {
				Run(this.filePath)
				return ""
			}
		
		; Otherwise, we search through the data structure by both number and shortcut and look for a match.
		} else {
			rowToDo := this.searchAllTables(userChoiceString)
		}
		
		; DEBUG.popup("Row to do", rowToDo)
		
		return rowToDo.data
	}

	; Search both given tables, the visible and the invisible.
	searchAllTables(input) {
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
		debugBuilder.addLine("Chars",          this.chars)
		debugBuilder.addLine("Data indices",   this.dataIndices)
		debugBuilder.addLine("GUI settings",   this.guiSettings)
		debugBuilder.addLine("Filepath",       this.filePath)
		debugBuilder.addLine("Choices",        this.choices)
		debugBuilder.addLine("Hidden Choices", this.hiddenChoices)
		debugBuilder.addLine("Section titles", this.sectionTitles)
	}
}