/* Class for generating and interacting with a Selector popup.
	
	Usage:
		Create a new SelectorGui instance
		Show popup (.show)
		Get any needed info back (.getChoiceQuery, .getOverrideData)
	
*/

class SelectorGui {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Create a new SelectorGui instance.
	; PARAMETERS:
	;  choices        (I,REQ) - Array of SelectorChoice objects containing the information we need 
	;                           (name and abbreviation) to show a list of choices to the user.
	;  sectionHeaders (I,OPT) - Array of headers that divide up sections of choices. The index on 
	;                           a given title should match that of the first choice that should be 
	;                           under that header.
	;  overrideFields (I,OPT) - Array of labels (column headers in the TL file) for the data 
	;                           that should get override fields.
	;  minColumnWidth (I,OPT) - Column width will never be smaller than the longest choice, 
	;                           but will also not get smaller than this value. Defaults to 0.
	;  iconPath       (I,OPT) - Path to an icon to show for the popup.
	; RETURNS:        Reference to new SelectorGui object
	;---------
	__New(choices, sectionHeaders := "", overrideFields := "", minColumnWidth := 0, iconPath := "") {
		this.overrideFields := overrideFields
		this.buildPopup(choices, sectionHeaders, minColumnWidth, iconPath)
	}
	
	;---------
	; DESCRIPTION:    Shows the popup, waits for it to be closed, and saves user inputs.
	; PARAMETERS:
	;  windowTitle         (I,REQ) - Title to show for the window.
	;  defaultOverrideData (I,OPT) - Associative array of default data, format:
	;                                 {columnLabel: value}
	;                                NOTE: only values for columns that we're showing fields for
	;                                will respect this value - if there's no field shown for the
	;                                column, this value is ignored and effectively dropped.
	;---------
	show(windowTitle, defaultOverrideData := "") {
		this.setDefaultOverrides(defaultOverrideData)
		this.showPopup(windowTitle)
		; saveUserInputs() is called from submitAndClose() before the gui is destroyed,
		; so control values are read while they still exist.
	}
	
