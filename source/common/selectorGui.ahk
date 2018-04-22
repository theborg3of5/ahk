
; GUI Events
SelectorGuiClose() { ; Called when window is closed
	Gui, Destroy
}
SelectorGuiSubmit() { ; Called when Enter is pressed (which fires the hidden, default button)
	Gui, Submit ; Actually saves edit controls' values to respective GuiIn* variables
	Gui, Destroy
}

class SelectorGui {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	__New(choices, sectionTitles = "", overrideFields = "", minColumnWidth = 0) {
		this.overrideFields := overrideFields
		
		this.setSpecialChars()
		this.setOffsets()
		this.setGuiId("Selector" getNextGuiId())
		this.makeGuiTheDefault()
		
		this.buildPopup(choices, sectionTitles)
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
	
	chars := []
	guiId     := ""
	guiHandle := ""
	choiceFieldName         := ""
	overrideFieldNamePrefix := ""
	
	overrideFields := []
	choiceQuery    := ""
	overrideData   := []
	
	; GUI spacing/positioning properties
	margins :=  {LEFT:10, RIGHT:10, TOP:10, BOTTOM:10}
	padding :=  {INDEX_ABBREV:5, ABBREV_NAME:10, OVERRIDE_FIELDS:5, COLUMNS:30}
	widths  :=  {INDEX:25, ABBREV:50} ; Other widths are calculated based on contents and available space
	heights :=  {LINE:25, FIELD:24}
	
	totalHeight := 0
	totalWidth  := 0
	
	
	setSpecialChars() {
		this.chars := []
		this.chars["NEW_COLUMN"] := "|"
	}
	
	setGuiId(id) {
		this.guiId := id
		
		; Names for global variables that we'll use for values of fields. This way they can be declared global and retrieved in the same way, without having to pre-define global variables.
		this.choiceFieldName         := "Choice"   id
		this.overrideFieldNamePrefix := "Override" id
	}
	
	; Make sure all of the Gui* commands refer to the right one.
	makeGuiTheDefault() {
		Gui, % this.guiId ":Default"
	}
	
	buildPopup(choices, sectionTitles = "") {
		this.totalHeight := 0
		this.totalWidth  := 0
		
		this.createPopup()
		
		this.addChoices(choices, sectionTitles)
		this.addFields()
		
		; Add in margins so we have an accurate popup size.
		this.totalHeight += this.margins["TOP"]  + this.margins["BOTTOM"]
		this.totalWidth  += this.margins["LEFT"] + this.margins["RIGHT"]
		; DEBUG.popup("SelectorGui.buildPopup","Finish", "height",this.totalHeight, "width",this.totalWidth)
	}
	
	createPopup() {
		Gui, +LastFound +LabelSelectorGui  ; +LabelSelectorGui: Gui* events will call SelectorGui* functions (in particular GuiClose > SelectorGuiClose).
		Gui, Color, 2A211C
		Gui, Font, s12 cBDAE9D
		Gui, Add, Button, Hidden Default +gSelectorGuiSubmit ; Hidden button for {Enter} submission.
		this.guiHandle := WinExist() ; Because of +LastFound above, the new gui is the last found window, so WinExist() finds it.
	}
	
