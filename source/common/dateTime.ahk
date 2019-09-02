; Date and time utility functions.
sendDateTime(format) {
	Send, % FormatTime(, format)
}

; Ask the user for a (shortcut) input to translate.
queryDate(format := "M/d/yy") {
	userIn := InputBox("Expand date", , , 200, 100)
	
	if(userIn != "")
		date := parseDateTime(userIn, format, "d")
	
	return date
}
queryTime(format := "h:mm tt") {
	userIn := InputBox("Expand time", , , 200, 100)
	
	if(userIn != "")
		time := parseDateTime(userIn, format, "t")
	
	return time
}

; Translate a date/time from the form "w+1" to the given format.
parseDateTime(input, format := "", dateOrTime := "") { ; dateOrTime = "d" for date, "t" for time
	firstChar := input.sub(1, 1)
	operator := input.sub(2, 1)
	difference := input.sub(3)
	
	; Two-char thing - "mi" for minute or "mo" for month. Account for it to get the real operator and offset.
	if(operator.isAlpha()) {
		secondChar := input.sub(2, 1)
		operator := input.sub(3, 1)
		difference := input.sub(4)
	}
	
	; Allow "mi" for minute and "mo" for month, to make it easier to tell the difference.
	if(firstChar = "m") {
		if(secondChar = "o")
			timeOrDate := "d"
		else if(secondChar = "i")
			timeOrDate := "t"
	}
	
	; Fix the odd exceptions that aren't their actual internal representations - now and today
	if(firstChar = "t")
		firstChar := "d"
	else if(firstChar = "n") {
		firstChar := "m"
		dateOrTime := "t"
	}
	
	; Determine for sure whether we're talking date or time.
	if(dateOrTime = "") {
		If (firstChar = "y")
			or (firstChar = "m") ; "m" is assumed to be month over minute given no other context.
			or (firstChar = "d")
		{
			dateOrTime := "d"
		}
		Else If (firstChar = "h")
			; or (firstChar = "m")
			or (firstChar = "s")
		{
			dateOrTime := "t"
		}
	}
	
	; Default formats
	if(format = "") {
		if(dateOrTime = "d")
			format = "M/d/yy"
		else if(dateOrTime = "t")
			format = "h:mm tt"
	}
	
	; DEBUG.popup("parseDateTime", "pre-calculations", "Input", input, "First char", firstChar, "Operator", operator, "Difference", difference, "Date or time", dateOrTime)
	
	if(dateOrTime = "d") {
		outDateTime := doDateMath(A_Now, operator, difference, firstChar)
	} else if(dateOrTime = "t") {
		if(operator = "-")
			difference := -difference
		
		outDateTime := A_Now
		outDateTime += difference, %firstChar%
	} else {
		DEBUG.popup("Error in parseDateTime", "Couldn't choose between date and time", "Input", date)
	}
	
	return FormatTime(outDateTime, format)
}

; Do addition/subtraction on dates where the traditional += fails.
doDateMath(start, operator := "+", diff := 0, unit := "d") {
	outDate := start
	dateObj := splitDateTime(start)
	
	if(operator = "-")
		diff := -diff
	
	; Treat weeks as 7 days - this is universal.
	if(unit = "w") {
		diff *= 7
		unit := "d"
	}
	
	if(unit = "d") {
		outDate += diff, days ; Days we can do the easy way, with EnvAdd/+=.
		dateObj := splitDateTime(outDate)
	} else if(unit = "m") { ; Months vary in size, so just modify their part of the timestamp.
		dateObj["month"] += diff
		dateObj["year"] += dateObj["month"] // 12
		dateObj["month"] := mod(dateObj["month"], 12)
	} else if(unit = "y") {
		dateObj["year"] += diff
	}
	
	; Pad out any lengths that went down to the wrong number of digits.
	For unit,amount in dateObj
		dateObj[unit] := amount.prePadToLength(2, "0") ; Technically year could be 4, but we're never going to deal with dates prior to the year 1000.
	
	outDate := dateObj["year"] dateObj["month"] dateObj["day"] dateObj["hour"] dateObj["minute"] dateObj["second"]
	; DEBUG.popup("doDateMath","return", "Start",start, "Y",dateObj["year"], "M",dateObj["month"], "D",dateObj["day"], "H",dateObj["hour"], "M",dateObj["minute"], "S",dateObj["second"], "Diff",diff, "Unit",unit, "Output",outDate)
	
	return outDate
}

; Break apart the given YYYYMMDDHH24MISS timestamp into its respective parts.
splitDateTime(timestamp) {
	dateTimeAry := Object()
	
	dateTimeAry["year"]   := timestamp.sub(1,  4)
	dateTimeAry["month"]  := timestamp.sub(5,  2)
	dateTimeAry["day"]    := timestamp.sub(7,  2)
	dateTimeAry["hour"]   := timestamp.sub(9,  2)
	dateTimeAry["minute"] := timestamp.sub(11, 2)
	dateTimeAry["second"] := timestamp.sub(13, 2)
	
	; DEBUG.popup("timestamp",timestamp, "dateTimeAry",dateTimeAry)
	return dateTimeAry
}

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
