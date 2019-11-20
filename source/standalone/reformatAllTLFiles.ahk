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

reformatRows(rows) {
	getDimensions(rows, normalIndentLevel, columnWidthsAry)
	
	modIndentLevel := 0
	newRows := []
	For _,rowText in rows {
		row := rowText.withoutWhitespace()
		
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
		
		; Mod rows indent based on how many mods are open.
		if(row.startsWith(TableList.Char_Mod_Start)) {
			modContents := row.removeFromStart(TableList.Char_Mod_Start).removeFromEnd(TableList.Char_Mod_End)
			
			; Clear all mods - zero out indent.
			if(modContents = "") {
				newRows.push(row) ; No indentation for this row, either.
				modIndentLevel := 0
				Continue
			}
			
			; Removing a mod - decrease indent.
			if(modContents.startsWith(TableList.Char_Mod_RemoveLabel)) {
				modIndentLevel-- ; Decrease this first so this row goes a level back.
				newRows.push(StringLib.getTabs(modIndentLevel) row)
				Continue
			}
			
			; Adding a mod - increase indent.
			newRows.push(StringLib.getTabs(modIndentLevel) row)
			modIndentLevel++
			Continue
		}
		
		prefix := stripOffModelKeyPrefix(row) ; Model/key rows have a special prefix that comes before starting indentation.
		indent := StringLib.getTabs(normalIndentLevel)
		row    := fixColumnWidths(row, columnWidthsAry)
		
		newRows.push(prefix indent row)
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
		
		; Mod rows shift the level based on the max mods open (1 mod open = 1 additional indent), but don't affect column widths.
		if(row.startsWith(TableList.Char_Mod_Start)) {
			modContents := row.removeFromStart(TableList.Char_Mod_Start).removeFromEnd(TableList.Char_Mod_End)
			if(modContents = "") ; Clearing all mods
				numOpenMods := 0
			else if(modContents.startsWith(TableList.Char_Mod_RemoveLabel)) ; Closing one specific mod
				numOpenMods--
			else
				numOpenMods++
			
			DataLib.updateMax(normalIndentLevel, numOpenMods)
			Continue
		}
		
		; Model/key rows - make sure "normal" indentation is at least 1 so we can separate the first column from the prefix.
		if(stripOffModelKeyPrefix(row) != "")
			DataLib.updateMax(normalIndentLevel, 1)
		
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

stripOffModelKeyPrefix(ByRef row) {
	if(row.startsWith(TableList.Char_Model))
		prefix := TableList.Char_Model
	else if(row.startsWith(TableList.Char_ColumnInfo))
		prefix := TableList.Char_ColumnInfo
	
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
