
; GUI Events
SelectorGuiClose() { ; Called when window is closed
	Gui, Destroy
}
SelectorGuiSubmit() { ; Called when Enter is pressed (which fires the hidden, default button)
	Gui, Submit ; Actually saves edit controls' values to respective GuiIn* variables
	Gui, Destroy
}
SelectorGuiOverrideFieldChanged() {
	fieldName := removeStringFromStart(A_GuiControl, A_Gui SelectorGui.baseFieldVarOverride)
	value := GuiControlGet("", A_GuiControl)
	; DEBUG.popup("A_GuiControl",A_GuiControl, "A_Gui",A_Gui, "fieldName",fieldName, "value",value)
	
	; Set the overall gui font color, then tell the edit control to conform to it.
	if(fieldName = value)
		Gui, Font, % "c" SelectorGui.fieldGhostFontColor
	else
		Gui, Font, -c
	GuiControl, Font, % A_GuiControl
}

class SelectorGui {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	__New(choices, sectionTitles = "", overrideFields = "", minColumnWidth = 0) {
		this.overrideFields := overrideFields
		
		this.setSpecialChars()
		this.setOffsets()
		this.setGuiId("SelectorGui" getNextGuiId())
		this.makeGuiTheDefault()
		
		this.buildPopup(choices, sectionTitles, minColumnWidth)
	}
	
