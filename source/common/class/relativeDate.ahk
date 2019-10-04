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

class RelativeDate {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    The calculated instant, based on the relative date string passed to the constructor.
	;---------
	Instant {
		get {
			return this._instant
		}
	}
	
	;---------
	; DESCRIPTION:    Create a new representation of a date relative to right now.
	; PARAMETERS:
	;  relativeDate (I,OPT) - The relative date string to use to find the new date. If not provided,
	;                         we'll prompt the user for it.
	;---------
	__New(relativeDate := "") {
		this.loadCurrentDate()
		
		; If no date is passed, prompt the user for a relative one.
		if(relativeDate = "")
			relativeDate := InputBox("Enter relative date string", , , 300, 100)
		if(relativeDate = "")
			return ""
		
		this.shiftByRelativeDate(relativeDate)
	}
	
	;---------
	; DESCRIPTION:    Send the relative date in a particular format.
	; PARAMETERS:
	;  format (I,REQ) - The format to send the date in, a la FormatTime().
	;---------
	SendInFormat(format) {
		Send, % FormatTime(this._instant, format)
	}

	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	_instant := "" ; The actual timestamp that we calculate based on the relative date string.
	_year := ""
	_month := ""
	_day := ""
	
	
	loadCurrentDate() {
		this._year    := A_YYYY
		this._month   := A_MM
		this._day     := A_DD
		this.updateInstantFromParts()
	}
	
	shiftByRelativeDate(relativeDate) {
		unit        := relativeDate.sub(1, 1)
		operator    := relativeDate.sub(2, 1)
		shiftAmount := relativeDate.sub(3)
		
		; Make shiftAmount match unit (because we have to use EnvAdd/+= for date/time math)
		if(operator = "-")
			shiftAmount := -shiftAmount
		
		DEBUG.popup("unit",unit, "shiftAmount",shiftAmount)
		
		; Do the shift based on the unit.
		if(unit = "d" || unit = "t") ; Relative days can also be written as "t" for today.
			this.shiftDay(shiftAmount)
		if(unit = "w")
			this.shiftWeek(shiftAmount)
		if(unit = "m")
			this.shiftMonth(shiftAmount)
		if(unit = "y")
			this.shiftYear(shiftAmount)
	}
	
	shiftDay(numDays) {
		this._instant += numDays, Days ; EnvAdd (+=) takes care of updating months/years if needed
		this.updatePartsFromInstant()
	}
	shiftWeek(numWeeks) {
		this.shiftDays(numWeeks * 7)
	}
	shiftMonth(numMonths) {
		; Update the month
		this._month += numMonths
		
		; If the month gets out of bounds, shift the year accordingly
		if(this._month < 1 || this._month > 12) {
			this._year += this._month // 12
			this._month := mod(this._month, 12)
		}
		this.updateInstantFromParts()
	}
	shiftYear(numYears) {
		this._year += numYears
		this.updateInstantFromParts()
	}
	
	updatePartsFromInstant() {
		this._year  := this._instant.sub(1, 4)
		this._month := this._instant.sub(5, 2)
		this._day   := this._instant.sub(7, 2)
	}
	
	updateInstantFromParts() {
		year  := this._year.prePadToLength(4, "0")
		month := this._month.prePadToLength(2, "0")
		day   := this._day.prePadToLength(2, "0")
		
		this._instant := year month day
	}
}
