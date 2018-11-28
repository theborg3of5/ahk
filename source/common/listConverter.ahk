/* Class for converting lists of things from one format into another.
	
	***
*/

global LISTFORMAT_Unknown := "UNKNOWN"
global LISTFORMAT_Array := "ARRAY"
global LISTFORMAT_Commas := "COMMA"
global LISTFORMAT_NewLines := "NEWLINE"

class ListConverter {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	__New(listObject := "") {
		this.setList(listObject)
	}
	
	setList(listObject, format := "") {
		if(!listObject)
			return
		
		this.listAry := this.processListObject(listObject, format)
	}
	
	getList(format) {
		if(!format)
			return ""
		
		if(format = LISTFORMAT_Array)
			return this.listAry
		;GDB TODO more
	}
	
	convertList(listObject, toFormat, fromFormat := "") {
		this.setList(listObject, fromFormat)
		return this.getList(toFormat)
	}
	
	; ==============================
	; == Private ===================
	; ==============================
	
	listAry := []
	
	processListObject(listObject, listFormat := "") {
		if(!listFormat)
			listFormat := this.determineListFormat(listObject)
		
		if(listFormat = LISTFORMAT_Array)
			return listObject
		if(listFormat = LISTFORMAT_Unknown)
			return [listObject] ; Just put the single value in an array.
		; GDB TODO get list into array based on starting format
	}
	
	determineListFormat(listObject) {
		; An object is assumed to be a simple array (same format as we use to store the list internally).
		if(isObject(listObject))
			return LISTFORMAT_Array
		
		; Otherwise, treat it as a string and start looking for delimiters
		
		
		
		
		; If we didn't find any delimiters, it could be any of them, but just a single value - so just treat it as a generic string.
		return LISTFORMAT_Unknown
	}
}