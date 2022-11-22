; Reformat all TL and TLS files in the AHK root folder and below, to my personally preferred standard.

#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
FileEncoding, UTF-8          ; Read files in UTF-8 encoding by default to handle special characters.

#Include <includeCommon>

global MIN_COLUMN_PADDING := 1 ; At least 1 tab between columns
global TAB_WIDTH := VSCode.TabWidth ; Match Notepad++ since that's where we're editing these

; Convenience constants that are shorter than referencing TableList constants directly.
global MODEL_START   := TableList.Char_Model_Start
global MODEL_END     := TableList.Char_Model_End
global COLINFO_START := TableList.Char_ColumnInfo_Start
global COLINFO_END   := TableList.Char_ColumnInfo_End


if(!GuiLib.showConfirmationPopup("Reformat all TL/TLS files?"))
	ExitApp

progToast := new ProgressToast("Reformatting TL/TLS files").blockingOn()

progToast.nextStep("Main repo")
root := Config.path["AHK_ROOT"]
Loop, Files, %root%\*.tl*, RF
{
	reformatFile(A_LoopFileFullPath)
}

progToast.nextStep("Private repo")
root := Config.path["AHK_PRIVATE"]
Loop, Files, %root%\*.tl*, RF
{
	reformatFile(A_LoopFileFullPath)
}

progToast.finish()
ExitApp


reformatFile(filePath) {
	rows := FileLib.fileLinesToArray(filePath)
	
	newRows := reformatRows(rows)
	fileContents := newRows.join("`r`n") "`r`n" ; Extra newline on the end
	
	FileLib.replaceFileWithString(filePath, fileContents)
}

reformatRows(rows) {
	getDimensions(rows, normalIndentLevel, columnWidthsAry)
	
	modIndentLevel := 0
	newRows := []
	For _,rowText in rows {
		row := rowText.withoutWhitespace()
		
		; Model row gets its contents indented to match normal rows, with the closing bracket 1 tab off the last element.
		if(isModel(row)) {
			rowContent := removePrefixSuffix(row)
			rowContent := fixColumnWidths(rowContent, columnWidthsAry)
			rowSoFar := MODEL_START StringLib.getTabs(normalIndentLevel) rowContent "`t" ; Always one tab before the closing bracket.
			
			; Measure where the closing bracket is so we can match the position in the column info row.
			columnInfoClosePosition := getCharacterWidth(rowSoFar)
			
			row := rowSoFar MODEL_END
			newRows.push(row)
			Continue
		}
		
		; Column info row gets its contents indented to match normal rows, with the closing paren matching the model row's closing bracket.
		if(isColumnInfo(row)) {
			rowContent := removePrefixSuffix(row)
			rowContent := fixColumnWidths(rowContent, columnWidthsAry)
			rowSoFar := COLINFO_START StringLib.getTabs(normalIndentLevel) rowContent
			
			; Align the ending paren with the model row's ending bracket.
			numSpacesShort := columnInfoClosePosition - getCharacterWidth(rowSoFar)
			numTabsShort := Ceil(numSpacesShort / TAB_WIDTH)
			
			row := rowSoFar StringLib.getTabs(numTabsShort) COLINFO_END
			newRows.push(row)
			Continue
		}
		
		; Comment rows are left exactly as-is (including indentation).
		if(isIgnore(row)) {
			newRows.push(rowText) ; rowText, not row - preserve original indentation.
			Continue
		}
		
		; Setting and header rows are never split, and get no indentation.
		if(isSetting(row) || isHeader(row)) {
			newRows.push(row)
			Continue
		}
		
		; Blank rows indent to match mods.
		if(row = "") {
			newRows.push(StringLib.getTabs(modIndentLevel) row)
			Continue
		}
		
		; Closing previous mod + opening a new one on the same line ("} ... {")
		if(isModClose(row) && isModOpen(row)) {
			newRows.push(StringLib.getTabs(modIndentLevel - 1) row) ; Indent this at one level back, but leave the indent level as-is since we're opening a new mod.
			Continue
		}
		
		; Closing a mod set - decrease indent.
		if(isModClose(row)) {
			modIndentLevel-- ; Decrease this first so this row goes a level back.
			newRows.push(StringLib.getTabs(modIndentLevel) row)
			Continue
		}
		
		; Adding a mod set
		if(isModOpen(row)) {
			; Increase indent
			newRows.push(StringLib.getTabs(modIndentLevel) row)
			modIndentLevel++
			Continue
		}
		
		indent := StringLib.getTabs(normalIndentLevel)
		row    := fixColumnWidths(row, columnWidthsAry)
		newRows.push(indent row)
	}
	
	return newRows
}

