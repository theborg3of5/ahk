; Reformat all TL and TLS files in the AHK root folder and below, to my personally preferred standard.

#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>

global SPACES_PER_TAB := 3
global MIN_COLUMN_PADDING := 1 ; At least 1 tab between columns

if(!GuiLib.showConfirmationPopup("Reformat all TL/TLS files in AHK root directory?"))
	ExitApp

; Loop over .tl and .tls files in the AHK root directory.
root := Config.path["AHK_ROOT"]
Loop, Files, %root%\*.tl*, RF
{
	reformatFile(A_LoopFileFullPath)
}

new Toast("Reformatted all TL/TLS files in AHK root directory").blockingOn().showMedium()

ExitApp


reformatFile(filePath) {
	rows := FileLib.fileLinesToArray(filePath)
	
	newRows := reformatRows(rows)
	fileContents := newRows.join("`r`n") "`r`n" ; Extra newline on the end
	
	FileLib.replaceFileWithString(filePath, fileContents)
}

getCharacterWidth(stringToMeasure) { ; GDB TODO - this isn't accurate, need to track tab STOPS, not just how long tabs are (because they vary!)
	numChars := 0
	
	Loop, Parse, % stringToMeasure
	{
		if(A_LoopField = A_Tab)
			numChars += (SPACES_PER_TAB - mod(numChars, SPACES_PER_TAB))
		else
			numChars++
	}
	
	return numChars
}

reformatRows(rows) {
	getDimensions(rows, normalIndentLevel, columnWidthsAry)
	
	modIndentLevel := 0
	newRows := []
	For _,rowText in rows {
		row := rowText.withoutWhitespace()
		
		; Model and Column Info rows get indented to match normal rows, but also have a prefix and suffix to add, with at least a little spacing.
		if(row.startsWith(TableList.Char_Model_Start)) {
			prefix := TableList.Char_Model_Start
			suffix := TableList.Char_Model_End
			rowContent := row.removeFromStart(prefix).removeFromEnd(suffix).withoutWhitespace()
			rowContent := fixColumnWidths(rowContent, columnWidthsAry)
			
			rowSoFar := prefix StringLib.getTabs(normalIndentLevel) rowContent "`t" ; Always one tab before the closing bracket.
			columnInfoClosePosition := getCharacterWidth(rowSoFar) ; Measure where the closing bracket is so we can match the position in the column info row.
			row := rowSoFar suffix
			
			newRows.push(row)
			Continue
		}
		
		if(row.startsWith(TableList.Char_ColumnInfo_Start)) {
			prefix := TableList.Char_ColumnInfo_Start
			suffix := TableList.Char_ColumnInfo_End
			rowContent := row.removeFromStart(prefix).removeFromEnd(suffix).withoutWhitespace()
			rowContent := fixColumnWidths(rowContent, columnWidthsAry)
			
			rowSoFar := prefix StringLib.getTabs(normalIndentLevel) rowContent
			
			; Align the ending bracket with the model row's.
			numSpacesShort := columnInfoClosePosition - getCharacterWidth(rowSoFar)
			numTabsShort := Ceil(numSpacesShort / SPACES_PER_TAB)
			row := rowSoFar StringLib.getTabs(numTabsShort) suffix
			
			newRows.push(row)
			Continue
		}
		
		; Comment rows are left exactly as-is (including indentation).
		if(row.startsWith(TableList.Char_Ignore)) {
			newRows.push(rowText) ; rowText, not row - preserve original indentation.
			Continue
		}
		
		; Setting and header rows are never split, and get no indentation.
		if(row.startsWith(TableList.Char_Setting) || row.startsWith(TableList.Char_Header)) {
			newRows.push(row)
			Continue
		}
		
		; Blank rows indent to match mods.
		if(row = "") {
			newRows.push(StringLib.getTabs(modIndentLevel) row)
			Continue
		}
		
		; Closing a mod set - decrease indent.
		if(row.startsWith(TableList.Char_Mod_Close)) {
			modIndentLevel-- ; Decrease this first so this row goes a level back.
			newRows.push(StringLib.getTabs(modIndentLevel) row)
			Continue
		}
		
		; Adding a mod set
		if(row.endsWith(TableList.Char_Mod_Open)) {
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
		if(row.startsWith(TableList.Char_Ignore) || row.startsWith(TableList.Char_Setting) || row.startsWith(TableList.Char_Header))
			Continue
		
		; Removing a mod set
		if(row.startsWith(TableList.Char_Mod_Close)) {
			numOpenMods--
			DataLib.updateMax(normalIndentLevel, numOpenMods)
			Continue
		}
		
		; Adding a mod set
		if(row.endsWith(TableList.Char_Mod_Open)) {
			numOpenMods++
			DataLib.updateMax(normalIndentLevel, numOpenMods)
			Continue
		}
		
		; Model/column info rows - make sure "normal" indentation is at least 1 so we can separate the first column from the prefix.
		if(row.startsWith(TableList.Char_Model_Start) || row.startsWith(TableList.Char_ColumnInfo_Start)) {
			DataLib.updateMax(normalIndentLevel, 1)
			
			; Also track size of each column (in tabs).
			row := row.removeFromStart(TableList.Char_Model_Start).removeFromEnd(TableList.Char_Model_End).withoutWhitespace() ; GDB TODO clean this up better
			row := row.removeFromStart(TableList.Char_ColumnInfo_Start).removeFromEnd(TableList.Char_ColumnInfo_End).withoutWhitespace()
			For columnIndex,value in splitRow(row) {
				width := Ceil(value.length() / SPACES_PER_TAB) + MIN_COLUMN_PADDING ; Width in tabs - ceiling means we'll get at least 1 FULL tab of padding
				columnWidthsAry[columnIndex] := DataLib.max(columnWidthsAry[columnIndex], width)
			}
			Continue
		}
		
		; Track size of each column (in tabs).
		For columnIndex,value in splitRow(row) {
			width := Ceil(value.length() / SPACES_PER_TAB) + MIN_COLUMN_PADDING ; Width in tabs - ceiling means we'll get at least 1 FULL tab of padding
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

; GDB TODO rename if we keep this - column info, not key
stripOffModelKeyPrefix(ByRef row) {
	if(row.startsWith(TableList.Char_Model_Start))
		prefix := TableList.Char_Model_Start
	else if(row.startsWith(TableList.Char_ColumnInfo_Start))
		prefix := TableList.Char_ColumnInfo_Start
	
	; Remove the prefix and any extra whitespace from the row so it can be split normally.
	if(prefix != "")
		row := row.removeFromStart(prefix).withoutWhitespace()
	
	return prefix
}

fixColumnWidths(row, columnWidthsAry) {
	newRow := ""
	
	For columnIndex,value in splitRow(row) {
		columnWidth := columnWidthsAry[columnIndex]
		valueWidth := Floor(value.length() / SPACES_PER_TAB) ; Width in tabs
		newRow .= value StringLib.getTabs(columnWidth - valueWidth)
	}
	
	return newRow.withoutWhitespace() ; Trim off any extra indentation we don't need at the end of the row
}
