
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
	
	totalHeight   := 0
	totalWidth    := 0
	choicesHeight := 0
	choicesWidth  := 0
	
	
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
		
		this.choicesHeight := flex.getTotalHeight()
		this.choicesWidth  := flex.getTotalWidth()
		this.totalHeight   += this.choicesHeight
		this.totalWidth    += this.choicesWidth
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
	
	addField(varName, x, y, w, height, data = "", subGoto = "") {
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
