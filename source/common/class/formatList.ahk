/* Class to represent a list of strings, that can be parsed and output in a variety of different formats.
	
	***
	
	GDB TODO
		Turn this into a non-static class
			Properties for getting list in different formats
			Property for calculated (and possibly prompted?) format of list?
			Public functions for:
				Sending list in different formats
				Sending list in format chosen by user (prompt)
		Fix usage in input.ahk
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
	static Format_Array    := "ARRAY"
	static Format_Commas   := "COMMA"
	static Format_NewLines := "NEWLINE"
	
	convertList(listObject, toFormat := "", fromFormat := "") {
		; Initialize the format delimiter array if this is the first time we're using the class.
		if(!FormatList.formatDelimsAry)
			FormatList.formatDelimsAry := FormatList.getFormatDelimsAry()
		
		; Convert input list into an array for processing.
		listAry := FormatList.parseListObject(listObject, fromFormat)
		
		; Determine the format to convert the list into if not given.
		if(!toFormat) {
			s := new Selector("listFormats.tls")
			toFormat := s.selectGui("FORMAT", "Enter OUTPUT format for list")
		}
		
		outputObject := FormatList.convertListAryToFormat(listAry, toFormat)
		; DEBUG.popup("Input format",fromFormat, "Input",listObject, "Parsed",listAry, "Output format",toFormat, "Output",outputObject)
		
		return outputObject
	}
	
	
; ==============================
; == Private ===================
; ==============================
	static formatDelimsAry := []
	
	; Special, internal-only list formats
	static Format_Ambiguous     := "AMBIGUOUS"      ; Can't tell what the format is, so we'll have to ask the user.
	static Format_UnknownSingle := "UNKNOWN_SINGLE" ; We don't know what the format is, but it looks like a single item only.
	
	getFormatDelimsAry() {
		ary := []
		
		ary[FormatList.Format_Commas]   := ","
		ary[FormatList.Format_NewLines] := "`r`n"
		
		return ary
	}
	
	parseListObject(listObject, listFormat) {
		if(!listFormat)
			listFormat := FormatList.determineListFormat(listObject)
		if(!listFormat)
			return ""
		
		if(listFormat = FormatList.Format_Array)
			listAry := listObject
		else if(listFormat = FormatList.Format_UnknownSingle) ; We don't know what delimiter the list was input with, but it seems to just be a single element, so it doesn't matter.
			listAry := [listObject]
		else if(listFormat = FormatList.Format_Commas)
			listAry := StrSplit(listObject, ",", " `t") ; Drop spaces and tabs from beginning/end of list elements
		else if(listFormat = FormatList.Format_NewLines)
			listAry := StrSplit(listObject, "`r`n", " `t") ; Drop spaces and tabs from beginning/end of list elements
		
		listAry := arrayDropEmptyValues(listAry) ; Drop empty values from the array.
		return listAry
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
	
	determineStringListFormat(listString) {
		numDelimitersFound := 0
		For format,delim in FormatList.formatDelimsAry {
			if(stringContains(listString, delim)) {
				; DEBUG.popup("FormatList.determineStringListFormat","Delimiter loop", "listString",listString, "Matched delimiter",delim)
				listFormat := format
				numDelimitersFound += 1
			}
		}
		
		if(numDelimitersFound > 1) ; If we found more than one delimiter, we can't tell which is the right one to split the list up by.
			return FormatList.Format_Ambiguous
		if(numDelimitersFound = 0) ; If we didn't find any delimiters, it could be any of them, but just a single value - so we know what to do with it.
			return FormatList.Format_UnknownSingle
		
		return listFormat
	}
	
	convertListAryToFormat(listAry, listFormat) {
		if(!listAry || !listFormat)
			return ""
		
		if(listFormat = FormatList.Format_Array)
			return listAry
		if(listFormat = FormatList.Format_Commas)
			return arrayJoin(listAry, ",")
		if(listFormat = FormatList.Format_NewLines)
			return arrayJoin(listAry, "`n")
	}
}