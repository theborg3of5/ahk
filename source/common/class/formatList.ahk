/* Class to represent a list of strings, that can be parsed and output in a variety of different formats.
	
	Example usage
		fl := new FormatList(clipboard)
		listAry := fl.getList(FormatList.Format_Array) ; Get the list as an array
		fl.sendList() ; Prompt the user for the format to send in
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
	
	;---------
	; DESCRIPTION:    Create a new FormatList object.
	; PARAMETERS:
	;  listObject (I,REQ) - Object representing the list, may be an array or delimited string.
	;  inFormat   (I,OPT) - Format that the list is in (from FormatList.Format_* constants). If not
	;                       given, we will try to determine it ourselves and prompt the user if we
	;                       can't figure it out.
	;---------
	__New(listObject, inFormat := "") {
		; Convert input list into an array for processing.
		if(!this.parseListObject(listObject, inFormat))
			return ""
		
		; DEBUG.popup("listObject",listObject, "this.delimsAry",this.delimsAry, "this.listAry",this.listAry)
	}
	
	;---------
	; DESCRIPTION:    Get the list in a certain format, programmatically.
	; PARAMETERS:
	;  format (I,OPT) - Format to get the list in. If not given, we'll prompt the user for it.
	; RETURNS:        The list, in the chosen format.
	;---------
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
	
	;---------
	; DESCRIPTION:    Send the list to the current window, in a certain format.
	; PARAMETERS:
	;  format (I,OPT) - Format to send the list in. If not given, we'll prompt the user for it.
	;---------
	sendList(format := "") {
		if(!format)
			format := this.promptForFormat("Enter OUTPUT format for list")
		if(!format)
			return
		
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
	
	;---------
	; DESCRIPTION:    Read in the provided list object and store it in an internal (array) format.
	; PARAMETERS:
	;  listObject (I,REQ) - The list to determine the format of.
	;  format     (I,OPT) - Format that the list is in (from FormatList.Format_* constants). If not
	;                       given, we will try to determine it ourselves and prompt the user if we
	;                       can't figure it out.
	; RETURNS:        true if we were successful, false if we couldn't determine the format (and
	;                 the user didn't help).
	; SIDE EFFECTS:   Populates .listAry with the array representation of the list
	;---------
	parseListObject(listObject, format) {
		; If the incoming format wasn't given, try to figure it out.
		if(!format)
			format := this.determineListFormat(listObject)
		
		; Quit silently if the format was blanked out (user was prompted but didn't pick anything)
		if(!format)
			return false
		
		; Turn the list into an array.
		this.listAry := this.convertListToArray(listObject, format)
		return true
	}
	
	;---------
	; DESCRIPTION:    Figure out what format the provided list is in, including prompting the user
	;                 if we can't figure it out on our own.
	; PARAMETERS:
	;  listObject (I,REQ) - The list to determine the format of.
	; RETURNS:        The determined format, from FormatList.Format_*
	;---------
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
	
	;---------
	; DESCRIPTION:    Try to determine the format of a list (assumed to be a string) based on what
	;                 delimiters it contains.
	; PARAMETERS:
	;  listString (I,REQ) - The string list to check.
	; RETURNS:        The determined format, from FormatList.Format_*
	;---------
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
	
	;---------
	; DESCRIPTION:    Prompt the user for an input or output format for the list.
	; PARAMETERS:
	;  title (I,REQ) - The title to prompt the user with.
	; RETURNS:        The chosen format, should match a value from FormatList.Format_*
	;---------
	promptForFormat(title) {
		s := new Selector("listFormats.tls")
		return s.selectGui("FORMAT", title)
	}
	
	;---------
	; DESCRIPTION:    Turn the list into our internal representation (an array) based on its format.
	; PARAMETERS:
	;  listObject (I,REQ) - The list to convert.
	;  format     (I,REQ) - The format the list is in.
	; RETURNS:        The array representation of the list
	;---------
	convertListToArray(listObject, format) {
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
	
	;---------
	; DESCRIPTION:    Return the list in the given format.
	; PARAMETERS:
	;  format (I,REQ) - The format (from FormatList.Format_*) to return the list in.
	; RETURNS:        The formatted list.
	;---------
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
	
	;---------
	; DESCRIPTION:    Send the list to the current window in a particular format.
	; PARAMETERS:
	;  format (I,REQ) - The format to use (FormatList.Format_*).
	; RETURNS:        true if successful, false if something went wrong (like an unsupported format).
	;---------
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