; This class represents a single recurring todo item, along with the timeframe filtering info that goes with it.
class OneNoteRecurringTodo {
	; #INTERNAL#
	
	;---------
	; DESCRIPTION:    Create a new recurring todo object.
	; PARAMETERS:
	;  todoAry (I,REQ) - An array with info about the object. Format:
	;                       Required subscripts:
	;                          ["TITLE"] - Title of the todo item. This is the only required subscript.
	;                       Filters: these are optional, and if left blank, that part of the date
	;                       will not be considered when evaluating this todo for matches.
	;                          ["DATE"]             - The numeric date (or "LAST" for the last day
	;                                                 of the month) that the todo should be included on.
	;                          ["DAY_ABBREV"]       - The all-caps abbreviation for the day of the
	;                                                 week that this todo should match.
	;                          ["MONTH_ABBREV"]     - The all-caps abbreviation for the month that
	;                                                 this todo should match.
	;                          ["NUM_DAY_OF_MONTH"] - The number day of the month (i.e. DAY_ABBREV=WED
	;                                                 and NUM_DAY_OF_MONTH=2 for 2nd Wednesday of the month).
	;---------
	__New(todoAry) {
		this.title         := todoAry["TITLE"]
		this.date          := todoAry["DATE"]
		this.dayAbbrev     := todoAry["DAY_ABBREV"]
		this.monthAbbrev   := todoAry["MONTH_ABBREV"]
		this.numDayOfMonth := todoAry["NUM_DAY_OF_MONTH"]
	}
	
	;---------
	; DESCRIPTION:    Check whether this todo matches the provided instant, based on its filters.
	; PARAMETERS:
	;  instant (I,REQ) - Instant to check for a match against this todo's filters.
	; RETURNS:        true if it matches, false otherwise.
	;---------
	matchesInstant(instant) {
		if(instant = "")
			return false
		
		if(!this.instantMatchesDate(instant))
			return false
		if(!this.instantMatchesDayAbbrev(instant))
			return false
		if(!this.instantMatchesMonthAbbrev(instant))
			return false
		if(!this.instantMatchesNumDayOfMonth(instant))
			return false
		
		return true
	}
	
	
	; #PRIVATE#
	
	title         := "" ; Title for the todo item
	date          := "" ; Numeric date or "LAST"
	dayAbbrev     := "" ; All-caps abbreviation for the day of the week
	monthAbbrev   := "" ; All-caps abbreviation for the month
	numDayOfMonth := "" ; For the day of the week, which number that is within the month (i.e. 2 for 2nd Wednesday in the month).
	
	
	;---------
	; DESCRIPTION:    Check whether the provided instant matches the date/day/month/numDayOfMonth
	;                 filters for this todo item.
	; PARAMETERS:
	;  instant (I,REQ) - Instant to check.
	; RETURNS:        true if it matches the respective filter (or that filter isn't set), false
	;                 otherwise.
	;---------
	instantMatchesDate(instant) {
		if(this.date = "")
			return true
		
		instDate := FormatTime(instant, "d") ; Date, no leading 0
		if(this.date = instDate)
			return true
		
		; Special case for last day of the month
		if(this.date = "LAST") {
			monthNum := FormatTime(instant, "M") ; Month number, no leading 0
			year     := FormatTime(instant, "yyyy")
			if(instDate = DateTimeLib.getLastDateOfMonth(monthNum, year))
				return true
		}
		
		return false
	}
	instantMatchesDayAbbrev(instant) {
		if(this.dayAbbrev = "")
			return true
			
		instDayAbbrev := StringUpper(FormatTime(instant, "ddd")) ; Day of week abbreviation, all caps
		if(this.dayAbbrev = instDayAbbrev)
			return true
		
		return false
	}
	instantMatchesMonthAbbrev(instant) {
		if(this.monthAbbrev = "")
			return true
		
		instMonthAbbrev := StringUpper(FormatTime(instant, "MMM")) ; Month abbreviation
		if(this.monthAbbrev = instMonthAbbrev)
			return true
		
		return false
	}
	instantMatchesNumDayOfMonth(instant) {
		if(this.numDayOfMonth = "")
			return true
		
		instDate := FormatTime(instant, "d") ; Date, no leading 0
		instNumDayOfMonth := ((instDate - 1) // 7) + 1 ; -1 to get to 0-base (otherwise day 6 and 7 are in different week numbers), +1 to get back after
		if(this.numDayOfMonth = instNumDayOfMonth)
			return true
		
		return false
	}
	; #END#
}