	addChoices(choices, sectionTitles = "") {
		flex := new FlexTable(this.guiId, this.margins["LEFT"], this.margins["TOP"], this.heights["LINE"], this.padding["COLUMNS"])
		
		isEmptyColumn := true
		For i,choice in choices {
			sectionTitle := sectionTitles[i]
			
			; Add new column if needed
			if(this.doesTitleForceNewColumn(sectionTitle)) {
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
			name := choice.data["NAME"]
			if(IsObject(choice.data["ABBREV"]))
				abbrev := choice.data["ABBREV", 1]
			else
				abbrev := choice.data["ABBREV"]
			
			if(!isEmptyColumn)
				flex.addRow()
			flex.addCell(i ")",      0,                            this.widths["INDEX"],  "Right")
			flex.addCell(abbrev ":", this.padding["INDEX_ABBREV"], this.widths["ABBREV"])
			flex.addCell(name,       this.padding["ABBREV_NAME"])
			isEmptyColumn := false
		}
		
		this.totalHeight += flex.getTotalHeight()
		this.totalWidth  += flex.getTotalWidth()
		; DEBUG.popup("SelectorGui.addChoices","Finish", "height",this.totalHeight, "width",this.totalWidth)
	}
	
	doesTitleForceNewColumn(sectionTitle) {
		return (SubStr(sectionTitle, 1, 2) = this.chars["NEW_COLUMN"] " ")
	}
	
	addFields() {
		Gui, Font, -c ; Revert the color back to system default (so it can match the edit fields, which use the system default background.
		
		this.addChoiceField()
		if(this.overrideFields)
			this.addOverrideFields()
		
		this.totalHeight += this.heights["LINE"] + this.heights["FIELD"]
		; DEBUG.popup("SelectorGui.addFields","Finish", "height",this.totalHeight, "width",this.totalWidth)
	}
	
	addChoiceField() {
		yField       := this.margins["TOP"] + this.totalHeight + this.heights["LINE"]
		xFieldChoice := this.margins["LEFT"] ; Lines up with first column of indices
		
		if(this.overrideFields)
			wFieldChoice := this.widths["INDEX"] + this.padding["INDEX_ABBREV"] + this.widths["ABBREV"] ; Main edit control is same size as index + abbrev columns combined.
		else
			wFieldChoice := this.totalWidth ; Main edit control is the same width as the choices table (margins haven't been added in yet).
		
		addInputField(this.choiceFieldName, xFieldChoice, yField, wFieldChoice, this.heights["FIELD"])
	}
	
	addOverrideFields() {
		yField              := this.margins["TOP"]  + this.totalHeight     + this.heights["LINE"]
		xFieldOverrideBlock := this.margins["LEFT"] + this.widths["INDEX"] + this.padding["INDEX_ABBREV"] + this.widths["ABBREV"] + this.padding["ABBREV_NAME"] ; Lines up with the first column's names
		leftoverWidth       := this.totalWidth - (xFieldOverrideBlock - this.margins["LEFT"]) ; width of choices table - portion that's already accounted for (choice field + padding)
		wFieldOverride      := this.calcOverrideFieldWidth(leftoverWidth)
		; DEBUG.popup("SelectorGui.addOverrideFields","Total width calculated", "this.totalWidth",this.totalWidth, "xFieldOverrideBlock",xFieldOverrideBlock, "wFieldOverride",wFieldOverride)
		
		xFieldOverride := xFieldOverrideBlock
		For i,label in this.overrideFields {
			addInputField(this.overrideFieldNamePrefix label, xFieldOverride, yField, wFieldOverride, this.heights["FIELD"], label) ; Default in the label, like ghost text. May be replaced by setDefaultOverrides() later.
			xFieldOverride += wFieldOverride + this.padding["OVERRIDE_FIELDS"]
		}
	}
	
	calcOverrideFieldWidth(leftoverWidth) {
		numDataFields  := this.overrideFields.length()
		widthForFields := leftoverWidth - ((numDataFields - 1) * this.padding["OVERRIDE_FIELDS"])
		; DEBUG.popup("SelectorGui.calcOverrideFieldWidth","Done calculating", "numDataFields",numDataFields, "leftoverWidth",leftoverWidth, "widthForFields",widthForFields)
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
		GuiControl, Focus, % this.choiceFieldName
		
		; Wait for gui to close
		WinWaitClose, % "ahk_id " this.guiHandle
	}
	
	
	
	saveUserInputs() {
		; Choice field
		this.choiceQuery := getInputFieldValue(this.choiceFieldName)
		
		; Override fields
		For num,label in this.overrideFields {
			inputVal := getInputFieldValue(this.overrideFieldNamePrefix label) ; SelectorOverride* variables are declared via assume-global mode in addInputField(), and populated by Gui, Submit.
			if(inputVal && (inputVal != label))
				this.overrideData[label] := inputVal
		}
	}
	
	
}
