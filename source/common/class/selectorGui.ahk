/* Class for generating and interacting with a Selector popup.
	
	Usage:
		Create a new SelectorGui instance
		Show popup (.show)
		Get any needed info back (.getChoiceQuery, .getOverrideData)
*/

class SelectorGui {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	;---------
	; DESCRIPTION:    Create a new SelectorGui instance.
	; PARAMETERS:
	;  choices        (I,REQ) - Array of SelectorChoice objects containing the information we need 
	;                           (name and abbreviation) to show a list of choices to the user.
	;  sectionTitles  (I,OPT) - Array of titles that divide up sections of choices. The index on 
	;                           a given title should match that of the first choice that should be 
	;                           under that header.
	;  overrideFields (I,OPT) - Array of labels (column headers in the TL file) for the data 
	;                           that should get override fields.
	;  minColumnWidth (I,OPT) - Column width will never be smaller than the longest choice, 
	;                           but will also not get smaller than this value. Defaults to 0.
	; RETURNS:        Reference to new SelectorGui object
	;---------
	__New(choices, sectionTitles := "", overrideFields := "", minColumnWidth := 0) {
		this.setSpecialChars()
		this.overrideFields := overrideFields
		this.buildPopup(choices, sectionTitles, minColumnWidth)
	}
	
	; Shows the popup, including waiting on it to be closed
	; defaultOverrideData - Array of data label/column => value to put in.
	show(windowTitle := "", defaultOverrideData := "") {
		Gui, % this.guiId ":Default"
		
		this.setDefaultOverrides(defaultOverrideData)
		this.showPopup(windowTitle)
		
		this.saveUserInputs()
	}
	
	; Getters for information entered by the user.
	getChoiceQuery() {
		return this.choiceQuery
	}
	getOverrideData() {
		return this.overrideData
	}
	
	; ==============================
	; == Private ===================
	; ==============================
	
	static baseFieldVarChoice          := "Choice"
	static baseFieldVarOverridesPrefix := "Override"
	static defaultFontColor            := "BDAE9D"
	static fieldGhostFontColor         := "BDAE9D"
	
	chars                   := []
	guiId                   := ""
	fieldVarChoice          := ""
	fieldVarOverridesPrefix := ""
	
	overrideFields := ""
	choiceQuery    := ""
	overrideData   := []
	
	; GUI spacing/positioning properties
	margins :=  {LEFT:10, RIGHT:10, TOP:10, BOTTOM:10}
	padding :=  {INDEX_ABBREV:5, ABBREV_NAME:10, OVERRIDE_FIELDS:5, COLUMNS:30}
	widths  :=  {INDEX:25, ABBREV:50} ; Other widths are calculated based on contents and available space
	heights :=  {LINE:25, FIELD:24}
	
	totalHeight   := 0
	totalWidth    := 0
	choicesHeight := 0
	choicesWidth  := 0
	
	
	setSpecialChars() {
		this.chars := []
		this.chars["NEW_COLUMN"] := "|"
	}
	
	buildPopup(choices, sectionTitles, minColumnWidth) {
		this.totalHeight += this.margins["TOP"]
		this.totalWidth  += this.margins["LEFT"]
		
		this.createPopup()
		this.addChoices(choices, sectionTitles, minColumnWidth)
		this.addFields()
		
		this.totalHeight += this.margins["BOTTOM"]
		this.totalWidth  += this.margins["RIGHT"]
		; DEBUG.popup("SelectorGui.buildPopup","Finish", "height",this.totalHeight, "width",this.totalWidth)
	}
	
	createPopup() {
		Gui, New, +HWNDguiId
		this.guiId := guiId ; from +HWND* setting above
		
		; Names for global variables that we'll use for values of fields. This way they can be declared global and retrieved in the same way, without having to pre-define global variables.
		this.fieldVarChoice          := guiId SelectorGui.baseFieldVarChoice
		this.fieldVarOverridesPrefix := guiId SelectorGui.baseFieldVarOverridesPrefix
		
		Gui, +LastFound +LabelSelectorGui  ; +LabelSelectorGui: Gui* events will call SelectorGui* functions (in particular GuiClose > SelectorGuiClose).
		Gui, Color, 2A211C
		Gui, Font, % "s12 c" SelectorGui.defaultFontColor
		Gui, Add, Button, Hidden Default +gSelectorGuiSubmit ; Hidden button for {Enter} submission.
	}
	
