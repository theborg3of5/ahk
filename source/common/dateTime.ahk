; Date and time utility functions.
getDateTime(format) {
	FormatTime, var, %dateTimeVar%, %format%
	return var
}
sendDateTime(format) {
	Send, % getDateTime(format)
}

; Ask the user for a (shortcut) input to translate.
queryDate(format = "M/d/yy") {
	InputBox, userIn, Expand date, , , 200, 100
	
	if(userIn != "")
		date := parseDateTime(userIn, format, "d")
	
	return date
}
queryTime(format = "h:mm tt") {
	InputBox, userIn, Expand time, , , 200, 100
	
	if(userIn != "")
		time := parseDateTime(userIn, format, "t")
	
	return time
}

; Translate a date/time from the form "w+1" to the given format.
parseDateTime(input, format = "", dateOrTime = "") { ; dateOrTime = "d" for date, "t" for time
	firstChar := SubStr(input, 1, 1)
	operator := SubStr(input, 2, 1)
	difference := SubStr(input, 3)
	
	; Two-char thing - "mi" for minute or "mo" for month. Account for it to get the real operator and offset.
	if(isAlpha(operator)) {
		secondChar := SubStr(input, 2, 1)
		operator := SubStr(input, 3, 1)
		difference := SubStr(input, 4)
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
	
	FormatTime, outStr, %outDateTime%, %format%
	
	; DEBUG.popup("parseDateTime", "pre-calculations", "Input", input, "First char", firstChar, "Operator", operator, "Difference", difference, "Date or time", dateOrTime, "Timestamp now", A_Now, "Output timestamp", outDateTime, "Output string", outStr)
	
	return outStr
}

; Do addition/subtraction on dates where the traditional += fails.
doDateMath(start, op = "+", diff = 0, unit = "d") { ; unit = "d"
	outDate := start
	d := splitDateTime(start)
	
	if(op = "-")
		diff := -diff
	
	; Treat weeks as 7 days - this is universal.
	if(unit = "w") {
		diff *= 7
		unit := "d"
	}
	
	
	if(unit = "d") {
		outDate += diff, days ; Days we can do the easy way, with EnvAdd/+=.
		d := splitDateTime(outDate)
	} else if(unit = "m") { ; Months vary in size, so just modify their part of the timestamp.
		d["month"] += diff
		d["year"] += d["month"] // 12
		d["month"] := mod(d["month"], 12)
	} else if(unit = "y") {
		d["year"] += diff
	}
	
	; Pad out any lengths that went down to the wrong number of digits.
	For i,x in d {
		if(i = "year")
			correctLen := 4
		else
			correctLen := 2
		
		currLen := StrLen(x)
		; DEBUG.popup("Index", i, "Correct length", correctLen, "Current length", currLen)
		while(currLen < correctLen) {
			d[i] := "0" x
			currLen++
		}
	}
	
	outDate := d["year"] d["month"] d["day"] d["hour"] d["minute"] d["second"]
	; DEBUG.popup("doDateMath", "return", "Start", start, "Y", d["year"], "M", d["month"], "D", d["day"], "H", d["hour"], "M", d["minute"], "S", d["second"], "Diff", diff, "Unit", unit, "Output", outDate)
	
	return outDate
}

; Break apart the given YYYYMMDDHH24MISS timestamp into its respective parts.
splitDateTime(timestamp) {
	d := Object()
	
	d["year"] := SubStr(timestamp, 1, 4)
	d["month"] := SubStr(timestamp, 5, 2)
	d["day"] := SubStr(timestamp, 7, 2)
	d["hour"] := SubStr(timestamp, 9, 2)
	d["minute"] := SubStr(timestamp, 11, 2)
	d["second"] := SubStr(timestamp, 13, 2)
	
	; DEBUG.popup("splitDate", "return", "Input", timestamp, "Y", d["year"], "M", d["month"], "D", d["day"], "H", d["hour"], "M", d["minute"], "S", d["second"])
	return d
}

