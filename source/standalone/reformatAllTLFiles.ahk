; Activate (or run if not already open) a specific program, to be executed by external program (like Microsoft keyboard special keys).
#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>

global SpacesPerTab := 3

root := Config.path["AHK_ROOT"]
Loop, Files, %root%\*.tl*, RF
{
	reformatFile(A_LoopFileFullPath)
}

new Toast("Reformatted all TL and TLS files in AHK root directory").blockingOn().showMedium()

ExitApp


reformatFile(filePath) {
	rowsAry := FileLib.fileLinesToArray(filePath)
	
	; Figure out the width of each column
	columnWidthsAry := []
	For _,row in rowsAry {
		row := row.withoutWhitespace()
		
		; Ignore certain rows for width-calculation purposes
		if(row.startsWith("[") || row.startsWith(";") || row.startsWith("@") || row.startsWith("# "))
			Continue
		
		; Model rows and key rows have an extra bit (and possibly whitespace) at the start
		if(row.startsWith("(") || row.startsWith(")")) {
			row := row.removeFromStart("(")
			row := row.removeFromStart(")")
			row := row.withoutWhitespace()
		}
		
		; Reduce any sets of multiple tabs in a row to a single one.
		Loop {
			if(!row.contains(A_Tab A_Tab))
				Break
			row := row.replace(A_Tab A_Tab, A_Tab)
		}
		
		; Track size of each column (in tabs).
		For columnIndex,value in row.split(A_Tab) {
			width := 1 + Ceil(value.length() / SpacesPerTab) ; Always at least 1 tab, plus the number of tabs needed to completely cover the longest value.
			columnWidthsAry[columnIndex] := DataLib.max(columnWidthsAry[columnIndex], width)
			; Debug.popup("columnIndex",columnIndex, "value",value, "width",width)
		}
	}

	; Figure out the starting indent level for "normal" rows - affected by model/key rows and mod rows.
	normalIndentLevel := 0
	numOpenMods := 0
	For _,row in rowsAry {
		row := row.withoutWhitespace()
		
		; Model/key rows cause us to push everything out to one tab.
		if(row.startsWith("(") || row.startsWith(")")) {
			normalIndentLevel := DataLib.max(normalIndentLevel, 1)
			Continue
		}
		
		; Mod rows shift the level based on the max mods open (1 mod open = 1 additional indent).
		if(row.startsWith("[")) {
			modContents := row.removeFromStart("[").removeFromEnd("]")
			if(modContents = "") ; Clearing all mods
				numOpenMods := 0
			else if(modContents.startsWith("-")) ; Closing one specific mod
				numOpenMods--
			else
				numOpenMods++
			
			; Debug.popup("row",row, "modContents",modContents, "numOpenMods",numOpenMods)
			
			normalIndentLevel := DataLib.max(normalIndentLevel, numOpenMods)
			Continue
		}
	}

	; Debug.popup("rowsAry",rowsAry, "columnWidthsAry",columnWidthsAry, "normalIndentLevel",normalIndentLevel)

	; Rewrite each row with enough tabs to space things correctly
	normalIndent := StringLib.getTabs(normalIndentLevel)
	modIndentLevel := 0
	newRowsAry := []
	For _,rowText in rowsAry {
		row := rowText.withoutWhitespace()
		
		; Comment rows are left exactly as-is (including indentation).
		if(row.startsWith(";")) {
			newRowsAry.push(rowText) ; rowText, not row - to preserve original indentation.
			Continue
		}
		
		; Setting and header rows never get any indentation.
		if(row.startsWith("@") || row.startsWith("# ")) {
			newRowsAry.push(row)
			Continue
		}
		
		; Blank rows go at the current mod indent level.
		if(row = "") {
			newRowsAry.push(StringLib.getTabs(modIndentLevel) row)
			Continue
		}
		
		; Mod rows are different - they increase or decrease the normal indent for following rows.
		if(row.startsWith("[")) {
			modContents := row.removeFromStart("[").removeFromEnd("]")
			
			; Clear all mods - clear indent.
			if(modContents = "") {
				newRowsAry.push(row)
				modIndentLevel := 0
				Continue
			}
			
			; Removing a mod - decrease indent.
			if(modContents.startsWith("-")) {
				modIndentLevel-- ; Decrease this first so this row goes a level back.
				newRowsAry.push(StringLib.getTabs(modIndentLevel) row)
				Continue
			}
			
			; Adding a mod - increase indent.
			newRowsAry.push(StringLib.getTabs(modIndentLevel) row)
			modIndentLevel++
			Continue
		}
		
		; Model/key row chars are special "prefixes" that come before starting indentation
		prefix := ""
		if(row.startsWith("(")) {
			prefix := "("
			row := row.removeFromStart("(").withoutWhitespace()
		}
		if(row.startsWith(")")) {
			prefix := ")"
			row := row.removeFromStart(")").withoutWhitespace()
		}
		
		; Reduce any sets of multiple tabs in a row to a single one to start, then split it.
		Loop {
			if(!row.contains(A_Tab A_Tab))
				Break
			row := row.replace(A_Tab A_Tab, A_Tab)
		}
		
		newRow := ""
		For columnIndex,value in row.split(A_Tab) {
			columnWidth := columnWidthsAry[columnIndex]
			valueWidth := Floor(value.length() / SpacesPerTab) ; Width in tabs
			newRow .= value StringLib.getTabs(columnWidth - valueWidth)
			
			; Debug.popup("value",value, "columnWidth",columnWidth, "valueWidth",valueWidth)
		}
		
		newRow := newRow.withoutWhitespace() ; Trim off any extra indentation we don't need at the end of each row
		newRowsAry.push(prefix normalIndent newRow)
	}

	FileLib.replaceFileWithString(filePath, newRowsAry.join("`r`n") "`r`n")
}

ExitApp
