
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
	
	__New(choices, sectionTitles = "", overrideFields = "", rowsPerColumn = 0, minColumnWidth = 0) {
		this.overrideFields := overrideFields
		
		this.setSpecialChars()
		this.guiId := "Selector" getNextGuiId()
		this.choiceFieldName         := "Choice"   this.guiId
		this.overrideFieldNamePrefix := "Override" this.guiId
		this.setDefaultGui()
		
		this.buildPopup(choices, sectionTitles)
	}
	
	; Shows the popup, including waiting on it to be closed
	show(windowTitle = "", defaultOverrideData = "") {
		this.setDefaultGui()
		
		; GDB TODO put default override data into relevant fields somehow
		For label,value in defaultOverrideData
			GuiControl, , % label, % value ; Blank command means replace contents
		
		; Show gui
		; GDB TODO use windowTitle instead of guiSettings
		; this.showPopup(windowTitle)
		; Resize the GUI to show the newly added edit control row.
		
		Gui, Show, h%heightTotal% w%widthTotal%, % this.guiSettings["WindowTitle"]
		
		; Focus the edit control.
		GuiControl, Focus,     % this.choiceFieldName
		GuiControl, +0x800000, % this.choiceFieldName
		
		; Wait for gui to close
		WinWaitClose, ahk_id %guiHandle%
		
		; Store off data entered by user
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
	
	; Input/output ; GDB TODO organize this section better
	overrideFields := []
	choiceQuery := ""
	overrideData := ""
	
	; Names for global variables that we'll use for values of fields. This way they can be declared global and retrieved in the same way, without having to pre-define global variables.
	; These will have the guiId appended to them in __New().
	choiceFieldName         := ""
	overrideFieldNamePrefix := ""
	
	; GUI spacing properties
	margins  := {LEFT:10, RIGHT:10, TOP:10, BOTTOM:10}
	paddings := {INDEX_ABBREV:5, ABBREV_NAME:10, DATA_FIELDS:5, COLUMNS:30}
	widths   := {INDEX:25, ABBREV:50} ; Other widths are calculated based on contents and available space
	heights  := {LINE:25, FIELD:24}
	
	; GDB TODO stuff that changes/is different
	guiId := ""
	guiHandle := ""
	
	
	
	setSpecialChars() {
		this.chars := []
		this.chars["NEW_COLUMN"] := "|"
	}
	
	setDefaultGui() {
		guiId := this.guiId
		Gui, %guiId%:Default
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
		
		; heightTotal := margins["TOP"] + margins["BOTTOM"] ; GDB TODO Should be class property
	}
	
	addChoices(choices, sectionTitles = "") {
		
		
		; Element starting positions (these get updated per column)
		xTitle       := this.margins["LEFT"]
		xIndex       := this.margins["LEFT"]
		xAbbrev      := xIndex  + this.widths["INDEX"]  + this.paddings["INDEX_ABBREV"]
		xName        := xAbbrev + this.widths["ABBREV"] + this.paddings["ABBREV_NAME"]
		
		yCurrLine     := this.margins["TOP"]
		
		lineNum := 0
		columnNum := 1
		columnWidths := []
		
		
		For i,c in choices {
			lineNum++
			sectionTitle := sectionTitles[i]
			
			if(this.needNewColumn(sectionTitle, lineNum, this.guiSettings["RowsPerColumn"])) {
				if(this.doesTitleForceNewColumn(sectionTitle))
					sectionTitle := SubStr(sectionTitle, 3) ; Strip special character and space off, they've served their purpose.
				
				; Add a new column as needed. ; GDB TODO turn this into a function to add a new column
				columnNum++
				
				xLastColumnOffset := columnWidths[columnNum - 1] + this.paddings["COLUMNS"]
				xTitle  += xLastColumnOffset
				xIndex  += xLastColumnOffset
				xAbbrev += xLastColumnOffset
				xName   += xLastColumnOffset
				
				if(!sectionTitle) { ; We're not starting a new title here, so show the previous one, continued.
					titleInstance++
					sectionTitle := currTitle " (" titleInstance ")"
					isContinuedTitle := true
				}
				
				lineNum := 1
				yCurrLine := this.margins["TOP"]
			}
			
			; Section title row
			if(sectionTitle) {
				if(!isContinuedTitle) {
					titleInstance := 1
					currTitle := sectionTitle
				} else {
					isContinuedTitle := false
				}
				
				; Extra newline above section titles, unless they're on the first line of a column.
				if(lineNum > 1) {
					yCurrLine += this.heights["LINE"]
					lineNum++
				}
				
				applyTitleFormat() ; GDB TODO make an addTitleLine function
				Gui, Add, Text, x%xTitle% y%yCurrLine%, %sectionTitle%
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
			wIndex  := this.widths["INDEX"]
			wAbbrev := this.widths["ABBREV"]
			Gui, Add, Text, x%xIndex%  y%yCurrLine% w%wIndex%   Right, % i ")"
			Gui, Add, Text, x%xAbbrev% y%yCurrLine% w%wAbbrev%,        % abbrev ":"
			Gui, Add, Text, x%xName%   y%yCurrLine%,                   % name
			
			widthName := getLabelWidthForText(name, "name" i)
			colWidthFromChoice := this.widths["INDEX"] + this.paddings["INDEX_ABBREV"] + this.widths["ABBREV"] + this.paddings["ABBREV_NAME"] + widthName
			
			columnWidths[columnNum] := max(columnWidths[columnNum], colWidthFromTitle, colWidthFromChoice, this.guiSettings["MinColumnWidth"])
			
			yCurrLine += this.heights["LINE"]
			maxColumnHeight := max(maxColumnHeight, yCurrLine - this.margins["TOP"])
		}
		
		widthTotal := this.getTotalWidth(columnWidths, this.paddings["COLUMNS"], this.margins["LEFT"], this.margins["RIGHT"])
		
		
		heightTotal += this.margins["TOP"] + maxColumnHeight ; GDB TODO turn into class property
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
	
	
	
	
	
	addFields() {
		xInputChoice := this.margins["LEFT"]
		xInputFirstData := this.margins["LEFT"] + this.widths["INDEX"] + this.paddings["INDEX_ABBREV"] + this.widths["ABBREV"] + this.paddings["ABBREV_NAME"] ; Line this up with the first name column
		
		yInput := maxColumnHeight + this.heights["LINE"] ; Extra empty row before inputs.
		if(this.guiSettings["ShowOverrideFields"])
			widthInputChoice := this.widths["INDEX"] + this.paddings["INDEX_ABBREV"] + this.widths["ABBREV"] ; Main edit control is same size as index + abbrev columns combined.
		else
			widthInputChoice := widthTotal - (this.margins["LEFT"] + this.margins["RIGHT"])   ; Main edit control is nearly full width.
		addInputField(this.choiceFieldName, xInputChoice, yInput, widthInputChoice, this.heights["FIELD"], "")
		
		if(this.guiSettings["ShowOverrideFields"]) {
			numDataInputs := this.overrideFields.length()
			leftoverWidth  := widthTotal - xInputFirstData - this.margins["RIGHT"]
			widthInputData := (leftoverWidth - ((numDataInputs - 1) * this.paddings["DATA_FIELDS"])) / numDataInputs
			
			xInput := xInputFirstData
			For num,label in this.overrideFields {
				if(data[label]) ; Data given as default
					tempData := data[label]
				else            ; Data label (treat like ghost text, filter out later if not modified)
					tempData := label
				
				addInputField(this.overrideFieldNamePrefix num, xInput, yInput, widthInputData, this.heights["FIELD"], tempData) ; GDB TODO make the variable use the label instead of the num, so we can find it better later.
				xInput += widthInputData + this.paddings["DATA_FIELDS"]
			}
		}
		
		
		heightTotal += this.heights["LINE"] + this.heights["FIELD"] + this.margins["BOTTOM"] ; GDB TODO turn into class property
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
	
	
	; Generate the text for the GUI and display it, returning the user's response.
	launchSelectorPopup(data) {
		; Element starting positions (these get updated per column)
		; xTitle       := this.margins["LEFT"]
		; xIndex       := this.margins["LEFT"]
		; xAbbrev      := xIndex  + this.widths["INDEX"]  + this.paddings["INDEX_ABBREV"]
		; xName        := xAbbrev + this.widths["ABBREV"] + this.paddings["ABBREV_NAME"]
		; yCurrLine     := this.margins["TOP"]
		
		; xNameFirstCol := xName
		
		; lineNum := 0
		; columnNum := 1
		; columnWidths := []
		
		
		
		; === Choices ===
		/*
		For i,c in this.choices {
			lineNum++
			sectionTitle := this.sectionTitles[i]
			
			if(this.needNewColumn(sectionTitle, lineNum, this.guiSettings["RowsPerColumn"])) {
				if(this.doesTitleForceNewColumn(sectionTitle))
					sectionTitle := SubStr(sectionTitle, 3) ; Strip special character and space off, they've served their purpose.
				
				; Add a new column as needed. ; GDB TODO turn this into a function to add a new column
				columnNum++
				
				xLastColumnOffset := columnWidths[columnNum - 1] + this.paddings["COLUMNS"]
				xTitle  += xLastColumnOffset
				xIndex  += xLastColumnOffset
				xAbbrev += xLastColumnOffset
				xName   += xLastColumnOffset
				
				if(!sectionTitle) { ; We're not starting a new title here, so show the previous one, continued.
					titleInstance++
					sectionTitle := currTitle " (" titleInstance ")"
					isContinuedTitle := true
				}
				
				lineNum := 1
				yCurrLine := this.margins["TOP"]
			}
			
			; Section title row
			if(sectionTitle) {
				if(!isContinuedTitle) {
					titleInstance := 1
					currTitle := sectionTitle
				} else {
					isContinuedTitle := false
				}
				
				; Extra newline above section titles, unless they're on the first line of a column.
				if(lineNum > 1) {
					yCurrLine += this.heights["LINE"]
					lineNum++
				}
				
				applyTitleFormat() ; GDB TODO make an addTitleLine function
				Gui, Add, Text, x%xTitle% y%yCurrLine%, %sectionTitle%
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
			wIndex  := this.widths["INDEX"]
			wAbbrev := this.widths["ABBREV"]
			Gui, Add, Text, x%xIndex%  y%yCurrLine% w%wIndex%   Right, % i ")"
			Gui, Add, Text, x%xAbbrev% y%yCurrLine% w%wAbbrev%,        % abbrev ":"
			Gui, Add, Text, x%xName%   y%yCurrLine%,                   % name
			
			widthName := getLabelWidthForText(name, "name" i)
			colWidthFromChoice := this.widths["INDEX"] + this.paddings["INDEX_ABBREV"] + this.widths["ABBREV"] + this.paddings["ABBREV_NAME"] + widthName
			
			columnWidths[columnNum] := max(columnWidths[columnNum], colWidthFromTitle, colWidthFromChoice, this.guiSettings["MinColumnWidth"])
			
			yCurrLine += this.heights["LINE"]
			maxColumnHeight := max(maxColumnHeight, yCurrLine)
		}
		
		widthTotal := this.getTotalWidth(columnWidths, this.paddings["COLUMNS"], this.margins["LEFT"], this.margins["RIGHT"])
		*/
		
		; === Fields ===
		/*
		xInputChoice := this.margins["LEFT"]
		xInputFirstData := this.margins["LEFT"] + this.widths["INDEX"] + this.paddings["INDEX_ABBREV"] + this.widths["ABBREV"] + this.paddings["ABBREV_NAME"] ; Line this up with the first name column
		
		yInput := maxColumnHeight + this.heights["LINE"] ; Extra empty row before inputs.
		if(this.guiSettings["ShowOverrideFields"])
			widthInputChoice := this.widths["INDEX"] + this.paddings["INDEX_ABBREV"] + this.widths["ABBREV"] ; Main edit control is same size as index + abbrev columns combined.
		else
			widthInputChoice := widthTotal - (this.margins["LEFT"] + this.margins["RIGHT"])   ; Main edit control is nearly full width.
		addInputField(this.choiceFieldName, xInputChoice, yInput, widthInputChoice, this.heights["FIELD"], "")
		
		if(this.guiSettings["ShowOverrideFields"]) {
			numDataInputs := this.overrideFields.length()
			leftoverWidth  := widthTotal - xInputFirstData - this.margins["RIGHT"]
			widthInputData := (leftoverWidth - ((numDataInputs - 1) * this.paddings["DATA_FIELDS"])) / numDataInputs
			
			xInput := xInputFirstData
			For num,label in this.overrideFields {
				if(data[label]) ; Data given as default
					tempData := data[label]
				else            ; Data label (treat like ghost text, filter out later if not modified)
					tempData := label
				
				addInputField(this.overrideFieldNamePrefix num, xInput, yInput, widthInputData, this.heights["FIELD"], tempData) ; GDB TODO make the variable use the label instead of the num, so we can find it better later.
				xInput += widthInputData + this.paddings["DATA_FIELDS"]
			}
		}
		*/
		
		; ; GDB TODO this below line should takes data from both above functions (choices and fields), and should be a class property that's updated in both accordingly.
		; heightTotal += maxColumnHeight + this.heights["LINE"] + this.heights["FIELD"] + this.margins["BOTTOM"] ; maxColumnHeight includes this.margins["TOP"], this.heights["LINE"] is for extra line between labels and inputs
		
		; === Show GUI and wait ===
		/*
		; Resize the GUI to show the newly added edit control row.
		
		Gui, Show, h%heightTotal% w%widthTotal%, % this.guiSettings["WindowTitle"]
		
		; Focus the edit control.
		GuiControl, Focus,     % this.choiceFieldName
		GuiControl, +0x800000, % this.choiceFieldName
		
		; Wait for the user to submit the GUI.
		WinWaitClose, ahk_id %guiHandle%
		*/
		
		
		; === Get values from fields ===
		/*
		choiceInput := getInputFieldValue(this.choiceFieldName)
		
		; Determine the user's choice (if any) and merge that info into the data array.
		if(choiceInput) ; User put something in the first box, which should come from the choices shown.
			choiceData := this.parseChoice(choiceInput)
			
		if(choiceData) {
			data := mergeArrays(data, choiceData)
			gotDataFromUser := true
		}
		
		; Read override data from any visible fields.
		if(this.guiSettings["ShowOverrideFields"]) {
			For num,label in this.overrideFields {
				inputVal := getInputFieldValue(this.overrideFieldNamePrefix num) ; SelectorOverride* variables are declared via assume-global mode in addInputField(), and populated by Gui, Submit.
				if(inputVal && (inputVal != label)) {
					data[label] := inputVal
					gotDataFromUser := true ; GDB TODO should be able to get rid of this now, hopefully?
				}
			}
		}
		
		if(!gotDataFromUser)
			return ""
		return data
		*/
	}
	
	needNewColumn(sectionTitle, lineNum) {
		; Section title forces a new column
		if(this.doesTitleForceNewColumn(sectionTitle))
			return true
		
		; Otherwise, we're only going to compare to the maximum rows per column (assuming it's >0).
		if(this.rowsPerColumn < 1)
			return false
		
		; Out of space in the column
		if(lineNum > this.rowsPerColumn)
			return true
		
		; Technically have one left, but the current one is a title
		; (which would leave the title by itself at the end of a column)
		if(sectionTitle && ((lineNum + 1) > this.rowsPerColumn))
			return true
		
		return false
	}
	
	doesTitleForceNewColumn(sectionTitle) {
		return (SubStr(sectionTitle, 1, 2) = this.chars["NEW_COLUMN"] " ")
	}
	
	
}