	; Shows the popup, including waiting on it to be closed
	; defaultOverrideData - Array of data label/column => value to put in.
	show(windowTitle = "", defaultOverrideData = "") {
		this.makeGuiTheDefault()
		
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
	
	static baseFieldVarChoice   := "Choice"
	static baseFieldVarOverride := "Override"
	static defaultFontColor     := "BDAE9D"
	static fieldGhostFontColor  := "BDAE9D"
	
	chars                   := []
	guiId                   := ""
	guiHandle               := ""
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
	
	totalHeight := 0
	totalWidth  := 0
	tableHeight := 0
	tableWidth  := 0
	
	
	setSpecialChars() {
		this.chars := []
		this.chars["NEW_COLUMN"] := "|"
	}
	
	setGuiId(id) {
		this.guiId := id
		
		; Names for global variables that we'll use for values of fields. This way they can be declared global and retrieved in the same way, without having to pre-define global variables.
		this.fieldVarChoice          := id SelectorGui.baseFieldVarChoice
		this.fieldVarOverridesPrefix := id SelectorGui.baseFieldVarOverride
	}
	
	; Make sure all of the Gui* commands refer to the right one.
	makeGuiTheDefault() {
		Gui, % this.guiId ":Default"
	}
	
	buildPopup(choices, sectionTitles, minColumnWidth) {
		this.totalHeight := this.margins["TOP"]
		this.totalWidth  := this.margins["LEFT"]
		
		this.createPopup()
		
		this.addChoices(choices, sectionTitles, minColumnWidth)
		this.totalHeight += this.tableHeight
		this.totalWidth  += this.tableWidth
		
		this.totalHeight += this.heights["LINE"] ; Add a line between the table and fields.
		
		this.addFields()
		this.totalHeight += this.heights["FIELD"]
		
		this.totalHeight += this.margins["BOTTOM"]
		this.totalWidth  += this.margins["RIGHT"]
		; DEBUG.popup("SelectorGui.buildPopup","Finish", "height",this.totalHeight, "width",this.totalWidth)
	}
	
	createPopup() {
		Gui, +LastFound +LabelSelectorGui  ; +LabelSelectorGui: Gui* events will call SelectorGui* functions (in particular GuiClose > SelectorGuiClose).
		Gui, Color, 2A211C
		Gui, Font, % "s12 c" SelectorGui.defaultFontColor
		Gui, Add, Button, Hidden Default +gSelectorGuiSubmit ; Hidden button for {Enter} submission.
		this.guiHandle := WinExist() ; Because of +LastFound above, the new gui is the last found window, so WinExist() finds it.
	}
	
	addChoices(choices, sectionTitles, minColumnWidth) {
		flex := new FlexTable(this.guiId, this.margins["LEFT"], this.margins["TOP"], this.heights["LINE"], this.padding["COLUMNS"], minColumnWidth)
		
		isEmptyColumn := true
		For i,choice in choices {
			sectionTitle := sectionTitles[i]
			
			; Add new column if needed
			if(SubStr(sectionTitle, 1, 2) = this.chars["NEW_COLUMN"] " ") {
				sectionTitle := SubStr(sectionTitle, 3) ; Strip the special character and space off so we don't show them.
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
		
		this.tableHeight := flex.getTotalHeight()
		this.tableWidth  := flex.getTotalWidth()
		; DEBUG.popup("SelectorGui.addChoices","Finish", "height",this.totalHeight, "width",this.totalWidth)
	}
	
	addChoiceToTable(flex, index, choice) {
		name := choice.data["NAME"]
		if(IsObject(choice.data["ABBREV"]))
			abbrev := choice.data["ABBREV", 1]
		else
			abbrev := choice.data["ABBREV"]
		
		flex.addCell(index  ")", 0,                            this.widths["INDEX"],  "Right")
		flex.addCell(abbrev ":", this.padding["INDEX_ABBREV"], this.widths["ABBREV"])
		flex.addCell(name,       this.padding["ABBREV_NAME"])
	}
	
	addFields() {
		Gui, Font, -c ; Revert the color back to system default (so it can match the edit fields, which use the system default background).
		this.addChoiceField()
		
		Gui, Font, % "c" SelectorGui.fieldGhostFontColor ; These will be default values (values = labels) by default - SelectorGuiOverrideFieldChanged() will change it dynamically based on contents.
		if(this.overrideFields)
			this.addOverrideFields()
	}
	
	addChoiceField() {
		yField       := this.totalHeight
		xFieldChoice := this.margins["LEFT"] ; Lines up with first column of indices
		
		if(this.overrideFields)
			wFieldChoice := this.widths["INDEX"] + this.padding["INDEX_ABBREV"] + this.widths["ABBREV"] ; Main edit control is same size as index + abbrev columns combined.
		else
			wFieldChoice := this.tableWidth ; Main edit control is the same width as the choices table.
		
		this.addField(this.fieldVarChoice, xFieldChoice, yField, wFieldChoice, this.heights["FIELD"])
	}
	
	addField(varName, x, y, width, height, data = "", subGoto = "") {
		setDynamicGlobalVar(varName) ; Declare the variable named in this.fieldVarChoice as a global
		
		propString := "v" varName                           ; Variable to save to on Gui, Submit
		propString .= " x" x " y" y " w" width " h" height  ; Position/size
		propString .= " -E" WS_EX_CLIENTEDGE " +Border"     ; Styling - no sunken appearance, add a border
		if(subGoto)
			propString .= " g" subGoto
		
		Gui, Add, Edit, % propString, % data
	}
	
	addOverrideFields() {
		yField              := this.totalHeight
		wFieldChoiceBlock   := this.widths["INDEX"] + this.padding["INDEX_ABBREV"] + this.widths["ABBREV"] + this.padding["ABBREV_NAME"]
		wFieldOverrideBlock := this.tableWidth - wFieldChoiceBlock
		wFieldOverride      := this.calcSingleOverrideFieldWidth(wFieldOverrideBlock)
		
		xFieldOverride := this.margins["LEFT"] + wFieldChoiceBlock
		For i,label in this.overrideFields {
			this.addField(this.fieldVarOverridesPrefix label, xFieldOverride, yField, wFieldOverride, this.heights["FIELD"], label, "SelectorGuiOverrideFieldChanged") ; Default in the label, like ghost text. May be replaced by setDefaultOverrides() later.
			xFieldOverride += wFieldOverride + this.padding["OVERRIDE_FIELDS"]
		}
	}
	
	calcSingleOverrideFieldWidth(blockWidth) {
		numDataFields  := this.overrideFields.length()
		widthForFields := blockWidth - ((numDataFields - 1) * this.padding["OVERRIDE_FIELDS"])
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
		WinWaitClose, % "ahk_id " this.guiHandle
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
}
