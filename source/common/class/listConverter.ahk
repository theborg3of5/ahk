/* Class for converting lists of things from one format into another.
	
	***
*/

class ListConverter {
	
	; ==============================
	; == Public ====================
	; ==============================

	; Formats for reading/writing lists.
	static Format_Array    := "ARRAY"
	static Format_Commas   := "COMMA"
	static Format_NewLines := "NEWLINE"
	
	convertList(listObject, toFormat := "", fromFormat := "") {
		; Initialize the format delimiter array if this is the first time we're using the class.
		if(!ListConverter.formatDelimsAry)
			ListConverter.formatDelimsAry := ListConverter.getFormatDelimsAry()
		
		; Determine the format to convert the list into if not given.
		if(!toFormat) {
			s := new Selector("listFormats.tls")
			toFormat := s.selectGui("FORMAT", "Enter OUTPUT format for list")
		}
		
		; Determine the format of the input list.
		if(!fromFormat)
			fromFormat := ListConverter.determineListFormat(listObject)
		
		listAry := ListConverter.parseListObject(listObject, fromFormat)
		outputObject := ListConverter.convertListAryToFormat(listAry, toFormat)
		; DEBUG.popup("Input format",fromFormat, "Input",listObject, "Parsed",listAry, "Output format",toFormat, "Output",outputObject)
		
		return outputObject
	}
	
	; ==============================
	; == Private ===================
	; ==============================
	
	formatDelimsAry := []
	
	; Special, internal-only list formats
	static Format_Ambiguous     := "AMBIGUOUS"      ; Can't tell what the format is, so we'll have to ask the user.
	static Format_UnknownSingle := "UNKNOWN_SINGLE" ; We don't know what the format is, but it looks like a single item only.
	
	getFormatDelimsAry() {
		ary := []
		
		ary[ListConverter.Format_Commas]   := ","
		ary[ListConverter.Format_NewLines] := "`r`n"
		
		return ary
	}
	
	determineListFormat(listObject) {
		if(isObject(listObject)) ; An object is assumed to be a simple array (same format as we use to store the list internally).
			listFormat := ListConverter.Format_Array
		else ; Otherwise, treat it as a string and decide based on the delimiter.
			listFormat := ListConverter.determineStringListFormat(listObject)
		
		; If we can't tell, ask the user.
		if(listFormat = ListConverter.Format_Ambiguous) {
			s := new Selector("listFormats.tls")
			listFormat := s.selectGui("FORMAT", "Enter INPUT format for list")
		}
		
		return listFormat
	}
	
	determineStringListFormat(listString) {
		numDelimitersFound := 0
		For format,delim in ListConverter.formatDelimsAry {
			if(stringContains(listString, delim)) {
				; DEBUG.popup("ListConverter.determineStringListFormat","Delimiter loop", "listString",listString, "Matched delimiter",delim)
				listFormat := format
				numDelimitersFound += 1
			}
		}
		
		if(numDelimitersFound > 1) ; If we found more than one delimiter, we can't tell which is the right one to split the list up by.
			return ListConverter.Format_Ambiguous
		if(numDelimitersFound = 0) ; If we didn't find any delimiters, it could be any of them, but just a single value - so we know what to do with it.
			return ListConverter.Format_UnknownSingle
		
		return listFormat
	}
	
	parseListObject(listObject, listFormat) {
		if(!listFormat)
			return ""
		
		if(listFormat = ListConverter.Format_Array)
			listAry := listObject
		else if(listFormat = ListConverter.Format_UnknownSingle) ; We don't know what delimiter the list was input with, but it seems to just be a single element, so it doesn't matter.
			listAry := [listObject]
		else if(listFormat = ListConverter.Format_Commas)
			listAry := StrSplit(listObject, ",", " `t") ; Drop spaces and tabs from beginning/end of list elements
		else if(listFormat = ListConverter.Format_NewLines)
			listAry := StrSplit(listObject, "`r`n", " `t") ; Drop spaces and tabs from beginning/end of list elements
		
		listAry := arrayDropEmptyValues(listAry) ; Drop empty values from the array.
		return listAry
	}
	
	convertListAryToFormat(listAry, listFormat) {
		if(!listAry || !listFormat)
			return ""
		
		if(listFormat = ListConverter.Format_Array)
			return listAry
		if(listFormat = ListConverter.Format_Commas)
			return arrayJoin(listAry, ",")
		if(listFormat = ListConverter.Format_NewLines)
			return arrayJoin(listAry, "`n")
	}
}