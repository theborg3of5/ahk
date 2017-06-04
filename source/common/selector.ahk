/* Generic, flexible custom class for selecting from multiple choices, adding arbitrary input, and performing an action.
	
	This class will read in a file (using the TableList class) and turn it into a group of choices, which is then displayed to the user in a graphical list. The programmatic entry point is Selector.select().
	
	Certain characters have special meaning when parsing the lines of a file. They include:
		= - Title
			This character starts a line that will be the title shown on the popup UI as a whole.
		
		# - Label
			This character starts a line that will be shown as a section label in the UI (to group individual choices).
		
		| - Abbreviation delimiter
			You can give an individual choice multiple abbreviations that will work for the user, separated by this character. Only the first one will be displayed, however.
		
		* - Hidden
			Putting this character at the start of a line will hide that choice from the UI, but still allow it to be selected via its abbreviation.
		
		( - Model
			You can have more than the simple layout of NAME-ABBREV-ACTION by using a model row that begins with this character. This line is tab-separated in the same way as the choices, with each entry being the name for the corresponding column of each choice.
		
		) - Model Index
			This row corresponds to the model row, giving each of the named columns an index, which is the order in which the additional arbitrary fields in the UI (turned on using +ShowArbitraryInputs, see settings below) will be shown. An index of 0 tells the UI not to show the field corresponding to that column at all.
		
		| - New column (in label row)
			If this character is put at the beginning of a label row (with a space on either side, such as "# | Title"), that label will force a new column in the UI.
		
		+ - Settings
			Lines which start with this character denote a setting that changes how the UI acts in some manner. They are always in the form "+Option=x", and include:
				ShowArbitraryInputs
					If set to 1, the UI will show an additional input box on the UI for each piece defined by the model row (excluding NAME, ABBREV, and ACTION). Note that these will be shown in the order they are listed by the model row, unless a model index row is present, at which point it respects that.
				
				RowsPerColumn
					Set this to any number X to have the UI start a new column when it hits that many rows in the current column. Note that the current section label will carry over with a (2) if it's the first time it's been broken across columns, (3) if it's the second time, etc.
				
				ColumnWidth
					Set this to any number X to have the UI be X pixels wide (per column if multiple columns are shown).
				
				TrayIcon
					Set this to a path or icon filename to use that icon in the tray.
				
				DefaultAction
					The default action that should be taken when this INI is used. Can be overridden by passing one into .select() directly.
				
				DefaultReturnColumn
					If the action to use is RET, this is the column that will be returned. Defaults to the DOACTION column.
	
	When the user selects their choice, the action passed in at the beginning will be evaluated as a function which receives a loaded SelectorRow object to perform the action on. See SelectorRow class for data structure.
	
	Once the UI is shown, the user can enter either the index or abbreviation for the choice that they would like to select. The user can give information to the popup in a variety of ways:
		Simplest case (+ShowArbitraryInputs != 1, no model or model index rows):
			The user will only have a single input box, where they can add their choice and additional input using the arbitrary character (see below)
			Resulting SelectorRow object will have the name, abbreviation, and action. Arbitrary input is added to the end of the action.
		
		Model row, but +ShowArbitraryInputs != 1
			The user still has a single input box.
			Resulting SelectorRow will have the various pieces in named subscripts of its data array, where the names are those from the model row. Note that name and abbreviation are still separate from the data array, and arbitrary additions are added to action, whether it is set or not.
		
		Model row, with +ShowArbitraryInputs=1 (model index row optional)
			The user will see multiple input boxes, in the order listed in the input file, or in the order of the model index row if defined. The user can override the values defined by the selected choice for each of the columns shown before the requested action is performed.
			Resulting SelectorRow will have the various pieces in named subscripts of its data array, where the names are those from the model row. Note that name and abbreviation are still separate from the data array, and arbitrary additions are ignored entirely (as the user can use the additional inputs instead).
		
	The input that the user puts in the first (sometimes only) input box can also include some special characters:
		
		. - Arbitrary
			Ingored if +ShowArbitraryInputs=1. Allows the user to add additional information to the end of the action eventually performed on the given choice.
		
		+ - Special actions
			These are special changes that can be made to the choice/UI at runtime, when the user is interacting with the UI. They include:
				e - edit
					Putting +e in the input will open the input file. If this is something like a txt or ini file, then it should open in a text editor.
				
				d - debug
					This will send the SelectorRow object to the function as usual, but with the isDebug flag set to true. Note that it's up to the called function to check this flag and send back debug info (stored in SelectorRow.debugResult) rather than actually performing the action, so if you add your own, be sure to include this check or else this option won't work. See selectorActions.ahk for more details.
					Selector will show that result (if given) using DEBUG.popup() (requires debug.ahk).
	
*/

