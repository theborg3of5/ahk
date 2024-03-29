#Include selectorGui.ahk
#Include selectorChoice.ahk

/* Class that selects an option from a given set of choices, and returns info about that choice. =--
	=-- Choices
			Choices are read from a TableList Selector (.tls) file. See documentation for the TableList class for general file format (applies to .tl or tls files), and "File Format" below for additional Selector-specific details.
			These choices may also be filtered (see the documentation for .dataTableList below) - this allows you to use a single file of information to be used in different ways.
		
	--- Selection
			This class can be used in one of two ways:
			1. Gui method (.selectGui())
					Show a popup containing the available choices and a field where the user can enter their selection using either the index or abbreviation of a choice. If override fields are visible (see "Data Override Fields" below) they can override specific information about that choice (or even submit the popup without a choice, only overrides) as well.
					
					The user may also enter the command character (+) followed by one of these letters to do something instead of picking a choice:
						e - edit
							Entering +e in the choice field will open the TableList file used to generate the popup.
				
			2. Silent method (.selectChoice())
					Select a choice silently, based on programmatic input.
			
	--- File Format
			Starting a row in the TableList file with certain characters has special meaning (beyond those documented in the TableList class):
				[ - Model row (required, should end with a corresponding ])
					The file should include a single model row (above all choices), which gives a name to each column in the file. Most column names will simply determine the subscript in the return array that the data from that column will be returned in, but these columns have special meaning:
							NAME   - This is the display name for a choice in the popup that can be shown to a user.
							ABBREV - This is displayed next to the display name for a choice in the popup. Additionally, a choice can be selected using the abbreviation (in addition to the index).
					Example:
						[	NAME		ABBREV		PATH	]
					Result:
						Values in the NAME and ABBREV columns will be displayed for choices as described above, and the return array will have a "PATH" subscript with the corresponding value from the selected choice.
					
				) - Override field index row
					These rows assign a numeric index to each column in the model row. This index will be the position the corresponding data override field will have in the popup. An index of 0 tells the UI not to show the field corresponding to that column at all. Note that the existence of this row will cause data override fields to be shown - the fields can be programmatically suppressed using the .overrideFieldsOff() function. See "Data Override Fields" below for more details.
					Example:
						[	NAME		ABBREV		PATH	]
						(	0			0				1		)
					Result:
						A "PATH" field will appear next to the choice field.
					
				@ - Gui setting
					All gui settings (see "Gui Settings" below for a list) may be preset in the file using a line that starts with the @ character, with an = between the name of the setting and the value.
					Example:
						@WindowTitle(This is the new title!)
					Result:
						The popup's title will be "This is the new title!"
					
				#  - Section title
					Starting a row with this character (plus a space) will start a new "section" in the popup, with an extra newline followed by the rest of the row's text as a title (bolded/underlined). Note that if no choices appear after one of these rows (which can happen when filtering choices), only the most recent section title row will apply. Additionally, you can force a new super-column in the popup using an exclamation point (!) character - see "New column" character below.
					Example:
						# Stuff
					Result:
						The popup will contain a (bolded/underlined) header of "Stuff".
					
			Certain characters can be included within a row to additional effect:
				| - Abbreviation delimiter
					You can give an individual choice multiple abbreviations that can all be used to select the choice, separated by this character. Only the first abbreviation will be displayed.
					Example:
						Programs		prog | prg		programs.tls
					Result:
						The "Programs" choice will appear in the popup with an abbreviation of "prog", but the "prg" abbreviation may also be used to select that choice.
					
				! - New column (in section title row)
					If this character is put at the beginning of a section title row (with a space on either side), that title will force a new super-column in the popup.
					Example:
						# ! Title
					Result:
						The "Title" section will start a new super-column in the popup.
			
	--- Gui Settings
			Some settings related to the popup may be customized by specifying them in the TLS file (using the @ character, see "Settings" character above).
			Note that these settings only have an effect on the popup shown by .selectGui().
			
			Available settings:
				WindowTitle
					This will be the title of the popup shown to the user. This setting may also be set using the title parameter of .selectGui().
				
				MinColumnWidth
					If this is set, each super-column in the popup will be that number of pixels wide at a minimum (each may be wider if the choices in that column are wider). See the FlexTable class for how super-columns work.
			
	--- Data Override Fields
			If an override field index row is specified in the TLS file, the popup shown by .selectGui() will include not only a choice field, but also fields for each column given a non-zero index in the override field index row. The fields are shown in the order specified by the row (i.e. 1 is first after the choice field, 2 is second, etc.). That the fields can be programmatically suppressed using the .overrideFieldsOff() function.
			These fields give a user the ability to override data from their selected choice (or submit the popup without a choice, only overrides). If the user changes the value of the field (it defaults to the column label), that value will be used instead of the selected choice's value for that column.
			Even if there is no override field index row in the TLS file, the .addOverrideFields() function may be used to add additional fields to the popup. The values from these fields will appear in the return array just like other override fields, under the subscript with their name.
			Values may be defaulted into these fields using the .setDefaultOverrides() function.
			
	--- Example Usage (Popup)
;			s := new Selector("C:\ahk\configs.tls")                             ; Read in the "configs.tls" TLS file
;			s.setTitle("New title!")                                            ; Set the popup's title to "New title!"
;			s.dataTableList.filterOutIfColumnNoMatch("MACHINE", "HOME_DESKTOP") ; Only include choices which which have the "MACHINE" column set to "HOME_DESKTOP" (or blank)
;			s.addOverrideFields(["CONFIG_NAME", "CONFIG_NUM"])                  ; Two additional override fields for the popup.
;			s.setDefaultOverrides({CONFIG_NAME: "Windows"})                     ; Default a value of "Windows" into the "CONFIG_NAME" override field
;			
;			data := s.selectGui()                                               ; Show the popup and retrieve the entire data array
;			MsgBox, % "Chosen config name: " data["CONFIG_NAME"]
;			MsgBox, % "Chosen config num: "  data["CONFIG_NUM"]
			
	--- Example Usage (Silent)
;			pathAbbrev := <user input>
;			
;			s := new Selector("C:\ahk\paths.tls")      ; Read in the "paths.tls" TLS file
;			path := s.selectChoice(pathAbbrev, "PATH") ; Return only the "PATH" value, not the whole return array
			
	--=
*/ ; --=

