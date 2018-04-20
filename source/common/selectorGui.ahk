
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
	
	; Input/output ; GDB TODO organize properties better
	overrideFields := []
	choiceQuery := ""
	overrideData := ""
	choiceFieldName := ""
	overrideFieldNamePrefix := ""
	
	; GUI spacing/positioning properties
	margins :=  {LEFT:10, RIGHT:10, TOP:10, BOTTOM:10}
	padding :=  {INDEX_ABBREV:5, ABBREV_NAME:10, DATA_FIELDS:5, COLUMNS:30}
	widths  :=  {INDEX:25, ABBREV:50} ; Other widths are calculated based on contents and available space
	heights :=  {LINE:25, FIELD:24}
	xOffsets := {} ; Populated by setOffsets()
	
	
	currColumnX := 0
	currLineY := 0
	currColumnNum := 0
	
	columnWidths := []
	
	; GDB TODO stuff that changes/is different
	guiId := ""
	guiHandle := ""
	
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
	
	setOffsets() {
		this.xOffsets["TITLE"]  := this.margins["LEFT"]
		this.xOffsets["INDEX"]  := this.margins["LEFT"]
		this.xOffsets["ABBREV"] := this.xOffsets["INDEX"]  + this.widths["INDEX"]  + this.padding["INDEX_ABBREV"]
		this.xOffsets["NAME"]   := this.xOffsets["ABBREV"] + this.widths["ABBREV"] + this.padding["ABBREV_NAME"]
	}
	
	; Make sure all of the Gui* commands refer to the right one.
	makeGuiTheDefault() {
		Gui, % this.guiId ":Default" ; GDB TODO test to make sure this works (vs: Gui, %guiId%:Default).
	}
	
	buildPopup(choices, sectionTitles = "") {
		this.createPopup()
		this.addChoices(choices, sectionTitles)
		this.addFields()
	}
	
	createPopup() {
		Gui, +LastFound +LabelSelectorGui  ; +LabelSelectorGui: Gui* events will call SelectorGui* functions (in particular GuiClose > SelectorGuiClose).
		Gui, Color, 2A211C
		Gui, Font, s12 cBDAE9D
		Gui, Add, Button, Hidden Default +gSelectorGuiSubmit ; Hidden button for {Enter} submission.
		this.guiHandle := WinExist() ; Because of +LastFound above, the new gui is the last found window, so WinExist() finds it.
		
		this.totalHeight := margins["TOP"]  + margins["BOTTOM"]
		this.totalWidth  := margins["LEFT"] + margins["RIGHT"]
	}
	
	addChoices(choices, sectionTitles = "") {
		
		; xOffsets["TITLE"]  
		; xOffsets["INDEX"]  
		; xOffsets["ABBREV"] 
		; xOffsets["NAME"]   
		
		this.currColumnX   := this.margins["LEFT"]
		this.currLineY     := this.margins["TOP"]
		this.currColumnNum := 1
		
		lineNum := 0 ; GDB TODO should these be properties too?
		
		For i,choice in choices {
			
			; Start new column if needed
			;  - Increment columnNum
			;  - Update current column x (using this.columnWidths for previous + padding)
			;  - Reset line number to 1
			;  - Reset line Y
			
			; Add section title row if needed
			;  - 
			;  - 
			;  - 
			
			; Add choice row
			;  - 
			;  - 
			;  - 
			
			; Update:
			;  - Max width within current column
			;  - Max height across all columns
			;  - Current line y (increment)
			
		}
		
		
		
		
		
		
		; Element starting positions (these get updated per column)
		; xTitle       := this.margins["LEFT"]
		; xIndex       := this.margins["LEFT"]
		; xAbbrev      := xIndex  + this.widths["INDEX"]  + this.padding["INDEX_ABBREV"]
		; xName        := xAbbrev + this.widths["ABBREV"] + this.padding["ABBREV_NAME"]
		
		; yCurrLine     := this.margins["TOP"]
		
		; lineNum := 0
		; columnNum := 1
		; columnWidths := []
		
		
		For i,c in choices {
			lineNum++
			sectionTitle := sectionTitles[i]
			
			if(this.doesTitleForceNewColumn(sectionTitle)) {
				sectionTitle := SubStr(sectionTitle, 3) ; Strip the special character and space off so we don't show them.
				
				; Add a new column. ; GDB TODO turn this into a function to add a new column
				columnNum++
				
				xLastColumnOffset := columnWidths[columnNum - 1] + this.padding["COLUMNS"] ; GDB TODO column start (x value) should be a property.
				xTitle  += xLastColumnOffset
				xIndex  += xLastColumnOffset
				xAbbrev += xLastColumnOffset
				xName   += xLastColumnOffset
				
				lineNum := 1
				yCurrLine := this.margins["TOP"]
			}
			
			; Section title row
			if(sectionTitle) {
				; Extra newline above section titles, unless they're on the first line of a column.
				if(lineNum > 1) {
					yCurrLine += this.heights["LINE"]
					lineNum++
				}
				
				applyTitleFormat() ; GDB TODO make an addTitleLine function
				Gui, Add, Text, % "x" xTitle " y" yCurrLine, %sectionTitle%
				colWidthFromTitle := getLabelWidthForText(sectionTitle, "title" i) ; This must happen before we revert formatting, so that current styling (mainly bolding) is taken into account. ; GDB TODO move this in with other width-calculating stuff, just wrap it in apply/clearTitleFormat() calls.
				clearTitleFormat()
				
				yCurrLine += this.heights["LINE"]
				lineNum++
			}
			
			name := c.data["NAME"]
			if(IsObject(c.data["ABBREV"]))
				abbrev := c.data["ABBREV", 1]
			else
				abbrev := c.data["ABBREV"]
			
			; GDB TODO add an addChoiceLine function (include/deal with needed surrounding logic too)
			; addChoiceLine(index, abbrev, name, y) ; Overall X should come from current column X (which should be a property)
			Gui, Add, Text, % "x" xIndex  " y" yCurrLine " w" this.widths["INDEX"]  " Right", % i ")"
			Gui, Add, Text, % "x" xAbbrev " y" yCurrLine " w" this.widths["ABBREV"]         , % abbrev ":"
			Gui, Add, Text, % "x" xName   " y" yCurrLine                                    , % name
			
			colWidthFromChoice := this.widths["INDEX"] + this.padding["INDEX_ABBREV"] + this.widths["ABBREV"] + this.padding["ABBREV_NAME"] + getLabelWidthForText(name, "name" i)
			columnWidths[columnNum] := max(columnWidths[columnNum], colWidthFromTitle, colWidthFromChoice, this.guiSettings["MinColumnWidth"])
			
			yCurrLine += this.heights["LINE"]
			maxColumnHeight := max(maxColumnHeight, yCurrLine - this.margins["TOP"])
		}
		
		Loop, % columnWidths.MaxIndex() {
			if(A_Index > 1)
				this.totalWidth += this.padding["COLUMNS"]
			this.totalWidth += columnWidths[A_Index]
		}
		
		
		
		heightTotal += this.margins["TOP"] + maxColumnHeight ; GDB TODO turn into class property
	}
	
	doesTitleForceNewColumn(sectionTitle) {
		return (SubStr(sectionTitle, 1, 2) = this.chars["NEW_COLUMN"] " ")
	}
	
	
	
	
	
	
	addFields() {
		xInputChoice := this.margins["LEFT"]
		xInputFirstData := this.margins["LEFT"] + this.widths["INDEX"] + this.padding["INDEX_ABBREV"] + this.widths["ABBREV"] + this.padding["ABBREV_NAME"] ; Line this up with the first name column
		
		yInput := maxColumnHeight + this.heights["LINE"] ; Extra empty row before inputs.
		if(this.guiSettings["ShowOverrideFields"])
			widthInputChoice := this.widths["INDEX"] + this.padding["INDEX_ABBREV"] + this.widths["ABBREV"] ; Main edit control is same size as index + abbrev columns combined.
		else
			widthInputChoice := widthTotal - (this.margins["LEFT"] + this.margins["RIGHT"])   ; Main edit control is nearly full width.
		addInputField(this.choiceFieldName, xInputChoice, yInput, widthInputChoice, this.heights["FIELD"], "")
		
		if(this.guiSettings["ShowOverrideFields"]) {
			numDataInputs := this.overrideFields.length()
			leftoverWidth  := widthTotal - xInputFirstData - this.margins["RIGHT"]
			widthInputData := (leftoverWidth - ((numDataInputs - 1) * this.padding["DATA_FIELDS"])) / numDataInputs
			
			xInput := xInputFirstData
			For num,label in this.overrideFields {
				if(data[label]) ; Data given as default
					tempData := data[label]
				else            ; Data label (treat like ghost text, filter out later if not modified)
					tempData := label
				
				addInputField(this.overrideFieldNamePrefix num, xInput, yInput, widthInputData, this.heights["FIELD"], tempData) ; GDB TODO make the variable use the label instead of the num, so we can find it better later.
				xInput += widthInputData + this.padding["DATA_FIELDS"]
			}
		}
		
		
		heightTotal += this.heights["LINE"] + this.heights["FIELD"] + this.margins["BOTTOM"] ; GDB TODO turn into class property
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
			inputVal := getInputFieldValue(this.overrideFieldNamePrefix num) ; SelectorOverride* variables are declared via assume-global mode in addInputField(), and populated by Gui, Submit.
			if(inputVal && (inputVal != label))
				this.overrideData[label] := inputVal
		}
	}
	
	
}