; Figure out our overall dimensions - column widths and indentation level for "normal" rows.
getDimensions(rows, ByRef normalIndentLevel, ByRef columnWidthsAry) {
	normalIndentLevel := 0
	columnWidthsAry   := []
	
	numOpenMods := 0
	For _,row in rows {
		row := row.withoutWhitespace()
		
		; Some rows don't affect widths or indentation
		if(isIgnore(row) || isSetting(row) || isHeader(row))
			Continue
		
		; Removing a mod set
		if(isModClose(row)) {
			numOpenMods--
			DataLib.updateMax(normalIndentLevel, numOpenMods)
			Continue
		}
		
		; Adding a mod set
		if(isModOpen(row)) {
			numOpenMods++
			DataLib.updateMax(normalIndentLevel, numOpenMods)
			Continue
		}
		
		; Model/column info rows - make sure "normal" indentation is at least 1 so we can separate the first column from the prefix.
		if(isModel(row) || isColumnInfo(row)) {
			DataLib.updateMax(normalIndentLevel, 1)
			
			; Remove the prefix/suffix so we can count the columns inside towards the column widths
			row := removePrefixSuffix(row)
		}
		
		; Track size of each column (in tabs).
		For columnIndex,value in splitRow(row) {
			width := Ceil(value.length() / TAB_WIDTH) + MIN_COLUMN_PADDING ; Width in tabs - ceiling means we'll get at least 1 FULL tab of padding
			columnWidthsAry[columnIndex] := DataLib.max(columnWidthsAry[columnIndex], width)
		}
	}
}

splitRow(row) {
	; Reduce any sets of multiple tabs in a row to a single one, so we don't end up with any extra blank column values.
	Loop {
		if(!row.contains(A_Tab A_Tab))
			Break
		row := row.replace(A_Tab A_Tab, A_Tab)
	}
	
	return row.split(A_Tab)
}

getCharacterWidth(stringToMeasure) {
	numChars := 0
	
	Loop, Parse, % stringToMeasure
	{
		if(A_LoopField = A_Tab)
			numChars += (TAB_WIDTH - mod(numChars, TAB_WIDTH)) ; Each tab brings us to the next tab stop
		else
			numChars++
	}
	
	return numChars
}

removePrefixSuffix(row) {
	row := row.removeFromStart(MODEL_START).removeFromEnd(MODEL_END)
	row := row.removeFromStart(COLINFO_START).removeFromEnd(COLINFO_END)
	return row.withoutWhitespace()
}

fixColumnWidths(row, columnWidthsAry) {
	newRow := ""
	
	For columnIndex,value in splitRow(row) {
		columnWidth := columnWidthsAry[columnIndex]
		valueWidth := Floor(value.length() / TAB_WIDTH) ; Width in tabs
		newRow .= value StringLib.getTabs(columnWidth - valueWidth)
	}
	
	return newRow.withoutWhitespace() ; Trim off any extra indentation we don't need at the end of the row
}

isIgnore(row) {
	return row.startsWith(TableList.Char_Ignore)
}
isSetting(row) {
	return row.startsWith(TableList.Char_Setting)
}
isHeader(row) {
	return row.startsWith(TableList.Char_Header)
}
isModClose(row) {
	return row.startsWith(TableList.Char_Mod_Close)
}
isModOpen(row) {
	return row.endsWith(TableList.Char_Mod_Open)
}
isModel(row) {
	return row.startsWith(TableList.Char_Model_Start)
}
isColumnInfo(row) {
	return row.startsWith(TableList.Char_ColumnInfo_Start)
}