class Selector {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    The TableList instance that holds all data read from the file, available so
	;                 that callers can apply filtering if needed. See TableList for available
	;                 filtering functions.
	;---------
	dataTableList {
		get {
			return this.dataTL
		}
	}
	
	;---------
	; DESCRIPTION:    Creates a new instance of the Selector class.
	; PARAMETERS:
	;  filePath (I,OPT) - The Selector file (.tls) where the choices that will be selected from will be
	;                     read from. See above for format.
	; RETURNS:        A new Selector object.
	;---------
	__New(filePath := "") {
		if(filePath) {
			this.filePath := FileLib.findConfigFilePath(filePath)
			this.loadFromFile()
		}
		
		; Debug.popup("Selector.__New", "Finish", "Filepath", this.filePath, "State", this)
	}
	
	;---------
	; DESCRIPTION:    Turn off the override fields in the popup.
	; RETURNS:        this
	;---------
	overrideFieldsOff() {
		this.overrideFields := "" ; Get rid of override fields entirely.
		return this
	}
	
	;---------
	; DESCRIPTION:    Set the popup's title.
	; PARAMETERS:
	;  title (I,REQ) - The title to use.
	; RETURNS:        this
	;---------
	setTitle(title) {
		this._windowTitle := title
		return this
	}
	
	;---------
	; DESCRIPTION:    Add additional override fields to the popup shown to the user, and return whatever data
	;                 they add (or is defaulted in) in the final return array.
	; PARAMETERS:
	;  fieldsToAdd (I,REQ) - Numerically-indexed object of field names (treated the same as column names from choices) to add.
	; NOTES:          This should be called after creating a new Selector object, but before calling .selectGui()/.select().
	;                 Default override values for these fields (if desired) can be set using the .setDefaultOverrides() function.
	;---------
	addOverrideFields(fieldsToAdd) {
		if(!this.overrideFields)
			this.overrideFields := {}
		
		baseLength := this.overrideFields.count()
		For i,label in fieldsToAdd
			this.overrideFields[baseLength + i] := label
		
		return this
	}
	
	;---------
	; DESCRIPTION:    Set the default values for the override fields in the popup.
	; PARAMETERS:
	;  defaultOverrides (I,REQ) - Associative array fo default overrides, format:
	;                              {columnLabel: value}
	; RETURNS:        this
	; NOTES:          These overrides are only used if you do a user selection (.selectGui(), or
	;                 .select() with a blank choiceString) - otherwise they are ignored.
	;---------
	setDefaultOverrides(defaultOverrides) {
		this.defaultOverrides := defaultOverrides
		return this
	}
	
