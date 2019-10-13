/* Class for generating and interacting with a Selector popup.
	
	Usage:
		Create a new SelectorGui instance
		Show popup (.show)
		Get any needed info back (.getChoiceQuery, .getOverrideData)
*/

class SelectorGui {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
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
	; RETURNS:        Reference to new SelectorGui object
	;---------
	__New(choices, sectionHeaders := "", overrideFields := "", minColumnWidth := 0) {
		this.overrideFields := overrideFields
		this.buildPopup(choices, sectionHeaders, minColumnWidth)
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
		Gui, % this.guiId ":Default"
		
		this.setDefaultOverrides(defaultOverrideData)
		this.showPopup(windowTitle)
		
		this.saveUserInputs()
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
	
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	; Special characters
	static Char_NewColumn := "|"
	
	static GuiSpecialLabelsPrefix      := "SelectorGui"
	static baseFieldVarChoice          := "Choice"
	static baseFieldVarOverridesPrefix := "Override"
	static defaultFontColor            := "BDAE9D"
	static fieldGhostFontColor         := "BDAE9D"
	
	guiId                   := "" ; Window handle for the gui
	fieldVarChoice          := "" ; Unique name (starting with this.guiId) for the choice field.
	fieldVarOverridesPrefix := "" ; Unique prefix (starting with this.guiId) for the override fields.
	
	overrideFields := "" ; Simple array of the names for the fields to add
	choiceQuery    := "" ; What the user entered in the query (bottom-left) field
	overrideData   := {} ; {label: inputValue}
	
	; GUI spacing/positioning properties
	margins :=  {LEFT:10, RIGHT:10, TOP:10, BOTTOM:10}
	padding :=  {INDEX_ABBREV:5, ABBREV_NAME:10, OVERRIDE_FIELDS:5, COLUMNS:30}
	widths  :=  {INDEX:25, ABBREV:50} ; Other widths are calculated based on contents and available space
	heights :=  {LINE:25, FIELD:24}
	
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
	;---------
	buildPopup(choices, sectionHeaders, minColumnWidth) {
		this.totalHeight += this.margins["TOP"]
		this.totalWidth  += this.margins["LEFT"]
		
		this.createPopup()
		this.addChoices(choices, sectionHeaders, minColumnWidth)
		this.addFields()
		
		this.totalHeight += this.margins["BOTTOM"]
		this.totalWidth  += this.margins["RIGHT"]
		; DEBUG.popup("SelectorGui.buildPopup","Finish", "height",this.totalHeight, "width",this.totalWidth)
	}
	
	;---------
	; DESCRIPTION:    Create the actual popup and apply styles.
	; SIDE EFFECTS:   Stores off the new gui's window handle and our new unique field ID/prefixes.
	;---------
	createPopup() {
		Gui, New, +HWNDguiId
		this.guiId := guiId ; from +HWND* setting above
		
		; Names for global variables that we'll use for values of fields. This way they can be declared global and retrieved in the same way, without having to pre-define global variables.
		this.fieldVarChoice          := guiId SelectorGui.baseFieldVarChoice
		this.fieldVarOverridesPrefix := guiId SelectorGui.baseFieldVarOverridesPrefix
		
		Gui, % "+LastFound +Label" SelectorGui.GuiSpecialLabelsPrefix  ; +LabelSelectorGui: Gui* events will call SelectorGui* functions (GuiClose > SelectorGuiClose, etc.).
		Gui, Color, 2A211C
		Gui, Font, % "s12 c" SelectorGui.defaultFontColor
		Gui, Add, Button, Hidden Default +gSelectorGuiSubmit ; Hidden button for {Enter} submission.
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
		flex := new FlexTable(this.guiId, this.margins["LEFT"], this.margins["TOP"], this.heights["LINE"], this.padding["COLUMNS"], minColumnWidth)
		
		isEmptyColumn := true
		For i,choice in choices {
			sectionTitle := sectionHeaders[i]
			
			; Add new column if needed
			if(sectionTitle.startsWith(this.Char_NewColumn " ")) {
				sectionTitle := sectionTitle.removeFromStart(this.Char_NewColumn " ")
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
		; DEBUG.popup("SelectorGui.addChoices","Finish", "height",this.totalHeight, "width",this.totalWidth)
	}
	
	;---------
	; DESCRIPTION:    Add a single choice to the FlexTable.
	; PARAMETERS:
	;  flex   (I,REQ) - The FlexTable to add the choice to.
	;  index  (I,REQ) - The index to show at the left of the choice.
	;  choice (I,REQ) - The choice to pull abbreviation and name from.
	;---------
	addChoiceToTable(flex, index, choice) {
		flex.addCell(index         ")", 0,                            this.widths["INDEX"],  "Right")
		flex.addCell(choice.abbrev ":", this.padding["INDEX_ABBREV"], this.widths["ABBREV"])
		flex.addCell(choice.name,       this.padding["ABBREV_NAME"])
	}
	
	;---------
	; DESCRIPTION:    Add the fields to the bottom of the popup.
	; SIDE EFFECTS:   Updates the total height based on what we added.
	;---------
	addFields() {
		this.totalHeight += this.heights["LINE"] ; Add an empty line before the fields.
		
		this.addChoiceField()
		if(this.overrideFields)
			this.addOverrideFields()
		
		this.totalHeight += this.heights["FIELD"]
	}
	
	;---------
	; DESCRIPTION:    Add the choice field (bottom-left, always appears).
	;---------
	addChoiceField() {
		Gui, Font, -c ; Revert the color back to system default (so it can match the edit fields, which use the system default background).
		
		x := this.margins["LEFT"] ; Lines up with first column's indices
		y := this.totalHeight
		w := this.calcChoiceFieldWidth()
		this.addField(this.fieldVarChoice, x, y, w, this.heights["FIELD"])
	}
	
	;---------
	; DESCRIPTION:    The choice field spans at least the first column's index + abbreviation, but
	;                 if there are no override fields, it's the full width of the choices FlexTable.
	; RETURNS:        The width that the choice field should be.
	;---------
	calcChoiceFieldWidth() {
		if(this.overrideFields)
			return this.widths["INDEX"] + this.padding["INDEX_ABBREV"] + this.widths["ABBREV"]
		else
			return this.choicesWidth
	}
	
	;---------
	; DESCRIPTION:    Add override fields to the popup - these allow the user to override certain
	;                 data regardless of the choice they pick.
	;---------
	addOverrideFields() {
		Gui, Font, % "c" SelectorGui.fieldGhostFontColor ; Start out gray (default, ghost-texty values) - SelectorGuiOverrideFieldChanged() will change it dynamically based on contents.
		
		; Where to start placing override fields - lines up with the first choice column's names.
		xOverridesBlock := this.margins["LEFT"] + this.widths["INDEX"] + this.padding["INDEX_ABBREV"] + this.widths["ABBREV"] + this.padding["ABBREV_NAME"]
		; Total width available to the override fields - Fill the rest of the horizontal space under the choices table.
		xChoicesRightEdge := this.margins["LEFT"] + this.choicesWidth
		wOverridesBlock := xChoicesRightEdge - xOverridesBlock
		
		x := xOverridesBlock
		y := this.totalHeight
		width := this.calcSingleOverrideFieldWidth(wOverridesBlock)
		
		For _,label in this.overrideFields {
			varName := this.fieldVarOverridesPrefix label
			this.addField(varName, x, y, width, this.heights["FIELD"], label, SelectorGui.GuiSpecialLabelsPrefix "OverrideFieldChanged") ; Default in the label, like ghost text, and bind any changes to SelectorGuiOverrideFieldChanged().
			x += width + this.padding["OVERRIDE_FIELDS"]
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
		numDataFields  := this.overrideFields.length()
		widthForFields := overrideBlockWidth - ((numDataFields - 1) * this.padding["OVERRIDE_FIELDS"])
		return widthForFields / numDataFields
	}
	
	;---------
	; DESCRIPTION:    Add a single field to the popup with the provided information.
	; PARAMETERS:
	;  varName (I,REQ) - The name of the global variable to link to the field.
	;  x       (I,REQ) - The x coordinate to add the control at.
	;  y       (I,REQ) - The y coordinate to add the control at.
	;  width   (I,REQ) - The field width
	;  height  (I,REQ) - The field height
	;  data    (I,OPT) - The data to pre-populate the field with
	;  subGoto (I,OPT) - The label/function name to bind the field to (that will fire when changes
	;                    are made to the field).
	;---------
	addField(varName, x, y, width, height, data := "", subGoto := "") {
		setDynamicGlobalVar(varName) ; Declare the provided unique variable name as a global
		
		propString := "v" varName                                        ; Variable to save to on Gui, Submit
		propString .= " x" x " y" y " w" width " h" height               ; Position/size
		propString .= " -E" MicrosoftLib.ExStyle_SunkenBorder " +Border" ; Styling - remove sunken border, add a normal border
		if(subGoto)
			propString .= " g" subGoto
		
		Gui, Add, Edit, % propString, % data
	}
	
	;---------
	; DESCRIPTION:    Apply default override data to the override fields.
	; PARAMETERS:
	;  defaultOverrideData (I,OPT) - Associative array of default data, format:
	;                                 {columnLabel: value}
	;---------
	setDefaultOverrides(defaultOverrideData) {
		For label,value in defaultOverrideData {
			if(value != "")
				GuiControl, , % label, % value ; Blank command (first parameter) = replace contents
		}
	}
	
	;---------
	; DESCRIPTION:    Actually show the finished popup.
	; PARAMETERS:
	;  windowTitle (I,REQ) - The title of the window.
	; SIDE EFFECTS:   Automatically focuses the choice field.
	;---------
	showPopup(windowTitle) {
		Gui, Show, % "h" this.totalHeight " w" this.totalWidth, % windowTitle
		
		; Focus the choice field
		GuiControl, Focus, % this.fieldVarChoice
		
		; Wait for gui to close
		WinWaitClose, % "ahk_id " this.guiId
	}
	
	;---------
	; DESCRIPTION:    Save the user's inputs to member variables for extraction by caller.
	;---------
	saveUserInputs() {
		; Choice field
		this.choiceQuery := getDynamicGlobalVar(this.fieldVarChoice) ; Declared via setDynamicGlobalVar(), populated by Gui, Submit
		
		; Override fields
		For num,label in this.overrideFields {
			inputVal := getDynamicGlobalVar(this.fieldVarOverridesPrefix label) ; Declared via setDynamicGlobalVar(), populated by Gui, Submit
			if(inputVal && (inputVal != label))
				this.overrideData[label] := inputVal
		}
	}
	
	
	; Debug info (used by the Debug class)
	debugName := "SelectorGui"
	debugToString(debugBuilder) {
		debugBuilder.addLine("Gui ID (handle)",            this.guiId)
		debugBuilder.addLine("Choice field var",           this.fieldVarChoice)
		debugBuilder.addLine("Override fields var prefix", this.fieldVarOverridesPrefix)
		debugBuilder.addLine("Override fields",            this.overrideFields)
		debugBuilder.addLine("Choice query",               this.choiceQuery)
		debugBuilder.addLine("Override data",              this.overrideData)
		debugBuilder.addLine("Total height",               this.totalHeight)
		debugBuilder.addLine("Total width",                this.totalWidth)
		debugBuilder.addLine("Choices table width",        this.choicesWidth)
	}
}

; GUI Events - these can't live in the class because they're only specified by name (via the +Label option on the gui).

; Window was closed
SelectorGuiClose() {
	Gui, Destroy
}
; Enter was pressed (which fires the hidden, default button)
SelectorGuiSubmit() {
	Gui, Submit ; Actually saves edit controls' values to respective GuiIn* variables
	Gui, Destroy
}
; One of the override fields changed
SelectorGuiOverrideFieldChanged() {
	fieldName := A_GuiControl.removeFromStart(A_Gui SelectorGui.baseFieldVarOverridesPrefix)
	value := GuiControlGet("", A_GuiControl)
	; DEBUG.popup("A_GuiControl",A_GuiControl, "A_Gui",A_Gui, "fieldName",fieldName, "value",value)
	
	; Set the overall gui font color - ghost if it's the default, black (default color) otherwise
	if(fieldName = value)
		Gui, Font, % "c" SelectorGui.fieldGhostFontColor
	else
		Gui, Font, -c
	
	; Tell the edit control to update to match
	GuiControl, Font, % A_GuiControl
}