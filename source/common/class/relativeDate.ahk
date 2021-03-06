#Include ..\base\actionObjectBase.ahk

/* Calculates and sends a date relative to the class's instantiation. --=
	
	Relative date string format
		The relative date string is in this format:
			<Unit><Operator><ShiftAmount>
				Unit        - The unit to shift the date by (see "Units" section below)
				Operator    - Plus (+) or minus (-) for the direction to shift
				ShiftAmount - How much to shift the date by, in the provided unit
	
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
	
*/ ; =--

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
	;  shiftAmount (I,REQ) - The amount to shift
	;  unit        (I,REQ) - The unit to shift in
	;---------
	doShift(shiftAmount, unit) {
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
	;---------
	shiftDay(numToShift) {
		this._instant := EnvAdd(this._instant, numToShift, "Days") ; Use EnvAdd to add days (can't use += format because it doesn't support this.*-style variable names).
		this.updatePartsFromInstant()
	}
	shiftWeek(numToShift) {
		this.shiftDay(numToShift * 7) ; There's always 7 days in a week, so just add it that way
	}
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
	shiftYear(numToShift) {
		this.year += numToShift
		this.updateInstantFromParts()
	}
	; #END#
}