	;---------
	; DESCRIPTION:    Add a single section header.
	; PARAMETERS:
	;  headerText       (I,REQ) - The text to use for the header.
	;  firstChoiceIndex (I,OPT) - The index of the first choice that will be in this section. If not passed, the header will be added
	;                             at the end of the current list of choices (that is, the next choice that's added will be the first
	;                             in this section).
	;---------
	addSectionHeader(headerText, firstChoiceIndex := "") {
		if(!this.sectionTitles)
			this.sectionTitles := {}
		if(firstChoiceIndex = "")
			firstChoiceIndex := this.choices.length() + 1
		
		this.sectionTitles[firstChoiceIndex] := headerText
	}
	
	;---------
	; DESCRIPTION:    Add a single choice programmatically.
	; PARAMETERS:
	;  choice (I,REQ) - SelectorChoice instance to add.
	; RETURNS:        Current count of choices.
	;---------
	addChoice(choice) {
		if(!this.choices)
			this.choices := []
		
		this.choices.push(choice)
		
		return this.choices.length()
	}
	
	;---------
	; DESCRIPTION:    Show a popup to the user so they can select one of the choices we've prepared
	;                 and enter any additional override information.
	; PARAMETERS:
	;  returnColumn (I,OPT) - If this parameter is given, only the data under the column with this
	;                         name will be returned.
	; RETURNS:        An array of data as chosen/overridden by the user. If the returnColumn
	;                 parameter was specified, only the subscript matching that name will be
	;                 returned.
	;---------
	selectGui(returnColumn := "") {
		if(!this.loadChoicesFromData())
			return ""
		
		data := this.doSelectGui()
		
		if(DataLib.isNullOrEmpty(data))
			return ""
		else if(returnColumn)
			return data[returnColumn]
		else
			return data
	}
	
	;---------
	; DESCRIPTION:    Programmatically select a choice from those we've prepared.
	; PARAMETERS:
	;  choiceString (I,REQ) - The string to try and match against the given choices. We will match this string
	;                         against the index or abbreviation of the choice.
	;  returnColumn (I,OPT) - If this parameter is given, only the data under the column with this name will
	;                         be returned.
	; RETURNS:        An array of data for the choice matching the given string. If the returnColumn parameter
	;                 was specified, only the subscript matching that name will be returned.
	;---------
	selectChoice(choiceString, returnColumn := "") {
		if(!choiceString)
			return ""
		
		if(!this.loadChoicesFromData())
			return ""
		
		data := this.parseChoice(choiceString)
		if(returnColumn)
			return data[returnColumn]
		else
			return data
	}
	
	;---------
	; DESCRIPTION:    Helper function that will try to run a silent selection based on the input,
	;                 but if that fails it will prompt the user.
	; PARAMETERS:
	;  choiceString (I,OPT) - The string to try and match against the given choices. If this is not
	;                         blank, we'll match it against the index or abbreviation of the choices
	;                         first. If that doesn't return anything or if this parameter was blank
	;                         we'll call .selectGui() to show a popup to the user where they pick
	;                         their choice and enter any additional override information.
	;  returnColumn (I,OPT) - If this parameter is given, only the data under the column with this name will
	;                         be returned.
	; RETURNS:        An array of data for the choice matching the given string. If the returnColumn
	;                 parameter was specified, only the subscript matching that name will be returned.
	;---------
	select(choiceString := "", returnColumn := "") {
		if(!this.loadChoicesFromData())
			return ""
		
		; If something is given, try that silently first
		if(choiceString)
			data := this.parseChoice(choiceString)
		
		; If we don't have a result yet, prompt the user.
		if(!data)
			data := this.doSelectGui()
		
		; If there's no result return "" so callers can just check !data
		if(DataLib.isNullOrEmpty(data))
			return ""
		
		; Return a specific column if requested
		if(returnColumn)
			return data[returnColumn]
		
		return data
	}
	
	; @NPP-TABLELIST@
	;---------
	; NPP-DEF-LINE:   WindowTitle(title)
	; NPP-RETURNS:    @
	; DESCRIPTION:    If this is set, we'll show the given text as the window title (aka the caption).
	; PARAMETERS:
	;  title (I,REQ) - The title to use.
	;---------
	
