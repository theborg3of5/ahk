/* Base class for relative date/time classes. =--
	
	Should not be used directly, only extended.
	
*/ ; --=

class RelativeDateTimeBase {

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
	; NOTES:          Should be overridden by child class.
	;---------
	__New(relativeDateTime := "") {
		new ErrorToast("RelativeDateTimeBase instance created", "RelativeDateTimeBase is a base class only, use a date/time-specific child class instead.").showMedium()
		return ""
	}
	
	;---------
	; DESCRIPTION:    Send the relative date/time in a particular format.
	; PARAMETERS:
	;  format (I,REQ) - The format to send the date/time in, a la FormatTime().
	;---------
	SendInFormat(format) {
		Send, % FormatTime(this._instant, format)
	}
	
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	_instant := "" ; The actual timestamp that we calculate based on the relative date/time string.
	
	; The current value for different time units.
	_year    := ""
	_month   := ""
	_day     := ""
	_hour    := ""
	_minute  := ""
	_second  := ""
	
	;---------
	; DESCRIPTION:    Load the current date and time into class members.
	;---------
	loadCurrentDateTime() {
		this._instant := A_Now
		
		this._year   := A_YYYY
		this._month  := A_MM
		this._day    := A_DD
		this._hour   := A_Hour
		this._minute := A_Min
		this._second := A_Sec
	}
	
	;---------
	; DESCRIPTION:    Split up the relative date/time string and call into the child class to
	;                 perform the shift.
	; PARAMETERS:
	;  relativeString (I,REQ) - The relative date/time string, in format:
	;                            <unitLetter><operator><shiftAmount>
	;                           Where unitLetter is the letter fo the unit, operator is + or -, and
	;                           shiftAmount is how many to add/subtract.
	;---------
	shiftByRelativeString(relativeString) {
		unit        := relativeString.sub(1, 1)
		operator    := relativeString.sub(2, 1)
		shiftAmount := relativeString.sub(3)
		
		; Make shiftAmount match unit (because we have to use EnvAdd/+= for date/time math)
		if(operator = "-")
			shiftAmount := -shiftAmount
		
		this.doShift(shiftAmount, unit)
	}
	
	;---------
	; DESCRIPTION:    Update the individual member variables for different units based on the instant.
	;---------
	updatePartsFromInstant() {
		this._year   := this._instant.sub(1,  4)
		this._month  := this._instant.sub(5,  2)
		this._day    := this._instant.sub(7,  2)
		this._hour   := this._instant.sub(9,  2)
		this._minute := this._instant.sub(11, 2)
		this._second := this._instant.sub(13, 2)
	}
	
	;---------
	; DESCRIPTION:    Update the instant based on the individual member variables for different units.
	;---------
	updateInstantFromParts() {
		year   :=   this._year.prePadToLength(4, "0")
		month  :=  this._month.prePadToLength(2, "0")
		day    :=    this._day.prePadToLength(2, "0")
		hour   :=   this._hour.prePadToLength(2, "0")
		minute := this._minute.prePadToLength(2, "0")
		second := this._second.prePadToLength(2, "0")
		
		this._instant := year month day hour minute second
	}
	
	;---------
	; DESCRIPTION:    Perform the date or time shift.
	; NOTES:          Just shows an error - should be overridden by the child class.
	;---------
	doShift(shiftAmount, unit) {
		new ErrorToast("RelativeDateTimeBase.doShift called", "The child class should override doShift().").showMedium()
	}
}
