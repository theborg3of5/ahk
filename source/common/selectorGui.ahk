
; A_Gui for GUI ID? No, don't need - Gui thread (when event leading to one of these happens) starts out with gui window as last found.
; GuiEscape instead of Escape handling in windows.tl? No, need Escape handling for other things (like WinSpy), so may as well get it for free here.
; GUI Events ; GDB TODO see if we can do these better - maybe with functor objects?
; SelectorGuiClose() {
	; Gui, Destroy
; }
; SelectorGuiSubmit() {
	; Gui, Submit ; Actually saves edit controls' values to respective GuiIn* variables
	; Gui, Destroy
; }

class SelectorGui {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	__New(choices, titles = "", dataIndices = "") {
		
		this.guiId := "Selector" getNextGuiId()
		Gui, %guiId%:Default ; GDB TODO move this default line just before doing GUI things (and use this.guiId)
		
		this.dataIndices := dataIndices
		
		this.buildGui(choices, titles) ; GDB TODO: should default data be set in show() instead of being set when we create the controls? If set in show, should it be passed to show() instead of here?
	}
	
	; Shows the popup, including waiting on it to be closed
	show(showOverrideFields = false, defaultOverrideData = "") {
		; GDB TODO put default override data into relevant fields somehow
		For label,value in defaultOverrideData
			GuiControl, , % label, % value ; Blank command means replace contents
		
		; Show gui
		
		; Wait for gui to close
		
		; Store off data entered by user ; GDB TODO
		; this.choiceQuery := ""
		; this.overrideData := []
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
	
	guiId := ""
	dataIndices := []
	choiceQuery  := ""
	overrideData := ""
	
	buildGui(choices, titles = "") {
		; GDB TODO: Create popup
		; GDB TODO: Add choices
		; GDB TODO: Add fields (choice + overrides)
	}
	
	
	
	; Generate the text for the GUI and display it, returning the user's response.
	launchSelectorPopup(data) {
		static GuiInChoice
		GuiInChoice := "" ; Clear this to prevent bleed-over from previous uses. Must be on a separate line from the static declaration or it only happens once.
		
		; Create and begin styling the GUI.
		guiHandle := this.createSelectorGui()
		
		; GUI sizes
		marginLeft   := 10
		marginRight  := 10
		marginTop    := 10
		marginBottom := 10
		
		padIndexAbbrev := 5
		padAbbrevName  := 10
		padInputData   := 5
		padColumn      := 5
		
		widthIndex  := 25
		widthAbbrev := 50
		; (widthName and widthInputChoice/widthInputData exist but are calculated)
		
		heightLine  := 25
		heightInput := 24
	
		; Element starting positions (these get updated per column)
		xTitle       := marginLeft
		xIndex       := marginLeft
		xAbbrev      := xIndex  + widthIndex  + padIndexAbbrev
		xName        := xAbbrev + widthAbbrev + padAbbrevName
		xInputChoice := marginLeft
		
		xNameFirstCol := xName
		yCurrLine     := marginTop
		
		lineNum := 0
		columnNum := 1
		columnWidths := []
		
		For i,c in this.choices {
			lineNum++
			title := this.nonChoices[i]
			
			; Add a new column as needed.
			if(this.needNewColumn(title, lineNum, this.guiSettings["RowsPerColumn"])) {
				columnNum++
				
				xLastColumnOffset := columnWidths[columnNum - 1] + padColumn
				xTitle  += xLastColumnOffset
				xIndex  += xLastColumnOffset
				xAbbrev += xLastColumnOffset
				xName   += xLastColumnOffset
				
				if(!title) { ; We're not starting a new title here, so show the previous one, continued.
					titleInstance++
					title := currTitle " (" titleInstance ")"
					isContinuedTitle := true
				}
				
				lineNum := 1
				yCurrLine := marginTop
			}
			
			; Title rows.
			if(title) {
				if(!isContinuedTitle) {
					titleInstance := 1
					currTitle := title
				} else {
					isContinuedTitle := false
				}
				
				; Extra newline above titles, unless they're on the first line of a column.
				if(lineNum > 1) {
					yCurrLine += heightLine
					lineNum++
				}
				
				applyTitleFormat()
				Gui, Add, Text, x%xTitle% y%yCurrLine%, %title%
				colWidthFromTitle := getLabelWidthForText(title, "title" i) ; This must happen before we revert formatting, so that current styling (mainly bolding) is taken into account.
				clearTitleFormat()
				
				yCurrLine += heightLine
				lineNum++
			}
			
			name := c.data["NAME"]
			if(IsObject(c.data["ABBREV"]))
				abbrev := c.data["ABBREV", 1]
			else
				abbrev := c.data["ABBREV"]
			
			Gui, Add, Text, x%xIndex%  y%yCurrLine% w%widthIndex%   Right, % i ")"
			Gui, Add, Text, x%xAbbrev% y%yCurrLine% w%widthAbbrev%,        % abbrev ":"
			Gui, Add, Text, x%xName%   y%yCurrLine%,                       % name
			
			widthName := getLabelWidthForText(name, "name" i)
			colWidthFromChoice := widthIndex + padIndexAbbrev + widthAbbrev + padAbbrevName + widthName
			
			columnWidths[columnNum] := max(columnWidths[columnNum], colWidthFromTitle, colWidthFromChoice, this.guiSettings["MinColumnWidth"])
			
			yCurrLine += heightLine
			maxColumnHeight := max(maxColumnHeight, yCurrLine)
		}
		
		widthTotal := this.getTotalWidth(columnWidths, padColumn, marginLeft, marginRight)
		yInput := maxColumnHeight + heightLine ; Extra empty row before inputs.
		if(this.guiSettings["ShowOverrideFields"])
			widthInputChoice := widthIndex + padIndexAbbrev + widthAbbrev ; Main edit control is same size as index + abbrev columns combined.
		else
			widthInputChoice := widthTotal - (marginLeft + marginRight)   ; Main edit control is nearly full width.
		Gui, Add, Edit, vGuiInChoice x%xInputChoice% y%yInput% w%widthInputChoice% h%heightInput% -E%WS_EX_CLIENTEDGE% +Border
		
		if(this.guiSettings["ShowOverrideFields"]) {
			numDataInputs := this.dataIndices.length()
			leftoverWidth  := widthTotal - xNameFirstCol - marginRight
			widthInputData := (leftoverWidth - ((numDataInputs - 1) * padInputData)) / numDataInputs
			
			xInput := xNameFirstCol
			For num,label in this.dataIndices {
				if(data[label]) ; Data given as default
					tempData := data[label]
				else            ; Data label (treat like ghost text, filter out later if not modified)
					tempData := label
				
				addInputField("GuiIn" num, xInput, yInput, widthInputData, heightInput, tempData) ; GDB TODO make the variable use the label instead of the num, so we can find it better later.
				xInput += widthInputData + padInputData
			}
		}
		
		; Resize the GUI to show the newly added edit control row.
		heightTotal += maxColumnHeight + heightLine + heightInput + marginBottom ; maxColumnHeight includes marginTop, heightLine is for extra line between labels and inputs
		Gui, Show, h%heightTotal% w%widthTotal%, % this.guiSettings["WindowTitle"]
		
		; Focus the edit control.
		GuiControl, Focus,     GuiInChoice
		GuiControl, +0x800000, GuiInChoice
		
		; Wait for the user to submit the GUI.
		WinWaitClose, ahk_id %guiHandle%
		
		; Determine the user's choice (if any) and merge that info into the data array.
		if(GuiInChoice) ; User put something in the first box, which should come from the choices shown.
			choiceData := this.parseChoice(GuiInChoice)
			
		if(choiceData) {
			data := mergeArrays(data, choiceData)
			gotDataFromUser := true
		}
		
		; Read override data from any visible fields.
		if(this.guiSettings["ShowOverrideFields"]) {
			For num,label in this.dataIndices {
				inputVal := GuiIn%num% ; GuiIn* variables are declared via assume-global mode in addInputField(), and populated by Gui, Submit. ; GDB TODO reference using label, not num
				if(inputVal && (inputVal != label)) {
					data[label] := inputVal
					gotDataFromUser := true
				}
			}
		}
		
		if(!gotDataFromUser)
			return ""
		return data
	}
	
	createSelectorGui() {
		Gui, +LastFound +LabelSelectorGui  ; +LabelSelectorGui: Gui* events will call SelectorGui* functions (in particular GuiClose > SelectorGuiClose).
		Gui, Color, 2A211C
		Gui, Font, s12 cBDAE9D ; GDB TODO: add font and color as optional parameters or properties?
		Gui, Add, Button, Hidden Default +gSelectorGuiSubmit ; Hidden button for {Enter} submission.
		return WinExist() ; Because of +LastFound above, the new gui is the last found window, so WinExist() finds it.
	}
	
	needNewColumn(ByRef sectionTitle, lineNum, rowsPerColumn) {
		; Special character in sectionTitle forces a new column
		if(SubStr(sectionTitle, 1, 2) = this.chars["NEW_COLUMN"] " ") {
			sectionTitle := SubStr(sectionTitle, 3) ; Strip special character and space off, they've served their purpose.
			return true
		}
		
		; Out of space in the column
		if(lineNum > rowsPerColumn)
			return true
		
		; Technically have one left, but the current one is a title
		; (which would leave the title by itself at the end of a column)
		if(sectionTitle && ((lineNum + 1) > rowsPerColumn))
			return true
		
		return false
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
	
	
}