	;---------
	; DESCRIPTION:    Get the user's query, as entered in the bottom-left field.
	; RETURNS:        The user's entered text.
	;---------
	getChoiceQuery() {
		return this.choiceQuery
	}
	;---------
	; DESCRIPTION:    Get the override data from column-specific fields.
	; RETURNS:        Associative array of override data. Format:
	;                  {columnLabel: value}
	; NOTES:          If default override data was passed in, only values that have corresponding
	;                 fields visible will be included here. Put another way, if you passed in values
	;                 for columns which are not visible, those will be ignored and won't appear here.
	;---------
	getOverrideData() {
		return this.overrideData
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ INTERNAL ------------------------------
	;---------
	; DESCRIPTION:    Update the font color of the given control so that it's "ghosted" if it's the initial value, and black otherwise.
	; PARAMETERS:
	;  ctrl      (I,REQ) - The control object to update
	;  fieldName (I,REQ) - The field name (label) for this override field
	;---------
	updateOverrideField(ctrl, fieldName) {
		value := ctrl.Value
		; Debug.popup("fieldName",fieldName, "value",value)

		; Set the font color - ghost if it's the default, black (default color) otherwise
		if(fieldName = value)
			ctrl.SetFont("c" SelectorGui.FontColor_Ghost)
		else
			ctrl.SetFont("-c")
	}
	;endregion ------------------------------ INTERNAL ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	; Special characters
	static Char_NewColumn := "! " ; Space after is required
	
	static FontColor_Default              := "BDAE9D"
	static FontColor_Ghost                := "BDAE9D"

	; GUI spacing/positioning constants
	static Margins :=  Map("LEFT",10, "RIGHT",10, "TOP",10, "BOTTOM",10)
	static Padding :=  Map("INDEX_ABBREV",5, "ABBREV_NAME",10, "OVERRIDE_FIELDS",5, "COLUMNS",30)
	static Widths  :=  Map("INDEX",25, "ABBREV",50) ; Other widths are calculated based on contents and available space
	static Heights :=  Map("LINE",25, "FIELD",24)

	guiObj                   := "" ; Gui object
	guiId                    := "" ; Window handle for the gui (= this.guiObj.Hwnd)
	choiceCtrl               := "" ; Control object for the choice field
	overrideFieldCtrls       := "" ; Map of label => control object for override fields

	overrideFields := "" ; Simple array of the names for the fields to add
	choiceQuery    := "" ; What the user entered in the query (bottom-left) field
	overrideData   := Map() ; {label: inputValue}
	
	; Height and width for the gui as a whole
	totalHeight   := 0
	totalWidth    := 0
	
	; Width of the choices FlexTable, used to calculate field position and widths.
	choicesWidth := 0
	
	;---------
	; DESCRIPTION:    Put together the popup, including margins and all contents.
	; PARAMETERS:
	;  choices        (I,REQ) - The choices to display, as an array of SelectorChoice objects.
	;  sectionHeaders (I,REQ) - Associative array of section headers. Format:
	;                            {firstRowUnderHeader: headerText}
	;  minColumnWidth (I,REQ) - Minimum width (in px) that each column should be.
	;  iconPath       (I,OPT) - Path to an icon to show for the popup.
	;---------
	buildPopup(choices, sectionHeaders, minColumnWidth, iconPath := "") {
		this.totalHeight += this.Margins["TOP"]
		this.totalWidth  += this.Margins["LEFT"]
		
		this.createPopup(iconPath)
		this.addChoices(choices, sectionHeaders, minColumnWidth)
		this.addFields()
		
		this.totalHeight += this.Margins["BOTTOM"]
		this.totalWidth  += this.Margins["RIGHT"]
		; Debug.popup("SelectorGui.buildPopup","Finish", "height",this.totalHeight, "width",this.totalWidth)
	}
	
	;---------
	; DESCRIPTION:    Create the actual popup and apply styles.
	; PARAMETERS:
	;  iconPath (I,OPT) - Path to an icon to show for the popup.
	; SIDE EFFECTS:   Stores off the new gui's window handle and our new unique field ID/prefixes.
	;---------
	createPopup(iconPath := "") {
		; Set the provided icon (if any) before we create the gui - it uses the icon in effect when it's initially created.
		settings := TempSettings().trayIcon(iconPath)

		; Create gui and save off gui object and window handle
		this.guiObj := Gui()
		this.guiId := this.guiObj.Hwnd
		settings.restore() ; Restore original icon now that the gui's created

		; Event handlers (replaces +Label prefix approach)
		this.guiObj.OnEvent("Close", (*) => this.guiObj.Destroy())
		this.guiObj.OnEvent("Escape", (*) => this.guiObj.Destroy())

		; Other gui options
		this.guiObj.Opt("-MinimizeBox -MaximizeBox") ; Hide maximize/minimize icons

		; Initialize override field control map
		this.overrideFieldCtrls := Map()

		this.guiObj.BackColor := "2A211C"
		this.guiObj.SetFont("s12 c" SelectorGui.FontColor_Default)

		; Hidden button for {Enter} submission
		submitBtn := this.guiObj.Add("Button", "Hidden Default")
		submitBtn.OnEvent("Click", (*) => this.submitAndClose())
	}
	
	;---------
	; DESCRIPTION:    Turn our choices array into a FlexTable and add it to the gui.
	; PARAMETERS:
	;  choices        (I,REQ) - The choices to display, as an array of SelectorChoice objects.
	;  sectionHeaders (I,REQ) - Associative array of section headers. Format:
	;                            {firstRowUnderHeader: headerText}
	;  minColumnWidth (I,REQ) - Minimum width (in px) that each column should be.
	;---------
	addChoices(choices, sectionHeaders, minColumnWidth) {
		flex := FlexTable(this.guiObj, this.Margins["LEFT"], this.Margins["TOP"], this.Heights["LINE"], this.Padding["COLUMNS"], minColumnWidth)
		
		isEmptyColumn := true
		For i,choice in choices {
			sectionTitle := (sectionHeaders && sectionHeaders.Has(i)) ? sectionHeaders[i] : ""
			
			; Add new column if needed
			if(sectionTitle.startsWith(this.Char_NewColumn)) {
				sectionTitle := sectionTitle.removeFromStart(this.Char_NewColumn)
				flex.addColumn()
				isEmptyColumn := true
			}
			
			; Add header if needed
			if(sectionTitle) {
				; Extra newline above section titles, unless they're on the first thing in a column (in which case just add the cell).
				if(!isEmptyColumn) {
					flex.addRow()
					flex.addRow()
				}
				
				flex.addHeaderCell(sectionTitle)
				isEmptyColumn := false
			}
			
			; Add choice
			if(!isEmptyColumn)
				flex.addRow() ; Only add a newline if we're not at the top of a new column
			this.addChoiceToTable(flex, i, choice)
			isEmptyColumn := false
		}
		
		; Keep track of the width of the FlexTable for use in field position/width calculation.
		this.choicesWidth := flex.getTotalWidth()
		
		; Add the resulting height/width onto our total gui height/width
		this.totalHeight += flex.getTotalHeight()
		this.totalWidth  += flex.getTotalWidth()
		; Debug.popup("SelectorGui.addChoices","Finish", "height",this.totalHeight, "width",this.totalWidth)
	}
	
	;---------
	; DESCRIPTION:    Add a single choice to the FlexTable.
	; PARAMETERS:
	;  flex   (I,REQ) - The FlexTable to add the choice to.
	;  index  (I,REQ) - The index to show at the left of the choice.
	;  choice (I,REQ) - The choice to pull abbreviation and name from.
	;---------
	addChoiceToTable(flex, index, choice) {
		flex.addCell(index ")",            0,                            this.Widths["INDEX"],  "Right")
		flex.addCell(choice.displayAbbrev, this.Padding["INDEX_ABBREV"], this.Widths["ABBREV"])
		flex.addCell(choice.displayName,   this.Padding["ABBREV_NAME"])
	}
	
	;---------
	; DESCRIPTION:    Add the fields to the bottom of the popup.
	; SIDE EFFECTS:   Updates the total height based on what we added.
	;---------
	addFields() {
		this.totalHeight += this.Heights["LINE"] ; Add an empty line before the fields.
		
		this.addChoiceField()
		if(this.overrideFields)
			this.addOverrideFields()
		
		this.totalHeight += this.Heights["FIELD"]
	}
	
	;---------
	; DESCRIPTION:    Add the choice field (bottom-left, always appears).
	;---------
	addChoiceField() {
		this.guiObj.SetFont("-c") ; Revert the color back to system default (so it can match the edit fields, which use the system default background).

		x := this.Margins["LEFT"] ; Lines up with first column's indices
		y := this.totalHeight
		w := this.calcChoiceFieldWidth()
		this.choiceCtrl := this.addField(x, y, w, this.Heights["FIELD"])
	}
	
	;---------
	; DESCRIPTION:    The choice field spans at least the first column's index + abbreviation, but
	;                 if there are no override fields, it's the full width of the choices FlexTable.
	; RETURNS:        The width that the choice field should be.
	;---------
	calcChoiceFieldWidth() {
		if(this.overrideFields)
			return this.Widths["INDEX"] + this.Padding["INDEX_ABBREV"] + this.Widths["ABBREV"]
		else
			return this.choicesWidth
	}
	
	;---------
	; DESCRIPTION:    Add override fields to the popup - these allow the user to override certain
	;                 data regardless of the choice they pick.
	;---------
	addOverrideFields() {
		this.guiObj.SetFont("c" SelectorGui.FontColor_Ghost) ; Start out gray (default, ghost-texty values) - updateOverrideField will change it dynamically based on contents.

		; Where to start placing override fields - lines up with the first choice column's names.
		xOverridesBlock := this.Margins["LEFT"] + this.Widths["INDEX"] + this.Padding["INDEX_ABBREV"] + this.Widths["ABBREV"] + this.Padding["ABBREV_NAME"]
		; Total width available to the override fields - Fill the rest of the horizontal space under the choices table.
		xChoicesRightEdge := this.Margins["LEFT"] + this.choicesWidth
		wOverridesBlock := xChoicesRightEdge - xOverridesBlock

		x := xOverridesBlock
		y := this.totalHeight
		width := this.calcSingleOverrideFieldWidth(wOverridesBlock)

		For _,label in this.overrideFields {
			ctrl := this.addField(x, y, width, this.Heights["FIELD"], label, label) ; Default in the label, like ghost text, and bind changes to updateOverrideField.
			this.overrideFieldCtrls[label] := ctrl
			x += width + this.Padding["OVERRIDE_FIELDS"]
		}
	}
	
	;---------
	; DESCRIPTION:    Figure out how wide each override field should be, based on the total width
	;                 available/how many of them there are (and taking padding into account).
	; PARAMETERS:
	;  overrideBlockWidth (I,REQ) - The total width available to put override fields in.
	; RETURNS:        The width that each override field should be.
	;---------
	calcSingleOverrideFieldWidth(overrideBlockWidth) {
		numDataFields  := this.overrideFields.Count
		widthForFields := overrideBlockWidth - ((numDataFields - 1) * this.Padding["OVERRIDE_FIELDS"])
		return widthForFields / numDataFields
	}
	
	;---------
	; DESCRIPTION:    Add a single field to the popup with the provided information.
	; PARAMETERS:
	;  x         (I,REQ) - The x coordinate to add the control at.
	;  y         (I,REQ) - The y coordinate to add the control at.
	;  width     (I,REQ) - The field width
	;  height    (I,REQ) - The field height
	;  data      (I,OPT) - The data to pre-populate the field with
	;  fieldName (I,OPT) - The field name (label) for this override field, used for change event binding.
	; RETURNS:        The control object for the new field.
	;---------
	addField(x, y, width, height, data := "", fieldName := "") {
		propString := "x" x " y" y " w" width " h" height               ; Position/size
		propString .= " -E" MicrosoftLib.ExStyle_SunkenBorder " +Border" ; Styling - remove sunken border, add a normal border

		ctrl := this.guiObj.Add("Edit", propString, data)
		if(fieldName)
			ctrl.OnEvent("Change", (ctrl, *) => this.updateOverrideField(ctrl, fieldName))

		return ctrl
	}
	
	;---------
	; DESCRIPTION:    Apply default override data to the override fields.
	; PARAMETERS:
	;  defaultOverrideData (I,OPT) - Associative array of default data, format:
	;                                 {columnLabel: value}
	; NOTES:          Assumes that the desired gui is the default.
	;---------
	setDefaultOverrides(defaultOverrideData) {
		if(!defaultOverrideData)
			return
		For label,value in defaultOverrideData {
			if(value != "" && this.overrideFieldCtrls.Has(label))
				this.overrideFieldCtrls[label].Value := value
		}
	}
	
	;---------
	; DESCRIPTION:    Actually show the finished popup.
	; PARAMETERS:
	;  windowTitle (I,REQ) - The title of the window.
	; SIDE EFFECTS:   Automatically focuses the choice field.
	; NOTES:          Assumes that the desired gui is the default.
	;---------
	showPopup(windowTitle) {
		this.guiObj.Title := windowTitle
		this.guiObj.Show("h" this.totalHeight " w" this.totalWidth)

		; Focus the choice field
		this.choiceCtrl.Focus()

		; Wait for gui to close
		WinWaitClose("ahk_id " this.guiObj.Hwnd)
	}
	
	;---------
	; DESCRIPTION:    Save the user's inputs to member variables for extraction by caller.
	;---------
	saveUserInputs() {
		; Choice field
		this.choiceQuery := this.choiceCtrl.Value

		; Override fields
		For num,label in this.overrideFields {
			if(!this.overrideFieldCtrls.Has(label))
				continue
			inputVal := this.overrideFieldCtrls[label].Value
			if(inputVal && (inputVal != label))
				this.overrideData[label] := inputVal
		}
	}
	;endregion ------------------------------ PRIVATE ------------------------------
	
	;region ------------------------------ DEBUG ------------------------------
	Debug_ToString(&table) {
		table.addLine("Gui ID (handle)",            this.guiId)
		table.addLine("Choice control",             this.choiceCtrl)
		table.addLine("Override field controls",    this.overrideFieldCtrls)
		table.addLine("Override fields",            this.overrideFields)
		table.addLine("Choice query",               this.choiceQuery)
		table.addLine("Override data",              this.overrideData)
		table.addLine("Total height",               this.totalHeight)
		table.addLine("Total width",                this.totalWidth)
		table.addLine("Choices table width",        this.choicesWidth)
	}
	;endregion ------------------------------ DEBUG ------------------------------

	;region ------------------------------ INTERNAL EVENT HANDLERS ------------------------------
	;---------
	; DESCRIPTION:    Submit the gui - save field values before destroying.
	;---------
	submitAndClose() {
		this.saveUserInputs() ; Read control values while they still exist
		this.guiObj.Destroy()
	}
	;endregion ------------------------------ INTERNAL EVENT HANDLERS ------------------------------
}