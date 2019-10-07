#Include relativeDateTimeBase.ahk

/* Calculates and sends a date relative to the class's instantiation.
	
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
		rd := new RelativeDate("m+5") ; 5 months in the future, at the date this line runs
		newTime := rd.Instant         ; Get the calculated date
		rd.SendInFormat("M/d/yy")     ; Send the calculated date in a specific format
*/

class RelativeDate extends RelativeDateTimeBase {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Create a new representation of a date relative to right now.
	; PARAMETERS:
	;  relativeDate (I,OPT) - The relative date string to use to find the new date. If not provided,
	;                         we'll prompt the user for it.
	;---------
	__New(relativeDate := "") {
		this.loadCurrentDateTime()
		
		; If no relative date string is passed, prompt the user for a relative one.
		if(relativeDate = "")
			relativeDate := InputBox("Enter relative date string", , , 300, 100)
		if(relativeDate = "")
			return ""
		
		this.shiftByRelativeString(relativeDate)
	}

	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Handle the actual date shift relative to today.
	; PARAMETERS:
	;  shiftAmount (I,REQ) - The amount to shift
	;  unit        (I,REQ) - The unit to shift in
	;---------
	doShift(shiftAmount, unit) {
		if(unit = "d" || unit = "t") ; Relative days can also be written as "t" for today.
			this.shiftDay(shiftAmount)
		if(unit = "w")
			this.shiftWeek(shiftAmount)
		if(unit = "m")
			this.shiftMonth(shiftAmount)
		if(unit = "y")
			this.shiftYear(shiftAmount)
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
		this._month += numToShift
		
		; If the month gets out of bounds, shift the year accordingly
		if(this._month < 1 || this._month > 12) {
			this._year += this._month // 12
			this._month := mod(this._month, 12)
		}
		this.updateInstantFromParts()
	}
	shiftYear(numToShift) {
		this._year += numToShift
		this.updateInstantFromParts()
	}
}
