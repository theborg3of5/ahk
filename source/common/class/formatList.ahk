/* Class to represent a list of strings, that can be parsed and output in a variety of different formats.
	
	***
	
	GDB TODO
		Turn this into a non-static class
			Properties for getting list in different formats?
			Public functions for:
				Sending list in different formats
				Sending list in format chosen by user (prompt)
		Try again to centralize delimiters, at least?
			Maybe separate input vs output delimiters?
			Maybe lack of a delimiter is a special case where we break into a switch statement?
		More output methods
			Filling in a OneNote table column (down arrow between?)
			Filling a list of IDs into EpicStudio (Before/after inputs on Selector popup for code surrounding lines, newlines only applied after that)
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
		; Initialize the format delimiter array if this is the first time we're using the class.
		if(!FormatList.formatsAry)
			FormatList.formatsAry := FormatList.buildFormatArray()
		
		; Convert input list into an array for processing.
		if(!this.parseListObject(listObject, inFormat))
			return ""
		
		; DEBUG.popup("listObject",listObject, "this.formatsAry",this.formatsAry, "this.listAry",this.listAry)
	}
	
	; GDB TODO add error toasts/early quits for formats that are allowed to be sent vs. returned
	getList(format := "") { ; Leave format blank to prompt user
		if(!format)
			format := this.determineOutputFormat()
		
		return this.getListInFormat(format)
	}
	
	; GDB TODO should we just do individual functions per format instead?
	sendList(format := "") { ; Leave format blank to prompt user
		if(!format)
			format := this.determineOutputFormat()
		
		this.sendListInFormat(format)
	}
	
	; Determine the format to convert the list into if not given.
	determineOutputFormat() {
		s := new Selector("listFormats.tls")
		return s.selectGui("FORMAT", "Enter OUTPUT format for list")
	}
	
	
; ==============================
; == Private ===================
; ==============================
	; static FormatDelimsAry := []
	
	static formatsAry := ""
	
	listAry := ""
	
	; Special, internal-only list formats
	static Format_Ambiguous     := "AMBIGUOUS"      ; Can't tell what the format is, so we'll have to ask the user.
	static Format_UnknownSingle := "UNKNOWN_SINGLE" ; We don't know what the format is, but it looks like a single item only.
	
	buildFormatArray() { ; GDB TODO get rid of this function if we don't do something with the delimiters
		; FormatList.FormatDelimsAry := [] ; GDB TODO consider getting rid of this one - why not just have specific cases?
		; FormatList.FormatDelimsAry[FormatList.Format_Commas]   := ","
		; FormatList.FormatDelimsAry[FormatList.Format_NewLines] := "`r`n"
		
	}
	
	parseListObject(listObject, format) {
		; If the incoming format wasn't given, try to figure it out.
		if(!format)
			format := this.determineListFormat(listObject)
		
		; Fail out if we couldn't figure out the format.
		if(!format) {
			; GDB TODO error toast, no format given or determineable.
			return false
		}
		
		; Turn the list into an array.
		this.listAry := this.transformToAry(listObject, format)
		
		; DEBUG.popup("listObject",listObject, "format",format, "this.listAry",this.listAry)
		return true
	}
	
	determineListFormat(listObject) {
		if(isObject(listObject)) ; An object is assumed to be a simple array (same format as we use to store the list internally).
			listFormat := FormatList.Format_Array
		else ; Otherwise, treat it as a string and decide based on the delimiter.
			listFormat := FormatList.determineStringListFormat(listObject)
		
		; If we can't tell, ask the user.
		if(listFormat = FormatList.Format_Ambiguous) {
			s := new Selector("listFormats.tls")
			listFormat := s.selectGui("FORMAT", "Enter INPUT format for list")
		}
		
		return listFormat
	}
	
	determineStringListFormat(listString) { ; GDB TODO should this be combined into determineListFormat? Maybe move the selector bit up into parseListObject() too?
		distinctDelimsCount := 0
		
		if(stringContains(listString, ",")) { ; GDB TODO reconsider looping approach?
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
		
		if(distinctDelimsCount = 0) ; If we didn't find any delimiters, it could be any of them, but just a single value - so we know what to do with it.
			return FormatList.Format_UnknownSingle
		if(distinctDelimsCount = 1)
			return foundFormat
		if(distinctDelimsCount > 1) ; If we found more than one delimiter, we can't tell which is the right one to split the list up by.
			return FormatList.Format_Ambiguous
		
		return ""
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
			return
		
		; Stuff that doesn't involve extra keys - just Send what comes out of .getListInFormat().
		if(format = FormatList.Format_Commas || format = FormatList.Format_NewLines) {
			SendRaw, % this.getListInFormat(format)
			return
		}
		
		; OneNote columns - send a down arrow keystroke between items.
		if(format = FormatList.Format_OneNoteColumn) {
			For i,item in this.listAry {
				SendRaw, % item
				if(i < this.listAry.length()) {
					SendPlay, {Down} ; SendPlay is required because OneNote doesn't reliably take {Down} keystrokes otherwise.
					Sleep, 100 ; Required because otherwise the down keystrokes can get out of sync with the items.
				}
			}
			return
		}
	}
}