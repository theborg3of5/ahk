/* Class to represent a list of strings, that can be parsed and output in a variety of different formats. --=
	
	Example usage
;		fl := new FormattedList(clipboard)
;		listAry := fl.getList(FormattedList.Format_Array) ; Get the list as an array
;		fl.sendList() ; Prompt the user for the format to send in
	
*/ ; =--

class FormattedList {
	; #PUBLIC#
	
	; @GROUP@ Formats for reading/writing lists
	static Format_Array         := "ARRAY"          ; Array
	static Format_Space         := "SPACE"          ; Space-delimited
	static Format_Commas        := "COMMA"          ; Comma-delimited (no space)
	static Format_CommasSpaced  := "COMMA_SPACED"   ; Comma-delimited (with spaces)
	static Format_NewLines      := "NEWLINE"        ; Newline-delimited
	static Format_OneNoteColumn := "ONENOTE_COLUMN" ; OneNote columns (double-newline delimited)
	; @GROUP-END@
	
	;---------
	; DESCRIPTION:    Create a new FormattedList object.
	; PARAMETERS:
	;  listObject (I,REQ) - Object representing the list, may be an array or delimited string.
	;  inFormat   (I,OPT) - Format that the list is in (from .Format_* constants). If not
	;                       given, we will try to determine it ourselves and prompt the user if we
	;                       can't figure it out.
	;---------
	__New(listObject, inFormat := "") {
		; Convert input list into an array for processing.
		if(!this.parseListObject(listObject, inFormat))
			return ""
		
		; Debug.popup("listObject",listObject, "this.delimsAry",this.delimsAry, "this.listAry",this.listAry)
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
		
		listInFormat := this.getListInFormat(format)
		if(listInFormat = "")
			new ErrorToast("Could not get list", "Format is not gettable: " format).showMedium()
		
		return listInFormat
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
			new ErrorToast("Could not send list", "Format is not sendable: " format).showMedium()
	}
	
	
	; #PRIVATE#
	
	; Special, internal-only list formats
	static Format_Ambiguous     := "AMBIGUOUS"      ; Can't tell what the format is, so we'll have to ask the user.
	static Format_UnknownSingle := "UNKNOWN_SINGLE" ; We don't know what the format is, but it looks like a single item only.
	
	listAry := "" ; Internal array representation of the list
	
	;---------
	; DESCRIPTION:    Read in the provided list object and store it in an internal (array) format.
	; PARAMETERS:
	;  listObject (I,REQ) - The list to determine the format of.
	;  format     (I,OPT) - Format that the list is in (from .Format_* constants). If not
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
		; Debug.popup("this.listAry",this.listAry)
		return true
	}
	
	;---------
	; DESCRIPTION:    Figure out what format the provided list is in, including prompting the user
	;                 if we can't figure it out on our own.
	; PARAMETERS:
	;  listObject (I,REQ) - The list to determine the format of.
	; RETURNS:        The determined format, from .Format_*
	;---------
	determineListFormat(listObject) {
		; Try to figure it out based on the list object itself.
		if(isObject(listObject)) ; All objects are assumed to be arrays
			format := this.Format_Array
		else ; Everything else is assumed to be a string
			format := this.determineFormatByDelimiters(listObject)
		
		; If we can't tell, ask the user.
		if(format = this.Format_Ambiguous)
			format := this.promptForFormat("Enter INPUT format for list")
		
		return format
	}
	
	;---------
	; DESCRIPTION:    Try to determine the format of a list (assumed to be a string) based on what
	;                 delimiters it contains.
	; PARAMETERS:
	;  listString (I,REQ) - The string list to check.
	; RETURNS:        The determined format, from .Format_*
	;---------
	determineFormatByDelimiters(listString) {
		distinctDelimsCount := 0
		if(listString.contains(",")) {
			foundFormat := this.Format_Commas ; Also covers Format_CommasSpaced, see .convertListToArray().
			distinctDelimsCount++
		}
		if(listString.contains(" ")) {
			foundFormat := this.Format_Space
			distinctDelimsCount++
		}
		if(listString.contains("`r`n")) {
			foundFormat := this.Format_NewLines
			distinctDelimsCount++
		}
		if(listString.contains("`r`n`r`n")) {
			foundFormat := this.Format_OneNoteColumn
			distinctDelimsCount++
		}
		
		if(distinctDelimsCount = 0)
			return this.Format_UnknownSingle ; No delimiters, so we're not sure which format it is, but just a single value - so we know what to do with it.
		if(distinctDelimsCount = 1)
			return foundFormat ; Just one matching delimiter, that's gotta be it.
		if(distinctDelimsCount > 1)
			return this.Format_Ambiguous ; We found multiple possibilities, ask the user to choose.
		
		return ""
	}
	
	;---------
	; DESCRIPTION:    Prompt the user for an input or output format for the list.
	; PARAMETERS:
	;  title (I,REQ) - The title to prompt the user with.
	; RETURNS:        The chosen format, should match a value from .Format_*
	;---------
	promptForFormat(title) {
		return new Selector("listFormats.tls").setTitle(title).selectGui("FORMAT")
	}
	
	;---------
	; DESCRIPTION:    Turn the list into our internal representation (an array) based on its format.
	; PARAMETERS:
	;  listObject (I,REQ) - The list to convert.
	;  format     (I,REQ) - The format the list is in.
	; RETURNS:        The array representation of the list
	;---------
	convertListToArray(listObject, format) {
		Switch format {
			Case this.Format_Array:                           listAry := listObject
			Case this.Format_UnknownSingle:                   listAry := [listObject] ; No idea of delimiter, but just one element so it doesn't matter.
			Case this.Format_Space:                           listAry := listObject.split(" ", " `t")
			Case this.Format_Commas,this.Format_CommasSpaced: listAry := listObject.split(",", " `t") 
			Case this.Format_NewLines:                        listAry := listObject.split("`r`n", " `t")
			Case this.Format_OneNoteColumn:                   listAry := listObject.split("`r`n`r`n", " `t`r`n")
		}
		
		listAry.removeEmpties()
		
		tempAry := []
		For _,item in listAry.clone()
			tempAry.appendArray(DataLib.expandList(item))
		listAry := tempAry
		
		return listAry
	}
	
	;---------
	; DESCRIPTION:    Return the list in the given format.
	; PARAMETERS:
	;  format (I,REQ) - The format (from .Format_*) to return the list in.
	; RETURNS:        The formatted list.
	;---------
	getListInFormat(format) {
		if(!this.listAry || !format)
			return ""
		
		Switch format {
			Case this.Format_Array:        return this.listAry
			Case this.Format_Space:        return this.listAry.join(" ")
			Case this.Format_Commas:       return this.listAry.join(",")
			Case this.Format_CommasSpaced: return this.listAry.join(", ")
			Case this.Format_NewLines:     return this.listAry.join("`n")
			Default:                       return ""
		}
	}
	
	;---------
	; DESCRIPTION:    Send the list to the current window in a particular format.
	; PARAMETERS:
	;  format (I,REQ) - The format to use (.Format_*).
	; RETURNS:        true if successful, false if something went wrong (like an unsupported format).
	;---------
	sendListInFormat(format) {
		if(!this.listAry || !format)
			return true
		
		Switch format {
			; Stuff that doesn't involve extra keys - just Send what comes out of .getListInFormat().
			Case this.Format_Space,this.Format_Commas,this.Format_CommasSpaced,this.Format_NewLines:
				SendRaw, % this.getListInFormat(format)
				return true
				
			; OneNote columns - send a down arrow keystroke between items.
			Case this.Format_OneNoteColumn:
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
	; #END#
}