	addChoices(choices, sectionTitles, minColumnWidth) {
		flex := new FlexTable(this.guiId, this.margins["LEFT"], this.margins["TOP"], this.heights["LINE"], this.padding["COLUMNS"], minColumnWidth)
		
		isEmptyColumn := true
		For i,choice in choices {
			sectionTitle := sectionTitles[i]
			
			; Add new column if needed
			if(stringStartsWith(sectionTitle, this.chars["NEW_COLUMN"] " ")) {
				sectionTitle := removeStringFromStart(sectionTitle, this.chars["NEW_COLUMN"] " ")
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
				flex.addRow()
			this.addChoiceToTable(flex, i, choice)
			isEmptyColumn := false
		}
		
		this.choicesHeight := flex.getTotalHeight()
		this.choicesWidth  := flex.getTotalWidth()
		this.totalHeight   += this.choicesHeight
		this.totalWidth    += this.choicesWidth
		; DEBUG.popup("SelectorGui.addChoices","Finish", "height",this.totalHeight, "width",this.totalWidth)
	}
	
	addChoiceToTable(flex, index, choice) {
		flex.addCell(index         ")", 0,                            this.widths["INDEX"],  "Right")
		flex.addCell(choice.abbrev ":", this.padding["INDEX_ABBREV"], this.widths["ABBREV"])
		flex.addCell(choice.name,       this.padding["ABBREV_NAME"])
	}
	
	addFields() {
		this.totalHeight += this.heights["LINE"] ; Add an empty line before the fields.
		
		this.addChoiceField()
		if(this.overrideFields)
			this.addOverrideFields()
		
		this.totalHeight += this.heights["FIELD"]
	}
	
	addChoiceField() {
		Gui, Font, -c ; Revert the color back to system default (so it can match the edit fields, which use the system default background).
		
		x := this.margins["LEFT"] ; Lines up with first column's indices
		y := this.totalHeight
		w := this.calcChoiceFieldWidth()
		this.addField(this.fieldVarChoice, x, y, w, this.heights["FIELD"])
	}
	
	; Choice edit control spans the first column's index and abbrev if there are override fields, otherwise it matches the total choices table width.
	calcChoiceFieldWidth() {
		if(this.overrideFields)
			return this.widths["INDEX"] + this.padding["INDEX_ABBREV"] + this.widths["ABBREV"]
		else
			return this.choicesWidth
	}
	
	addField(varName, x, y, w, height, data := "", subGoto := "") {
		setDynamicGlobalVar(varName) ; Declare the variable named in this.fieldVarChoice as a global
		
		propString := "v" varName                           ; Variable to save to on Gui, Submit
		propString .= " x" x " y" y " w" w " h" height  ; Position/size
		propString .= " -E" WS_EX_CLIENTEDGE " +Border"     ; Styling - no sunken appearance, add a border
		if(subGoto)
			propString .= " g" subGoto
		
		Gui, Add, Edit, % propString, % data
	}
	
	addOverrideFields() {
		Gui, Font, % "c" SelectorGui.fieldGhostFontColor ; Start out gray (default, ghost-texty values) - SelectorGuiOverrideFieldChanged() will change it dynamically based on contents.
		
		xOverridesBlock := this.margins["LEFT"] + this.widths["INDEX"] + this.padding["INDEX_ABBREV"] + this.widths["ABBREV"] + this.padding["ABBREV_NAME"] ; Lines up with first column's names
		wOverridesBlock := this.choicesWidth - (xOverridesBlock - this.margins["LEFT"]) ; Fill the rest of the horizontal space under the choices table with the override fields.
		
		x := xOverridesBlock
		y := this.totalHeight
		w := this.calcSingleOverrideFieldWidth(wOverridesBlock)
		
		For i,label in this.overrideFields {
			varName := this.fieldVarOverridesPrefix label
			this.addField(varName, x, y, w, this.heights["FIELD"], label, "SelectorGuiOverrideFieldChanged") ; Default in the label, like ghost text. May be replaced by setDefaultOverrides() later.
			x += w + this.padding["OVERRIDE_FIELDS"]
		}
	}
	
	calcSingleOverrideFieldWidth(overrideBlockWidth) {
		numDataFields  := this.overrideFields.length()
		widthForFields := overrideBlockWidth - ((numDataFields - 1) * this.padding["OVERRIDE_FIELDS"])
		return widthForFields / numDataFields
	}
	
	setDefaultOverrides(defaultOverrideData) {
		For label,value in defaultOverrideData {
			if(value != "")
				GuiControl, , % label, % value ; Blank command (first parameter) = replace contents
		}
	}
	
	showPopup(windowTitle) {
		Gui, Show, % "h" this.totalHeight " w" this.totalWidth, % windowTitle
		
		; Focus the choice field
		GuiControl, Focus, % this.fieldVarChoice
		
		; Wait for gui to close
		WinWaitClose, % "ahk_id " this.guiId
	}
	
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
		debugBuilder.addLine("Chars",                      this.chars)
		debugBuilder.addLine("Gui ID (handle)",            this.guiId)
		debugBuilder.addLine("Choice field var",           this.fieldVarChoice)
		debugBuilder.addLine("Override fields var prefix", this.fieldVarOverridesPrefix)
		debugBuilder.addLine("Override fields",            this.overrideFields)
		debugBuilder.addLine("Choice query",               this.choiceQuery)
		debugBuilder.addLine("Override data",              this.overrideData)
		debugBuilder.addLine("Total height",               this.totalHeight)
		debugBuilder.addLine("Total width",                this.totalWidth)
		debugBuilder.addLine("Choices table height",       this.choicesHeight)
		debugBuilder.addLine("Choices table width",        this.choicesWidth)
	}
}

; GUI Events

; Called when window is closed
SelectorGuiClose() {
	Gui, Destroy
}

; Called when Enter is pressed (which fires the hidden, default button)
SelectorGuiSubmit() {
	Gui, Submit ; Actually saves edit controls' values to respective GuiIn* variables
	Gui, Destroy
}

; Called when an override field is changed, changes font color based on whether it was the "default" value (matches label)
SelectorGuiOverrideFieldChanged() {
	fieldName := removeStringFromStart(A_GuiControl, A_Gui SelectorGui.baseFieldVarOverridesPrefix)
	value := GuiControlGet("", A_GuiControl)
	; DEBUG.popup("A_GuiControl",A_GuiControl, "A_Gui",A_Gui, "fieldName",fieldName, "value",value)
	
	; Set the overall gui font color, then tell the edit control to conform to it.
	if(fieldName = value)
		Gui, Font, % "c" SelectorGui.fieldGhostFontColor
	else
		Gui, Font, -c
	GuiControl, Font, % A_GuiControl
}