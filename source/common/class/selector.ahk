#Include selectorGui.ahk
#Include selectorChoice.ahk

/* Class that selects an option from a given set of choices, and returns info about that choice.
	
	Choices
		Choices are read from a TableList Selector (.tls) file. See documentation for the TableList class for general file format (applies to .tl or tls files), and "File Format" below for additional Selector-specific details.
		These choices may also be filtered (see the documentation for .dataTL below) - this allows you to use a single file of information to be used in different ways.
		
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
				
			) - override field index row
				These rows assign a numeric index to each column in the model row. This index will be the position the corresponding data override field will have in the popup. An index of 0 tells the UI not to show the field corresponding to that column at all. Note that the existence of this row will cause data override fields to be shown - the fields can be programmatically suppressed using .selectGui()'s suppressOverrideFields parameter. See "Data Override Fields" below for more details.
				Example:
					(	NAME		ABBREV		PATH
					)	0			0				1
				Result:
					A "PATH" field will appear next to the choice field.
				
			@ - Gui setting
				All gui settings (see "Gui Settings" below for a list) may be preset in the file using a line that starts with the @ character, with an = between the name of the setting and the value.
				Example:
					@WindowTitle=This is the new title!
				Result:
					The popup's title will be "This is the new title!"
				
			#  - Section title
				Starting a row with this character (plus a space) will start a new "section" in the popup, with an extra newline followed by the rest of the row's text as a title (bolded/underlined). Note that if no choices appear after one of these rows (which can happen when filtering choices), only the most recent section title row will apply. Additionally, you can force a new super-column in the popup using a pipe (|) character - see "New column" character below.
				Example:
					# Stuff
				Result:
					The popup will contain a (bolded/underlined) header of "Stuff".
				
		Certain characters can be included within a row to additional effect:
			| - Abbreviation delimiter
				You can give an individual choice multiple abbreviations that can all be used to select the choice, separated by this character. Only the first abbreviation will be displayed.
				Example:
					Programs		prog|prg		programs.tls
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
			1. Specified in the TLS file (using the @ character, see "Settings" character above)
			2. Programmatically, using the .setGuiSetting() function
		Note that these settings only have an effect on the popup shown by .selectGui().
		
		Available settings:
			WindowTitle
				This will be the title of the popup shown to the user. This setting may also be set using the title parameter of .selectGui().
			
			MinColumnWidth
				If this is set, each super-column in the popup will be that number of pixels wide at a minimum (each may be wider if the choices in that column are wider). See the FlexTable class for how super-columns work.
		
	Data Override Fields
		If an override field index row is specified in the TLS file, the popup shown by .selectGui() will include not only a choice field, but also fields for each column given a non-zero index in the override field index row. The fields are shown in the order specified by the row (i.e. 1 is first after the choice field, 2 is second, etc.). That the fields can be programmatically suppressed using .selectGui()'s suppressOverrideFields parameter.
		These fields give a user the ability to override data from their selected choice (or submit the popup without a choice, only overrides). If the user changes the value of the field (it defaults to the column label), that value will be used instead of the selected choice's value for that column.
		Even if there is no override field index row in the TLS file, the .addExtraOverrideFields() function may be used to add additional fields to the popup. The values from these fields will appear in the return array just like other override fields, under the subscript with their name.
		Values may be defaulted into these fields using .selectGui()'s defaultOverrideData parameter.
	
	Example Usage (Popup)
		extraDataFields := ["CONFIG_NAME", "CONFIG_NUM"]           ; Two additional override fields for the popup.
		defaultOverrideData := {CONFIG_NAME: "Windows"}            ; Default a value of "Windows" into the "CONFIG_NAME" override field
		
		s := new Selector("C:\ahk\configs.tls")                    ; Read in the "configs.tls" TLS file
		s.dataTL.filterByColumn("MACHINE", "HOME_DESKTOP")         ; Only include choices which which have the "MACHINE" column set to "HOME_DESKTOP" (or blank)
		s.setGuiSetting("MinColumnWidth", 500)                     ; Set the minimum super-column width to 500 pixels
		s.addExtraOverrideFields(extraDataFields)                  ; Add the extra override fields
		
		data := s.selectGui("", "New title!", defaultOverrideData) ; Show the popup with a title of "New title!" and the default override field values specified above
		MsgBox, % "Chosen config name: " data["CONFIG_NAME"]
		MsgBox, % "Chosen config num: "  data["CONFIG_NUM"]
		
	Example Usage (Silent)
		pathAbbrev := <user input>
		
		s := new Selector("C:\ahk\paths.tls")      ; Read in the "paths.tls" TLS file
		path := s.selectChoice(pathAbbrev, "PATH") ; Return only the "PATH" value, not the whole return array
*/

class Selector {

; ==============================
; == Public ====================
; ==============================
	
