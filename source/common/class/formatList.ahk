/* Class to represent a list of strings, that can be parsed and output in a variety of different formats.
	
	***
	
	GDB TODO
		More output methods
			Filling a list of IDs into EpicStudio (Before/after inputs on Selector popup for code surrounding lines, newlines only applied after that)
				Should this really just be part of the M snippets stuff, and just have it make use of .getList(FormatList.Format_Array)?
				Maybe take this a step further and make it specifically filling in an array?
				Make sure that dot level is taken into account (I think I have functions for that)
*/

class FormatList {

; ==============================
; == Public ====================
; ==============================
	; Formats for reading/writing lists.
	static Format_Array         := "ARRAY"
	static Format_Commas        := "COMMA"
	static Format_NewLines      := "NEWLINE"
	static Format_OneNoteColumn := "ONENOTE_COLUMN"
	
	originalFormat := ""
	
	__New(listObject, inFormat := "") {
		; Convert input list into an array for processing.
		if(!this.parseListObject(listObject, inFormat))
			return ""
		
		; DEBUG.popup("listObject",listObject, "this.delimsAry",this.delimsAry, "this.listAry",this.listAry)
	}
	
	getList(format := "") {
		if(!format)
			format := this.promptForFormat("Enter OUTPUT format for list")
		if(!format)
			return ""
		
		formattedList := this.getListInFormat(format)
		if(formattedList = "")
			Toast.showError("Could not get list", "Format is not gettable: " format)
		
		return formattedList
	}
	
	sendList(format := "") {
		if(!format)
			format := this.promptForFormat("Enter OUTPUT format for list")
		if(!format)
			return ""
		
		if(!this.sendListInFormat(format))
			Toast.showError("Could not send list", "Format is not sendable: " format)
	}
	
	
; ==============================
; == Private ===================
; ==============================
	listAry := ""
	
	; Special, internal-only list formats
	static Format_Ambiguous     := "AMBIGUOUS"      ; Can't tell what the format is, so we'll have to ask the user.
	static Format_UnknownSingle := "UNKNOWN_SINGLE" ; We don't know what the format is, but it looks like a single item only.
	
	parseListObject(listObject, format) {
		; If the incoming format wasn't given, try to figure it out.
		if(!format)
			format := this.determineListFormat(listObject)
		
		; Quit silently if the format was blanked out (user was prompted but didn't pick anything)
		if(!format)
			return false
		
		; Turn the list into an array.
		this.listAry := this.transformToAry(listObject, format)
		
		return true
	}
	
	determineListFormat(listObject) {
		; Try to figure it out based on the list object itself.
		if(isObject(listObject)) ; All objects are assumed to be arrays
			format := FormatList.Format_Array
		else ; Everything else is assumed to be a string
			format := FormatList.determineFormatByDelimiters(listObject)
		
		; If we can't tell, ask the user.
		if(format = FormatList.Format_Ambiguous)
			format := this.promptForFormat("Enter INPUT format for list")
		
		return format
	}
	
	determineFormatByDelimiters(listString) {
		distinctDelimsCount := 0
		if(stringContains(listString, ",")) {
			foundFormat := FormatList.Format_Commas
			distinctDelimsCount++
		}
		if(stringContains(listString, "`r`n")) {
			foundFormat := FormatList.Format_NewLines
			distinctDelimsCount++
		}
		if(stringContains(listString, "`r`n`r`n")) {
			foundFormat := FormatList.Format_OneNoteColumn
			distinctDelimsCount++
		}
		
		if(distinctDelimsCount = 0)
			return FormatList.Format_UnknownSingle ; No delimiters, so we're not sure which format it is, but just a single value - so we know what to do with it.
		if(distinctDelimsCount = 1)
			return foundFormat ; Just one matching delimiter, that's gotta be it.
		if(distinctDelimsCount > 1)
			return FormatList.Format_Ambiguous ; We found multiple possibilities, ask the user to choose.
		
		return ""
	}
	
	; Determine the format to convert the list into if not given.
	promptForFormat(title) {
		s := new Selector("listFormats.tls")
		return s.selectGui("FORMAT", title)
	}
	
	; Turn the list into an array based on its format.
	transformToAry(listObject, format) {
		if(format = FormatList.Format_Array)
			listAry := listObject
		if(format = FormatList.Format_UnknownSingle) ; We don't know what delimiter the list was input with, but it seems to just be a single element, so it doesn't matter.
			listAry := [listObject]
		if(format = FormatList.Format_Commas)
			listAry := StrSplit(listObject, ",", " `t") ; Drop leading/trailing spaces, tabs
		if(format = FormatList.Format_NewLines)
			listAry := StrSplit(listObject, "`r`n", " `t") ; Drop leading/trailing spaces, tabs
		if(format = FormatList.Format_OneNoteColumn) ; Cells are separated by double newlines
			listAry := StrSplit(listObject, "`r`n`r`n", " `t`r`n") ; Drop leading/trailing spaces, tabs, newlines
		
		return arrayDropEmptyValues(listAry)
	}
	
	getListInFormat(format) {
		if(!this.listAry || !format)
			return ""
		
		if(format = FormatList.Format_Array)
			return this.listAry
		if(format = FormatList.Format_Commas)
			return arrayJoin(this.listAry, ",")
		if(format = FormatList.Format_NewLines)
			return arrayJoin(this.listAry, "`n")
		
		return ""
	}
	
	sendListInFormat(format) {
		if(!this.listAry || !format)
			return true
		
		; Stuff that doesn't involve extra keys - just Send what comes out of .getListInFormat().
		if(format = FormatList.Format_Commas || format = FormatList.Format_NewLines) {
			SendRaw, % this.getListInFormat(format)
			return true
		}
		
		; OneNote columns - send a down arrow keystroke between items.
		if(format = FormatList.Format_OneNoteColumn) {
			For i,item in this.listAry {
				SendRaw, % item
				if(i < this.listAry.length()) {
					SendPlay, {Down} ; SendPlay is required because OneNote doesn't reliably take {Down} keystrokes otherwise.
					Sleep, 150 ; Required because otherwise the down keystrokes can get out of sync with the items.
				}
			}
			return true
		}
		
		return false
	}
}