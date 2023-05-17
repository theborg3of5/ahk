#Include ..\base\actionObjectBase.ahk

/* Calculates and sends a date relative to the class's instantiation. =--
	
	Relative date string format
		The relative date string is in this format:
			<Unit><Operator><ShiftAmount>
				Unit        - The unit to shift the date by (see "Units" section below)
				Operator    - Plus (+) or minus (-) for the direction to shift
				ShiftAmount - How much to shift the date by, in the provided unit
				              Also supports a special "day of week" mode, where ShiftAmount is the letter (umtwrfs) of the day of the week, 
				              to shift to the next/previous (for +/- operator) instance of that day. You can also specify how many additional
				              instances of that day to shift (i.e. t+2m is 2 Mondays after today, aka the Monday after next).
	
	Units
		This class supports a few date units, including:
			y - years
			m - months
			w - weeks
			d - days
			t - days (stands for "today")
	
	Example Usage
;		rd := new RelativeDate("m+5") ; 5 months in the future, at the date this line runs
;		newTime := rd.instant         ; Get the calculated date
;		rd.SendInFormat("M/d/yy")     ; Send the calculated date in a specific format
	
*/ ; --=

class RelativeDate extends RelativeDateTimeBase {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Create a new representation of a date relative to right now.
	; PARAMETERS:
	;  relativeDate (I,REQ) - The relative date string to use to find the new date.
	;---------
	__New(relativeDate) {
		this.loadCurrentDateTime()
		this.shiftByRelativeString(relativeDate)
	}

	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Handle the actual date shift relative to today.
	; PARAMETERS:
	;  shiftAmount (I,REQ) - The amount to shift. Can optionally include a suffix for a specific day of the week: (m for the
	;                        coming Monday, -m for the previous Monday, 2m for the Monday after next, etc.).
	;  unit        (I,REQ) - The unit to shift in
	;---------
	doShift(shiftAmount, unit) {
		; Special day-of-week handling (t+2m => 2 Mondays after today [the Monday after next], etc.)
		dayOfWeek := shiftAmount.lastChar().isAnyOf(["u", "m", "t", "w", "r", "f", "s"]) ; Starting with Sunday (u) because that's how A_WDay counts (Sunday = 1).
		if(dayOfWeek) {
			; Shift to the given day of the week within the current week (Sun to Sat)
			numDays := dayOfWeek - A_WDay ; Examples: Mon => Tues = 1, Tues => Mon = -1, Wed => Wed = 0, Sat => Sun = -6

			; Figure out how many weeks we need to shift (number before the day of the week)
			numWeeks := shiftAmount.sub(1, -1) ; All but last character
			; Handle t+m/t-m cases (implies a 1-week shift)
			if(numWeeks = "-")
				numWeeks := -1
			else if(numWeeks = "")
				numWeeks := 1

			; If we already shifted days in the direction we're going, that counts as shifting a "week" already.
			if(shiftAmount.contains("-") && (dayOfWeek < A_WDay))
				numWeeks += 1
			if(!shiftAmount.contains("-") && (dayOfWeek > A_WDay))
				numWeeks -= 1

			shiftAmount := numDays + (numWeeks * 7)
		}

		Switch unit {
			Case "d","t": this.shiftDay(shiftAmount) ; Relative days can also be written as "t" for today.
			Case "w":     this.shiftWeek(shiftAmount)
			Case "m":     this.shiftMonth(shiftAmount)
			Case "y":     this.shiftYear(shiftAmount)
		}
	}
	
	;---------
	; DESCRIPTION:    Shift the date by the given number of days/weeks/months/years.
	; PARAMETERS:
	;  numToShift (I,REQ) - The number of days/weeks/months/years to shift by.
	;                       Can optionally include a suffix for a specific day of the week: (m for the coming Monday,
	;                       -m for the previous Monday, 2m for the Monday after next, etc.).
	;---------
	shiftDay(numToShift) {
		; No shift, nothing to do (like a simple "t" input).
		if(numToShift = "")
			return
		
		this._instant := EnvAdd(this._instant, numToShift, "Days") ; Use EnvAdd to add days (can't use += format because it doesn't support this.*-style variable names).
		this.updatePartsFromInstant()
	}

	;---------
	; DESCRIPTION:    Shift the date by the given number of weeks.
	; PARAMETERS:
	;  numToShift (I,REQ) - Number of weeks to shift by.
	;---------
	shiftWeek(numToShift) {
		this.shiftDay(numToShift * 7) ; There's always 7 days in a week, so just add it that way
	}

	;---------
	; DESCRIPTION:    Shift the date by the given number of months.
	; PARAMETERS:
	;  numToShift (I,REQ) - Number of months to shift by.
	;---------
	shiftMonth(numToShift) {
		; Update the month
		this.month += numToShift
		
		; If the month gets out of bounds, shift the year accordingly
		if(this.month < 1 || this.month > 12) {
			this.year += this.month // 12
			this.month := mod(this.month, 12)
		}
		this.updateInstantFromParts()
	}

	;---------
	; DESCRIPTION:    Shift the date by the given number of years.
	; PARAMETERS:
	;  numToShift (I,REQ) - Number of years to shift by.
	;---------
	shiftYear(numToShift) {
		this.year += numToShift
		this.updateInstantFromParts()
	}
	; #END#
}