	;---------
	; DESCRIPTION:    The TableList instance that holds all data read from the file, available so
	;                 that callers can apply filtering if needed. See TableList for available
	;                 filtering functions.
	;---------
	dataTL[] {
		get {
			return this._dataTL
		}
	}
	
	;---------
	; DESCRIPTION:    Creates a new instance of the Selector class.
	; PARAMETERS:
	;  filePath (I,REQ) - The Selector file (.tls) where the choices that will be selected from will be
	;                     read from. See above for format.
	; RETURNS:        A new Selector object.
	;---------
	__New(filePath) {
		this.setDefaultGuiSettings()
		
		if(filePath) {
			this.filePath := findConfigFilePath(filePath)
			this.getDataFromFile()
		}
		
		; DEBUG.popup("Selector.__New", "Finish", "Filepath", this.filePath, "State", this)
	}
	
	;---------
	; DESCRIPTION:    Override a gui-related setting. The list of these settings and what they do may be found
	;                 in the class documentation above.
	; PARAMETERS:
	;  name  (I,REQ) - Name of the setting to override.
	;  value (I,OPT) - Value to set the setting to. Defaults to blank.
	; NOTES:          This should be called after creating a new Selector object, but before calling .selectGui().
	;---------
	setGuiSetting(name, value := "") {
		if(name = "")
			return
		
		this.guiSettings[name] := value
	}
	
	;---------
	; DESCRIPTION:    Add additional override fields to the popup shown to the user, and return whatever data
	;                 they add (or is defaulted in) in the final return array.
	; PARAMETERS:
	;  extraDataFields (I,REQ) - Numerically-indexed array of field names (treated the same as column names from
	;                            choices) to add.
	; NOTES:          This should be called after creating a new Selector object, but before calling .selectGui().
	;                 Default override values for these fields (if desired) can be set using .selectGui()'s
	;                 defaultOverrideData parameter.
	;---------
	addExtraOverrideFields(extraDataFields) {
		if(!this.overrideFields)
			this.overrideFields := {}
		
		baseLength := this.overrideFields.count()
		For i,label in extraDataFields
			this.overrideFields[baseLength + i] := label
	}
	
	;---------
	; DESCRIPTION:    Show a popup to the user so they can select one of the choices we've prepared and 
	;                 enter any additional override information.
	; PARAMETERS:
	;  returnColumn           (I,OPT) - If this parameter is given, only the data under the column with
	;                                   this name will be returned.
	;  title                  (I,OPT) - If you want to override the title set in the TLS file (or defaulted
	;                                   from this class), pass in the desired title here.
	;  defaultOverrideData    (I,OPT) - If you want to default values into the override fields shown to
	;                                   the user, pass those values in an array here. Format:
	;                                      defaultOverrideData["fieldName"] := value
	;  suppressOverrideFields (I,OPT) - If the TLS file would normally show override fields (by virtue of
	;                                   having an override field index row), you can still hide those
	;                                   fields by setting this parameter to true.
	; RETURNS:        An array of data as chosen/overridden by the user. If the returnColumn parameter was
	;                 specified, only the subscript matching that name will be returned.
	;---------
	selectGui(returnColumn := "", title := "", defaultOverrideData := "", suppressOverrideFields := false) {
		; DEBUG.popup("Selector.selectGui", "Start", "Default override data", defaultOverrideData, "GUI Settings", guiSettings)
		if(!this.loadFromData())
			return ""
		
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
		
		if(!this.loadFromData())
			return ""
		
		data := this.parseChoice(choiceString)
		if(returnColumn)
			return data[returnColumn]
		else
			return data
	}
	
	;---------
	; DESCRIPTION:    Helper function that calls either .selectGui() or .selectChoice() based on whether the
	;                 given choice is blank.
	; PARAMETERS:
	;  choiceString (I,OPT) - The string to try and match against the given choices. If this is blank, we'll
	;                         call .selectGui() to show a popup to the user where they pick their choice and
	;                         enter any additional override information. If this is not blank, we'll match
	;                         it against the index or abbreviation of the choices and return the results.
	;  returnColumn (I,OPT) - If this parameter is given, only the data under the column with this name will
	;                         be returned.
	; RETURNS:        An array of data for the choice matching the given string. If the returnColumn
	;                 parameter was specified, only the subscript matching that name will be returned.
	;---------
	select(choiceString := "", returnColumn := "") {
		if(choiceString)
			return this.selectChoice(choiceString, returnColumn)
		else
			return this.selectGui(returnColumn)
	}
	
	
; ==============================
; == Private ===================
; ==============================
	
	static Char_OverrideFieldIndex := ")"
	static Char_CommandStart       := "+"
	static Char_Command_Edit       := "e"
	