global SEL_GUI := 2

; GUI subroutines. They are initially pass-through with no functionality until Selector.loaded is set.
SelectorEscape:
SelectorClose:
	if(Selector.loaded) {
		; Gui %SEL_GUI%: Cancel ;*gdb 11/14 - Was causing weird issues when a value was in the box.
		Gui %SEL_GUI%: Destroy
		return
	}

SelectorSubmit:
	if(Selector.loaded) {
		Gui %SEL_GUI%: Submit ; Actually saves edit controls' values to GuiIn0, GuiIn1, etc.
		Gui %SEL_GUI%: Destroy
		return
	}

; The above subroutines don't do anything until this flag is set.
Selector.loaded := true

; These must be static or global to use with Edit control.
global GuiIn0
global GuiIn1,  GuiIn2,  GuiIn3,  GuiIn4,  GuiIn5,  GuiIn6,  GuiIn7,  GuiIn8,  GuiIn9,  GuiIn10
global GuiIn11, GuiIn12, GuiIn13, GuiIn14, GuiIn15, GuiIn16, GuiIn17, GuiIn18, GuiIn19, GuiIn20

; Selector class which reads in and stores data from a file, and given an index, abbreviation or action, does that action.
class Selector {
	startupConstants() {
		; Constants and such.
		this.titleChar           := "="
		this.labelChar           := "#"
		this.newColumnChar       := "|"
		this.hiddenChar          := "*"
		this.startModelIndexChar := ")"
		this.settingsChar        := "+"
		
		this.iconEnding := ".ico"
		
		this.editStrings  := ["e", "edit"]
		this.debugStrings := ["d", "debug"]
		
		this.defaultNameIndex   := 1
		this.defaultAbbrevIndex := 2
		this.defaultActionIndex := 3
		
		this.showArbitraryInputs := false
		this.rowsPerColumn       := 99
		this.columnWidth         := 300
		this.iconPath            := ""
		this.actionType          := ""
		this.returnColumn        := "DOACTION"
		this.labelIndices        := [1, 2, 3]
		
		; Various choice data objects.
		this.choices       := [] ; Visible choices the user can pick from.
		this.hiddenChoices := [] ; Invisible choices the user can pick from.
		this.nonChoices    := [] ; Lines that will be displayed as titles, extra newlines, etc, but have no other significance.
		
		; Other init values.
		this.title := "Please make a choice by either number or abbreviation:"
		
		; Settings to use with TableList object when parsing input file.
		this.tableListSettings := []
		this.tableListSettings["CHARS"] := []
		this.tableListSettings["CHARS",  "PLACEHOLDER"]     := "\x"
		this.tableListSettings["CHARS",  "PASS"]            := [this.titleChar, this.labelChar, this.settingsChar]
		this.tableListSettings["FORMAT", "SEPARATE_MAP"]    := {this.startModelIndexChar: "DATA_INDEX"} 
		this.tableListSettings["FORMAT", "DEFAULT_INDICES"] := ["NAME", "ABBREV", "DOACTION"]
	}
	
