; Date and time utility functions.

class DateTimeLib {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Replace tags matching different formats supported by FormatTime.
	; PARAMETERS:
	;  inString (I,REQ) - The string to replace tags in
	;  dateTime (I,OPT) - The date/time to use when replacing tags
	; RETURNS:        The updated string
	;---------
	static replaceTags(inString, instant := "") {
		outString := inString
		
		; All formats supported by FormatTime
		formatsAry := ["d","dd","ddd","dddd","M","MM","MMM","MMMM","y","yy","yyyy","gg","h","hh","H","HH","m","mm","s","ss","t","tt","","Time","ShortDate","LongDate","YearMonth","YDay","YDay0","WDay","YWeek"]
		
		For _,formatToUse in formatsAry {
			dateTimeBit := FormatTime(instant, formatToUse)
			outString := outString.replaceTag(formatToUse, dateTimeBit)
		}
		
		return outString
	}

	;---------
	; DESCRIPTION:    Figure out the last date in the provided month/year.
	; PARAMETERS:
	;  monthNum (I,OPT) - The month number to check
	;  year     (I,OPT) - The year to check
	; RETURNS:        The last date (with leading 0) in the given month.
	;---------
	static getLastDateOfMonth(monthNum := "", year := "") {
		monthNum := monthNum ? monthNum : A_MM
		year     := year     ? year     : A_YYYY

		nextMonthNum := monthNum + 1
		if nextMonthNum = 13
			nextMonthNum := 1

		dateString := year nextMonthNum.prePadToLength(2, "0") "01" ; First day of following month in YYYYMMDD format
		dateString := DateAdd(dateString, -1, "Days")

		return FormatTime(dateString, "dd")
	}
	;endregion ------------------------------ PUBLIC ------------------------------
}