	choices        := []    ; Array of visible choices the user can pick from (array of SelectorChoice objects).
	sectionTitles  := {}    ; {choiceIndex: title} - Lines that will be displayed as titles (index matches the first choice that should be under this title)
	overrideFields := ""    ; {fieldIndex: label} - Mapping from override field indices => data labels (column headers)
	guiSettings    := {}    ; {settingName: value} - Settings related to the GUI popup we show
	filePath       := ""    ; Where the file lives if we're reading one in.
	suppressData   := false ; Whether to ignore all data from the user (choice and overrides). Typically used when we've done something else (like edit the TLS file).
	_dataTL        := ""    ; TableList instance read from file, which we'll extract choice and other info from.
	
	;---------
	; DESCRIPTION:    Populate this.guiSettings with our defaults for various gui settings.
	;---------
	setDefaultGuiSettings() {
		this.guiSettings["MinColumnWidth"] := 0
		this.guiSettings["WindowTitle"]    := "Please make a choice by either number or abbreviation:"
	}
	
	;---------
	; DESCRIPTION:    Load the choices and other information from the TLS file into a TableList instance.
	;---------
	getDataFromFile() {
		this._dataTL := new TableList(this.filePath, {this.Char_OverrideFieldIndex: "OVERRIDE_INDEX"})
	}
	
	;---------
	; DESCRIPTION:    Load info from our data TableList instance into the various members used to
	;                 actually launch a selector.
	; RETURNS:        true if all went well, false if there was an error and we should abort.
	; SIDE EFFECTS:   Shows an error toast if something went wrong.
	;---------
	loadFromData() {
		tl := this._dataTL
		
		this.sectionTitles := tl.headers
		For name,value in tl.settings
			this.setGuiSetting(name, value)
		
		; Special override field index row that tells us how we should arrange data inputs.
		fieldIndices := tl.keyRow["OVERRIDE_INDEX"]
		if(fieldIndices) {
			this.overrideFields := {}
			For label,fieldIndex in fieldIndices {
				if(fieldIndex > 0) ; Ignore data columns we don't want fields for (fieldIndex = 0)
					this.overrideFields[fieldIndex] := label
			}
		}
		
		For _,row in tl.getTable()
			this.choices.push(new SelectorChoice(row))
		
		; Show a warning and fail if we didn't actually manage to load any choices.
		if(!this.choices.length()) {
			Toast.showError("Selector: no choices available", "No choices were found in the TableList instance")
			return false
		}
		
		return true
	}
	
	;---------
	; DESCRIPTION:    Generate and show a popup to the user where they can select a
	;                 choice and override specific data, then retrieving, processing,
	;                 and merging that data as appropriate.
	; PARAMETERS:
	;  defaultOverrideData (I,REQ) - Array of data to default into override fields. Format:
	;                                   defaultOverrideData["fieldName"] := value
	; RETURNS:        Merged array of data, which includes both the choice and any
	;                 overrides.
	;---------
	doSelectGui(defaultOverrideData) {
		sGui := new SelectorGui(this.choices, this.sectionTitles, this.overrideFields, this.guiSettings["MinColumnWidth"])
		sGui.show(this.guiSettings["WindowTitle"], defaultOverrideData)
		
		; User's choice is main data source
		choiceData := this.parseChoice(sGui.getChoiceQuery())
		if(this.suppressData)
			return ""
		
		; Override fields can add to that too.
		overrideData := sGui.getOverrideData()
		
		; DEBUG.popup("Selector.doSelectGui","Finish", "Choice data",choiceData, "Override data",overrideData, "Merged data",mergeObjects(choiceData, overrideData))
		return mergeObjects(choiceData, overrideData)
	}
	
	;---------
	; DESCRIPTION:    Process a user's choice input, handling special commands or finding
	;                 a choice matching the input. For matching against choices, the string
	;                 must be either the index of the choice (for visible choices), or the
	;                 abbreviation.
	; PARAMETERS:
	;  userChoiceString (I,REQ) - The string that the user typed in the choice field.
	; RETURNS:        If we found a matching choice (and the input wasn't a command), the
	;                 data array from that choice. Otherwise, "".
	;---------
	parseChoice(userChoiceString) {
		; Command choice - edit ini, etc.
		if(userChoiceString.startsWith(this.Char_CommandStart)) {
			commandChar := userChoiceString.afterString(this.Char_CommandStart)
			
			; Edit action - open the current INI file for editing
			if(commandChar = this.Char_Command_Edit) {
				this.suppressData := true
				Run(this.filePath)
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
	
	
	; Debug info (used by the Debug class)
	debugName := "Selector"
	debugToString(debugBuilder) {
		debugBuilder.addLine("Chars",           this.chars)
		debugBuilder.addLine("Override fields", this.overrideFields)
		debugBuilder.addLine("GUI settings",    this.guiSettings)
		debugBuilder.addLine("Filepath",        this.filePath)
		debugBuilder.addLine("Suppress data?",  this.suppressData)
		debugBuilder.addLine("Choices",         this.choices)
		debugBuilder.addLine("Section titles",  this.sectionTitles)
	}
}