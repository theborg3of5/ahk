; Date and time utility functions.

replaceDateTimeTags(inString, dateTime := "") { ; dateTime defaults to A_Now (based on FormatTime's behavior)
	outString := inString
	
	; All formats supported by FormatTime
	formatsAry := ["d","dd","ddd","dddd","M","MM","MMM","MMMM","y","yy","yyyy","gg","h","hh","H","HH","m","mm","s","ss","t","tt","","Time","ShortDate","LongDate","YearMonth","YDay","YDay0","WDay","YWeek"]
	
	For _,format in formatsAry {
		dateTimeBit := FormatTime(dateTime, format)
		outString := outString.replaceTag(format, dateTimeBit)
	}
	
	return outString
}

getLastDateOfMonth(monthNum = "", year = "") {
	; Default in today's month/year if either is not given
	if(monthNum = "")
		monthNum := A_MM ; Current month number (with leading 0, though that doesn't matter)
	if(year = "")
		year := A_YYYY ; Current year

	; Get number of the next month
	if(monthNum = 12)
		nextMonthNum := 1
	else
		nextMonthNum := monthNum + 1
	
	dateString := year nextMonthNum.prePadToLength(2, "0") ; First day of following month in YYYYMM format
	dateString += -1, Days ; Go back a day to get to the last day of the given month
	
	return FormatTime(dateString, "dd") ; Date with leading 0 (matches A_DD)
}