	;---------
	; NPP-DEF-LINE:   MinColumnWidth(minWidth)
	; NPP-RETURNS:    @
	; DESCRIPTION:    If this is set, each super-column in the display will be at least this wide.
	; PARAMETERS:
	;  minWidth (I,REQ) - The minimum width (in pixels).
	;---------
	; @NPP-TABLELIST-END@
	
	
	; #PRIVATE#
	
	static Char_CommandStart := "+"
	static Char_Command_Edit := "e"
	
	_windowTitle     := "Please make a choice by either index or abbreviation:" ; The title of the window
	_minColumnWidth  := 0     ; How wide (in pixels) each column must be, at a minimum.
	choices          := ""    ; Array of visible choices the user can pick from (array of SelectorChoice objects).
	sectionTitles    := ""    ; {choiceIndex: title} - Lines that will be displayed as titles (index matches the first choice that should be under this title)
	overrideFields   := ""    ; {fieldIndex: label} - Mapping from override field indices => data labels (column headers)
	filePath         := ""    ; Where the file lives if we're reading one in.
	defaultOverrides := ""    ; {columnLabel: value} - Default values to show in override fields, by column name
	dataTL           := ""    ; TableList instance read from file, which we'll extract choice and other info from.
	
	;---------
	; DESCRIPTION:    Read everything from the TLS file into a TableList instance and load most of
	;                 it into this class.
	; NOTES:          This reads the choices into the TableList instance, but it does not load them
	;                 into this class until we're actually doing selection (as before then the
	;                 caller can still modify them by filtering the TableList via .dataTableList).
	;---------
	loadFromFile() {
		tl := new TableList(this.filePath)
		
		this.updateSettings(tl.settings)
		
		; Special override field index row that tells us how we should arrange data inputs.
		fieldIndices := tl.columnInfo
		if(!DataLib.isNullOrEmpty(fieldIndices)) {
			this.overrideFields := {}
			For label,fieldIndex in fieldIndices {
				if(fieldIndex > 0) ; Ignore data columns we don't want fields for (fieldIndex = 0)
					this.overrideFields[fieldIndex] := label
			}
		}
		
		this.dataTL := tl
	}
	
	;---------
	; DESCRIPTION:    Update our settings based on the array of settings from the TLS file.
	; PARAMETERS:
	;  settings (I,REQ) - Associative array of settings. Format:
	;                      settings[name] := value
	;---------
	updateSettings(settings) {
		For name,value in settings {
			; The (@)NPP-TABLELIST section in this class should be kept up-to-date with all available settings.
			Switch name {
				Case "WindowTitle":    this._windowTitle := value
				Case "MinColumnWidth": this._minColumnWidth := value
			}
		}
	}
	
	;---------
	; DESCRIPTION:    Load the choices from our data TableList instance.
	; RETURNS:        true if all went well, false if there was an error and we should abort.
	; SIDE EFFECTS:   Shows an error toast if something went wrong.
	;---------
	loadChoicesFromData() {
		; If choices have already been added (programmatically) and there's no TableList to pull from, we're done.
		if(this.choices && !this.dataTL)
			return true
		
		; Load the section headers
		this.sectionTitles := this.dataTL.headers
		
		; Load the choices
		this.choices := []
		For _,row in this.dataTL.getTable()
			this.addChoice(new SelectorChoice(row))
		
		; Show a warning and fail if we didn't actually manage to load any choices.
		if(!this.choices.length()) {
			Toast.ShowError("Selector: no choices available", "No choices were found in the TableList instance")
			return false
		}
		
		return true
	}
	
	;---------
	; DESCRIPTION:    Generate and show a popup to the user where they can select a
	;                 choice and override specific data, then retrieving, processing,
	;                 and merging that data as appropriate.
	; RETURNS:        Merged array of data, which includes both the choice and any
	;                 overrides.
	;---------
	doSelectGui() {
		if(!this.validateChoices())
			return ""
		
		sGui := new SelectorGui(this.choices, this.sectionTitles, this.overrideFields, this._minColumnWidth)
		sGui.show(this._windowTitle, this.defaultOverrides)
		
		; User's choice is main data source
		choiceData := this.parseChoice(sGui.getChoiceQuery(), suppressData)
		if(suppressData)
			return ""
		
		; Override fields can add to that too.
		overrideData := sGui.getOverrideData()
		
		; Return the combination of the choice and overrides.
		if(choiceData)
			return choiceData.mergeFromObject(overrideData)
		else
			return overrideData
	}
	
	;---------
	; DESCRIPTION:    Do some sanity checks to make sure the given choices are valid.
	; RETURNS:        true if all is well, false (and show popup) on error.
	;---------
	validateChoices() {
		; Abbreviation checks:
		;  - All choices must have an abbreviation
		;  - No abbreviations may be repeated
		empties         := [] ; [SelectorChoice]
		duplicates      := {} ; { abbreviation: [SelectorChoice] }
		choicesByAbbrev := {} ; { abbreviation: SelectorChoice }
		For _,choice in this.choices {
			choiceAbbrevs := choice.data["ABBREV"]
			if(choiceAbbrevs = "") {
				empties.push(choice)
				Continue
			}
			
			For _,abbrev in DataLib.forceArray(choiceAbbrevs) { ; forceArray because this could be an array or single value
				; We've already seen this abbreviation.
				if(choicesByAbbrev[abbrev]) {
					if(!duplicates[abbrev])
						duplicates[abbrev] := [ choicesByAbbrev[abbrev] ] ; The original choice with this abbreviation
					duplicates[abbrev].push(choice) ; The offending duplicate(s)
					Continue
				}
				
				choicesByAbbrev[abbrev] := choice
			}
		}
		
		; All clear, no problems found.
		if(DataLib.isNullOrEmpty(empties) && DataLib.isNullOrEmpty(duplicates))
			return true
		
		; Build error message
		table := new DebugTable("Choices with invalid abbreviations").setBorderType(TextTable.BorderType_BoldLine)
		if(!DataLib.isNullOrEmpty(empties))
			table.addLine("Blank", empties)
		if(!DataLib.isNullOrEmpty(duplicates))
			table.addLine("Duplicates", duplicates)
		
		new TextPopup(table).show()
		if(this.filePath)
			RunLib.runAsUser(this.filePath) ; Open file to fix it
		return false
	}
	
	;---------
	; DESCRIPTION:    Process a user's choice input, handling special commands or finding
	;                 a choice matching the input. For matching against choices, the string
	;                 must be either the index of the choice (for visible choices), or the
	;                 abbreviation.
	; PARAMETERS:
	;  userChoiceString (I,REQ) - The string that the user typed in the choice field.
	;  suppressData     (O,OPT) - Will be set to true if we should return empty data (like when the
	;                             edit command is entered)
	; RETURNS:        If we found a matching choice (and the input wasn't a command), the
	;                 data array from that choice. Otherwise, "".
	;---------
	parseChoice(userChoiceString, ByRef suppressData := "") {
		suppressData := false
		
		; Command choice - edit ini, etc.
		if(userChoiceString.startsWith(this.Char_CommandStart)) {
			commandChar := userChoiceString.afterString(this.Char_CommandStart)
			
			; Edit action - open the current INI file for editing
			if(commandChar = this.Char_Command_Edit) {
				suppressData := true
				RunLib.runAsUser(this.filePath)
			}
			
			return ""
		
		; Otherwise, we search through the data structure by both number and shortcut and look for a match.
		} else {
			return this.searchChoices(userChoiceString)
		}
	}
	
	;---------
	; DESCRIPTION:    Search loaded choices for a match.
	; PARAMETERS:
	;  input (I,REQ) - The string to match against choices.
	; RETURNS:        If we found a match, the data array from that choice.
	;                 If not, "".
	;---------
	searchChoices(input) {
		For i,t in this.choices {
			; Index
			if(input = i)
				return t.data
			
			; Abbreviation
			if(t.matchesAbbrev(input))
				return t.data
		}
		
		return ""
	}
	
	
	; #DEBUG#
	
	Debug_ToString(ByRef table) {
		table.addLine("Filepath",          this.filePath)
		table.addLine("Window title",      this._windowTitle)
		table.addLine("Min column width",  this._minColumnWidth)
		table.addLine("Override fields",   this.overrideFields)
		table.addLine("Default overrides", this.defaultOverrides)
		table.addLine("Choices",           this.choices)
		table.addLine("Section titles",    this.sectionTitles)
		table.addLine("Data TableList",    this.dataTL)
	}
	; #END#
}