	init(fPath, action, iconName, selRows, tlSettingOverrides, settingOverrides) {
		; DEBUG.popup("init Filepath", fPath, "Action", action, "Icon name", iconName, "SelRows", selRows)
		
		this.startupConstants()
		
		; If we were given pre-formed SelectorRows, awesome. Otherwise, read from file.
		if(selRows) {
			this.choices := selRows
		} else {
			; DEBUG.popup("Filepath before", fPath)

			; Read in the choices file.
			if(fPath != "") {
				if(FileExist(fPath)) {                                  ; In the current folder, or full path
					this.filePath := fPath
				} else if(FileExist("Includes\" fPath)) {  ; If there's an Includes folder in the same directory, check in there as well.
					this.filePath := "Includes\" fPath
				} else if(FileExist(ahkRootPath "config\" fPath)) {  ; Default folder for selector INIs
					this.filePath := ahkRootPath "config\" fPath
				} else {
					this.errPop(fPath, "File doesn't exist")
					fPath := ""
				}
			} else {
				this.errPop(fPath, "No file given")
			}

			; DEBUG.popup("Filepath after", this.filePath)			
			
			this.tableListSettings := mergeArrays(this.tableListSettings, tlSettingOverrides)
			
			; Load up the choices.
			if(this.filePath)
				this.loadChoicesFromFile(this.filePath)
		}
		
		; Setting overrides.
		if(action)
			this.actionType := action
		if(settingOverrides["ShowArbitraryInputs"])
			this.showArbitraryInputs := settingOverrides["ShowArbitraryInputs"]
		
		; Get paths for the icon file, and read them in.
		if(iconName) { ; Use the icon name override if given.
			this.iconPath := iconName
		} else if(!this.iconPath) {
			this.iconPath := SubStr(this.filePath, 1, -4) this.iconEnding
		}
		
		; DEBUG.popup("Selector.init", "Pre-icon-path-processing", "Parameter icon", iconName, "INI icon", this.iniIconPath, "Chosen icon path", this.iconPath, "Exists", FileExist(this.iconPath))
		
		if(!FileExist(this.iconPath))
			this.iconPath := ahkRootPath "resources\" this.iconPath
		; DEBUG.popup("Selector.init", "Post-icon-path-processing", "Icon file path", this.iconPath)
		
		; DEBUG.popup("Selector.init", "Finish", "Object", this)
	}
	
	/* DESCRIPTION:   Main programmatic access point. Sets up and displays the selector gui, processes the choice, etc.
		PARAMETERS:
			filePath            - Filename (including path and extension) for the input file to generate choices from
			actionType          - Name of the function to call once a choice has been picked (can default from INI if not given here)
			silentChoice        - If supplied, run the selection logic to get a result back using this instead of a user's input (never show the UI)
			iconName            - Filename for the icon.
			data[]              - Assocative array of indices or data labels to data values to default into arbitrary inputs. Only applies if arbitrary inputs are turned on with +ShowArbitraryInputs.
			selRows[]           - Array of SelectorRow objects to use directly instead of reading from filePath.
			tableListSettings[] - Settings to override for when we read in a file using a TableList object.
	*/
	select(filePath, actionType = "", silentChoice = "", iconName = "", data = "", selRows = "", tableListSettings = "", settingOverrides = "", extraData = "") {
		; DEBUG.popup("Filepath", filePath, "Action Type", actionType, "Silent Choice", silentChoice, "Icon name", iconName, "Data", data)
		
		; Set up our various information, read-ins, etc.
		this.init(filePath, actionType, iconName, selRows, tableListSettings, settingOverrides, extraData)
		
		if(extraData) {
			baseLength := this.labelIndices.maxIndex()
			if(!baseLength)
				baseLength := 0
			
			For i,d in extraData {
				For label,dataToDefault in d { ; GDB TODO - there should only ever be one at this layer, find a better way to pick out the index?
					this.labelIndices[baseLength + i] := label
					data[label] := dataToDefault ; GDB TODO - This only works for associative array style stuff right now, do better.
				}
			}
		}
		
		; Loop until we get good input, or the user gives up.
		while(rowToDo = "" && !done) {
			dataFilled := false
			
			; Make sure to clear out the variables that we're assocating with the edit controls.
			nullGlobals("GuiIn", 0, 20) ; Numbers should be kept in sync with global GuiIn0... declarations at top.
			
			; Get the choice.
			if(silentChoice != "") { ; If they've given us a silent choice, run silently, even without the flag.
				userIn := silentChoice
				done := true ; only try this once, don't repeat.
				this.hideErrors := true
			} else { ; Otherwise, popup time.
				userIn := this.launchSelectorPopup(data, dataFilled)
				this.restoreIcon() ; Restore the original tray icon before we start potentially quitting. Will be re-changed by launchSelectorPopup if it loops.
			}
			
			; Blank input, we bail.
			if(!userIn && !dataFilled)
				return ""
			
			; User put something in the first box, which should come from the choices shown.
			if(userIn) {
				rowToDo := this.parseChoice(userIn)
				if(!rowToDo) ; We didn't find a match at all, and showed them an error - next iteration of the loop so they can try again.
					Continue
			}
			
			; They filled something into the arbitrary fields (everything except the first one).
			if(dataFilled) {
				done := true
				if(!rowToDo)
					rowToDo := new SelectorRow()
			}
			
			; Blow in any data from the arbitrary input boxes.
			if(IsObject(data)) {
				For i,l in this.labelIndices {
					; DEBUG.popup("Data labels", this.dataLabels, "Data", data, "Label", v, "Data grabbed", data[v])
					if(data[l])
						rowToDo.data[l] := data[l]
				}
			}
			
			; DEBUG.popup("User Input", userIn, "Row Parse Result", rowToDo, "Action type", this.actionType, "Data filled", dataFilled)
		}
		
		if(!rowToDo)
			return ""
		
		return this.doAction(rowToDo, this.actionType)
	}
	
	; Restore the tray icon if it was something else before.
	restoreIcon() {
		if(this.originalIconPath)
			Menu, Tray, Icon, % this.originalIconPath
	}
	
	; Load the choices and other such things from a specially formatted file.
	loadChoicesFromFile(filePath) {
		
		tl := new TableList(filepath, this.tableListSettings)
		if(this.tableListSettings["FILTER", "COLUMN"])
			list := tl.getFilteredTable(this.tableListSettings["FILTER", "COLUMN"], this.tableListSettings["FILTER", "INCLUDE", "VALUE"])
		else
			list := tl.getTable()
		
		; DEBUG.popup("Filepath", filePath, "Parsed List", list, "Index labels", tl.getIndexLabels(), "Separate rows", tl.getSeparateRows())
		
		; Special model row that tells us how a file with more than 3 columns should be laid out.
		if(IsObject(tl.getIndexLabels()) && IsObject(tl.getSeparateRows())) {
			screenIndices := tl.getSeparateRow("DATA_INDEX")
			this.labelIndices := []
			For i,s in screenIndices {
				if(s > 0)
					this.labelIndices[s] := tl.getIndexLabel(i) ; Index onscreen => label
			}
		}
		; DEBUG.popup("Selector.loadChoicesFromFile", "Processed indices", "Index labels", tl.getIndexLabels(), "Separate rows", tl.getSeparateRows(), "Selector label indices", this.labelIndices)
		
		For i,currItem in list {
			; Parse this size-n array into a new SelectorRow object.
			currRow := new SelectorRow(currItem)
			firstChar := SubStr(currItem[1], 1, 1) ; Only really populated for the non-normal rows.
			; DEBUG.popup("Curr Row", currRow, "First Char", firstChar)
			
			; Popup title.
			if(i = 1 && firstChar = this.titleChar) {
				; DEBUG.popup("Title char", this.titleChar, "First char", firstChar, "Row", currRow)
				this.title := SubStr(currItem[1], 2) " [SLCT]"
			
			; Options for the selector in general.
			} else if(firstChar = this.settingsChar) {
				settingString := SubStr(currRow.data[1], 2)
				setting := StrSplit(settingString, "=")
				if(setting[1] = "ShowArbitraryInputs")
					this.showArbitraryInputs := (setting[2] = "1")
				else if(setting[1] = "RowsPerColumn")
					this.rowsPerColumn := setting[2]
				else if(setting[1] = "ColumnWidth")
					this.columnWidth := setting[2]
				else if(setting[1] = "TrayIcon")
					this.iconPath := setting[2]
				else if(setting[1] = "DefaultAction")
					this.actionType := setting[2]
				else if(setting[1] = "DefaultReturnColumn")
					this.returnColumn := setting[2]
			
			; Special: add a title and/or blank row in the list display.
			} else if(firstChar = this.labelChar) {
				; DEBUG.popup("Label char", this.labelChar, "First char", firstChar, "Row", currRow)
				
				; If blank, extra newline.
				if(StrLen(currItem[1]) < 3) {
					this.nonChoices.push(" ")
				
				; If title, #{Space}Title.
				} else {
					idx := 0
					if(this.choices.MaxIndex())
						idx := this.choices.MaxIndex()
					
					this.nonChoices.InsertAt(idx + 1, SubStr(currItem[1], 3))
					; DEBUG.popup("Just added nonchoice:", this.nonChoices[this.nonChoices.MaxIndex()], "At index", idx + 1)
				}
				
			; Invisible, but viable, choice.
			} else if(firstChar = this.hiddenChar) {
				; DEBUG.popup("Hidden char", this.hiddenChar, "First char", firstChar, "Row", currRow)
				
				; DEBUG.popup("Hidden choice added", currRow)
				this.hiddenChoices.push(currRow)
			
			; Otherwise, it's a visible, viable choice!
			} else {
				; DEBUG.popup("Choice added", currRow)
				this.choices.push(currRow)
			}
		}
	}
	
	; Generate the text for the GUI and display it, returning the user's response.
	launchSelectorPopup(ByRef guiData, ByRef guiDataFilled) {
		guiDataFilled := false
		if(!IsObject(guiData))
			guiData := Object()
		
		; Various GUI element dimensions.
		offsetX            := 10
		offsetIndexAbbrevX := 5
		offsetDataInputX   := 5
		offsetY            := 10
		
		titleX     := 10
		indexX     := 10
		indexW     := 25
		abbrevX    := indexX + indexW + offsetIndexAbbrevX
		abbrevW    := 50
		nameX      := abbrevX + abbrevW + offsetX
		startNameX := nameX
		
		inputX := offsetX
		
		currY := offsetY
		lineHeight := 25
		
		; Change the tray icon.
		if(this.iconPath && FileExist(this.iconPath)) {
			this.originalIconPath := A_IconFile ; Back up the current icon before changing it.
			Menu, Tray, Icon, % this.iconPath
		}
		
		; Create and begin styling the GUI.
		Gui %SEL_GUI%: +LabelSelector  ;*gdb 10/14 - Make labels up top work using a custom label to override number behavior.
		Gui %SEL_GUI%: Color, 2A211C
		Gui %SEL_GUI%: Font, s12 cBDAE9D
		Gui %SEL_GUI%: +LastFound
		GuiHWND := WinExist()
		
		titleStyle := "w700 underline" ; Bold, underline.
		
		; Generate the text to display from the various choice objects.
		displayText := ""
		lineNum := 1
		numColumns := 1
		titleInstance := 1
		
		For i,c in this.choices {
			title := this.nonChoices[i]
			
			if(SubStr(title, 1, 2) = this.newColumnChar " ") {
				title := SubStr(title, 3)
				forceNewCol := true
			}
			
			; Add a new column as needed.
			if(forceNewCol || (lineNum > this.rowsPerColumn) || (title && ((lineNum + 1) > this.rowsPerColumn))) {
				forceNewCol := false
				titleX += this.columnWidth
				indexX += this.columnWidth
				abbrevX += this.columnWidth
				nameX += this.columnWidth
				bottomHeight := max(bottomHeight, currY)
				numColumns++
				
				if(!title) { ; We're not starting a new title here, so show the previous one, continued.
					titleInstance++
					title := currTitle " (" titleInstance ")"
					lineNum := 0
				} else {
					lineNum := 1
				}
				
				currY := offsetY
			}
			
			; Title rows.
			if(title) {
				if(lineNum = 0) {
					lineNum++
				} else {
					currTitle := title
					titleInstance := 1
				}
				
				if((title != " ") && (lineNum > 1)) {
					currY += lineHeight
					lineNum++
				}
				
				; Title formatting.
				Gui %SEL_GUI%: Font, % titleStyle
				
				Gui %SEL_GUI%: Add, Text, x%titleX% y%currY%, %title%
				currY += lineHeight
				lineNum++
				
				; Clear title formatting.
				Gui %SEL_GUI%: Font, norm
			}
			
			name := c.data["NAME"]
			if(IsObject(c.data["ABBREV"]))
				abbrev := c.data["ABBREV"][1]
			else
				abbrev := c.data["ABBREV"]
			
			; DEBUG.popup("Choice putting into UI", c, "Index", i, "Name", name, "Abbreviation", abbrev)
			Gui %SEL_GUI%: Add, Text, x%indexX% Right w%indexW% y%currY%, % i ")"
			Gui %SEL_GUI%: Add, Text, x%abbrevX% y%currY%, % abbrev ":"
			Gui %SEL_GUI%: Add, Text, x%nameX% y%currY%, % name
			
			currY += lineHeight
			lineNum++
		}
		
		bottomHeight := max(bottomHeight, currY)
		
		if(this.columnWidth) {
			guiWidth := numColumns * this.columnWidth
		} else {
			; Show the window in order to get its width.
			Gui %SEL_GUI%: Show, , % this.title
			WinGetPos, , , guiWidth, H, A
		}
		guiWidth -= 5 ; Bezels and such.
		bottomHeight += lineHeight ; Extra row down for aesthetics.
		
		; DEBUG.popup("Index", i, "Data Index", m, "Label at index", this.dataLabels[i], "Label at data index", this.dataLabels[m], "Data at index", GuiIn%i%, "Data at data index", GuiIn%m%, "DataLabels Array", this.dataLabels, "DataIndices Array", this.dataIndices, "ModelIndices Array", this.modelIndices)
		
		if(this.showArbitraryInputs) {
			; Main edit control is equally sized with index + abbrev columns.
			editWidth := indexW + offsetDataInputX + abbrevW
			Gui %SEL_GUI%: Add, Edit, vGuiIn0 x%inputX% y%bottomHeight% w%editWidth% h24 -E0x200 +Border
			
			numArbitInputs := this.labelIndices.length()
			leftoverWidth := guiWidth - startNameX - offsetX ; offsetX is rightmost padding on GUI
			editWidth := (leftoverWidth / numArbitInputs) - ((numArbitInputs - 1) * offsetDataInputX)
			
			posX := startNameX
			; DEBUG.popup("Whole data array", guiData)
			For l,d in this.labelIndices { ; need to change meaning of dataIndices
				if(guiData[d]) ; Data given as default
					tempData := guiData[d]
				else           ; Data label
					tempData := d
					
				; DEBUG.popup("Index", i, "ModelIndex", m, "Data at index", guiData[m], "Label", this.dataLabels[m], "Data at label", guiData[this.dataLabels[m]], "Using data", tempData)
				Gui %SEL_GUI%: Add, Edit, vGuiIn%l% x%posX% y%bottomHeight% w%editWidth% h24 -E0x200 +Border, % tempData
				posX += editWidth + offsetDataInputX
			}
			
		} else {
			; Add the edit control with almost the width of the window.
			editWidth := guiWidth - (offsetX * 2)
			Gui %SEL_GUI%: Add, Edit, vGuiIn0 x%inputX% y%bottomHeight% w%editWidth% h24 -E0x200 +Border
		}
		
		; Resize the GUI to show the newly added edit control row.
		finalHeight += bottomHeight + 30
		Gui %SEL_GUI%: Show, h%finalHeight%, % this.title
		
		; Hidden OK button for {Enter} submission.
		Gui %SEL_GUI%: Add, Button, Hidden Default +gSelectorSubmit, SubmitSelector
		
		; Focus the edit control.
		GuiControl, %SEL_GUI%:Focus, GuiIn0
		GuiControl, %SEL_GUI%:+0x800000, GuiIn0
		
		; Wait for the user to submit the GUI.
		WinWaitClose, ahk_id %GuiHWND%
		
		
		; == GUI is now waiting for user to do something ==
		
		
		; DEBUG.popup("DataLabels Array", this.dataLabels, "DataIndices Array", this.dataIndices, "ModelIndices Array", this.modelIndices, "Model Indices Reversed", this.modelIndicesReverse)
		if(this.showArbitraryInputs) {
			For i,l in this.labelIndices {
				inputVal := GuiIn%i%
				if(inputVal && (inputVal != l)) {
					; DEBUG.popup("Index", i, "Model index", m, "Label at index", this.dataLabels[i], "Label at data index", this.dataLabels[m], "Data at index", GuiIn%i%, "Data at data index", GuiIn%m%, "DataLabels Array", this.dataLabels, "DataIndices Array", this.dataIndices, "ModelIndices Array", this.modelIndices, "Model Indices Reversed", this.modelIndicesReverse)
					guiDataFilled := true
					guiData[l] := GuiIn%i%
				}
			}
		}
		
		return GuiIn0
	}
	
	; Function to turn the input into something useful.
	parseChoice(userIn) {
		settingsCharPos := InStr(userIn, this.settingsChar)
		
		rowToDo := ""
		rest := SubStr(userIn, 2)
		
		; DEBUG.popup("Selector.parseChoice", "Start", "User in", userIn, "Settings char pos", settingsCharPos)
		
		; No input in main box, but others possibly filled out
		if(userIn = "") {
			return ""
		
		; Special choice - edit ini, debug, etc.
		} else if(settingsCharPos = 1) {
			; DEBUG.popup("Got setting", rest)
			
			; Special case: +e is the edit action, which will open the current INI file for editing.
			if(contains(this.editStrings, rest)) {
				; DEBUG.popup("Edit action", rest, "Edit strings", this.editStrings)
				this.actionType := "DO"
				rowToDo := new SelectorRow()
				rowToDo.data["DOACTION"] := this.filePath
			
			; Special case: +d is debug action, which will copy/popup the result of the action.
			} else if(contains(this.debugStrings, rest, 1)) {
				; Peel off the d + space, and run it through this function again.
				StringTrimLeft, userIn, rest, 2
				rowToDo := this.parseChoice(userIn)
				if(rowToDo)
					rowToDo.isDebug := true
			
			; Otherwise, we don't know what this is.
			} else if(!isNum(rest)) {
				this.errPop("Invalid special input option")
			}
		
		; Otherwise, we search through the data structure by both number and shortcut and look for a match.
		} else {
			rowToDo := this.searchAllTables(userIn)
			
			if(!rowToDo)
				this.errPop("No matches found!")
		}
		
		; DEBUG.popup("Row to do", rowToDo)
		
		return rowToDo
	}

	; Search both given tables, the visible and the invisible.
	searchAllTables(input) {
		; Try the visible choices.
		out := this.searchTable(this.choices, input)
		if(out)
			return out
		
		; Try the invisible choices.
		out := this.searchTable(this.hiddenChoices, input)
		
		return out
	}

	; Function to search our generated table for a given index/shortcut.
	searchTable(table, input) {
		For i,t in table {
			if(input = i) ; They picked the index itself.
				return t.clone()
			
			; Abbreviation could be an array, so account for that.
			if(!IsObject(t.data["ABBREV"]) && (input = t.data["ABBREV"]))
				return t.clone()
			if(IsObject(t.data["ABBREV"]) && contains(t.data["ABBREV"], input))
				return t.clone()
		}
		
		return ""
	}

	; Function to do what it is we want done, then exit.
	doAction(rowToDo, actionType) {
		; DEBUG.popup("Action type", actionType, "Row to run", rowToDo, "Action", action)
		
		if(!actionType)
			actionType := "RET" ; Default action if none given.
		
		if(actionType = "RET") ; Special case for simple return action, passing in the column to return.
			result := RET(rowToDo, this.returnColumn)
		else if(isFunc(actionType)) ; Generic caller for many possible actions.
			result := actionType.(rowToDo)
		else ; Error catch.
			this.errPop("Action " actionType " not defined!")
		
		; Debug case - show a popup with row info and copy it to the clipboard, don't do the actual action.
		if(rowToDo.isDebug) {
			result := ""
			if(!IsObject(rowToDo.debugResult))
				clipboard := rowToDo.debugResult
			DEBUG.popup("Debugged row", rowToDo)
		}
		
		return result
	}
	
	; Centralized MsgBox clone that respects the silencer flag.
	errPop(text, label = "") {
		if(!this.hideErrors) {
			if(!label)
				label := "Error"
			if(isFunc("DEBUG.popup"))
				DEBUG.popup(label, text)
			else
				MsgBox, % "Label: `n`t" label "`nText: `n`t" text
		}
	}
	
	; Debug info
	debugName := "Selector"
	debugToString(numTabs = 0) {
		outStr .= DEBUG.buildDebugString("Choices", this.choices, numTabs)
		outStr .= DEBUG.buildDebugString("Hidden Choices", this.hiddenChoices, numTabs)
		outStr .= DEBUG.buildDebugString("Non-Choices", this.nonChoices, numTabs)
		return outStr
	}
}