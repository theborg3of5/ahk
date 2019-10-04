; Date and time utility functions.

;---------
; DESCRIPTION:    Send the current date/time in the given format.
; PARAMETERS:
;  format (I,REQ) - The date/time format to send, a la FormatTime().
;---------
sendCurrentDate(format := "M/d/yy") {
	sendDate(A_Now, format)
}
sendCurrentTime(format := "h:mm tt") {
	sendTime(A_Now, format)
}

;---------
; DESCRIPTION:    Send a date in a particular format.
; PARAMETERS:
;  dateToSend (I,OPT) - The date to send. If not given, we'll prompt the user for a relative date.
;  format     (I,REQ) - The format to send the date in, a la FormatTime(). Defaults to
;                       <month w/out leading 0>/<day with leading 0>/<2-digit year>.
;---------
sendDate(dateToSend := "", format := "M/d/yy") {
	; If no date is passed, prompt the user for a relative one.
	if(dateToSend = "") {
		userDate := InputBox("Enter relative date to send", , , 300, 100)
		if(userDate = "")
			return
		dateToSend := parseRelativeDate(userDate)
	}
	
	Send, % FormatTime(dateToSend, format)
}
;---------
; DESCRIPTION:    Send a time in a particular format.
; PARAMETERS:
;  timeToSend (I,OPT) - The time to send. If not given, we'll prompt the user for a relative time.
;  format     (I,REQ) - The format to send the date in, a la FormatTime(). Defaults to
;                       <hour w/out leading 0>:<minute with leading 0> <AM/PM>.
;---------
sendTime(timeToSend := "", format := "h:mm tt") {
	; If no time is passed, prompt the user for a relative one.
	if(timeToSend = "") {
		userTime := InputBox("Enter relative time to send", , , 300, 100)
		if(userTime = "")
			return
		timeToSend := parseRelativeTime(userTime)
	}
	
	Send, % FormatTime(timeToSend, format)
}

parseRelativeDate(dateToParse) {
	unit        := dateToParse.sub(1, 1)
	operator    := dateToParse.sub(2, 1)
	shiftAmount := dateToParse.sub(3)
	
	; Relative days can actually be written as "t" for today - switch it out if that's the case here.
	if(unit = "t")
		unit := "d"
	
	; Make shiftAmount match unit (because we have to use EnvAdd/+= for date/time math)
	if(operator = "-")
		shiftAmount := -shiftAmount
	
	return doDateMath(A_Now, shiftAmount, unit)
}

parseRelativeTime(timeToParse) {
	unit        := timeToParse.sub(1, 1)
	operator    := timeToParse.sub(2, 1)
	shiftAmount := timeToParse.sub(3)
	
	; Relative minutes can actually be written as a "n" for now - switch it out if that's the case here.
	if(unit = "n")
		unit := "m"
	
	; Make shiftAmount match unit (because we have to use EnvAdd/+= for date/time math)
	if(operator = "-")
		shiftAmount := -shiftAmount
	
	outDateTime := A_Now
	outDateTime += shiftAmount, %unit%
	return outDateTime
}

; Do addition/subtraction on dates where the traditional += fails.
doDateMath(start, shiftAmount, unit) {
	newDate := start
	
	; Days and weeks are simple - just shift by the relevant number of days, with the += operator (EnvAdd).
	if(unit = "d" || unit = "w") {
		if(unit = "w")
			shiftAmount *= 7 ; Weeks are 7 days
		
		newDate += shiftAmount, days
		return newDate
	}
	
	; For months/years, modify the relevant bits of the timestamp directly instead (because EnvAdd
	; doesn't support anything bigger than days, but number of days per month/year varies).
	dateObj := DateHelper.splitDateTime(newDate)
	if(unit = "m")
		DateHelper.addMonths(dateObj, shiftAmount)
	else if(unit = "y")
		dateObj["year"] += shiftAmount
	
	return DateHelper.joinDateTime(dateObj)
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

class DateHelper {
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================

	; Break apart the given YYYYMMDDHH24MISS timestamp into its respective parts.
	splitDateTime(timestamp) {
		dateTime := Object()
		
		dateTime["year"]   := timestamp.sub(1,  4)
		dateTime["month"]  := timestamp.sub(5,  2)
		dateTime["day"]    := timestamp.sub(7,  2)
		dateTime["hour"]   := timestamp.sub(9,  2)
		dateTime["minute"] := timestamp.sub(11, 2)
		dateTime["second"] := timestamp.sub(13, 2)
		
		; DEBUG.popup("timestamp",timestamp, "dateTime",dateTime)
		return dateTime
	}
	joinDateTime(dateTime) {
		return dateTime["year"] dateTime["month"] dateTime["day"] dateTime["hour"] dateTime["minute"] dateTime["second"]
	}
	
	addMonths(ByRef dateObj, monthsToAdd) {
		currMonth := dateObj["month"]
		currYear := dateObj["year"]
		
		; Update the month
		currMonth += monthsToAdd
		
		; If month get out of bounds, shift year accordingly
		if(currMonth < 1 || currMonth > 12) {
			currYear += currMonth // 12
			currMonth := mod(currMonth, 12)
		}
		
		; Make sure month stays 2 digits long.
		currMonth := currMonth.prePadToLength(2, "0")
		
		dateObj["month"] := currMonth
		dateObj["year"] := currYear
	}
	
}
